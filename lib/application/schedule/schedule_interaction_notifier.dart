import 'dart:async';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lakiite/domain/entity/schedule_reaction.dart';
import 'package:lakiite/domain/entity/schedule_comment.dart';
import 'package:lakiite/domain/interfaces/i_schedule_interaction_repository.dart';
import 'package:lakiite/application/schedule/schedule_interaction_state.dart';
import 'package:lakiite/infrastructure/schedule_interaction_repository.dart';
import 'package:lakiite/utils/logger.dart';
import 'package:lakiite/application/notification/notification_notifier.dart';
import 'package:lakiite/presentation/presentation_provider.dart';
import '../../infrastructure/firebase/push_notification_sender.dart';

final scheduleInteractionRepositoryProvider =
    Provider<IScheduleInteractionRepository>(
  (ref) => ScheduleInteractionRepository(),
);

final scheduleInteractionNotifierProvider = StateNotifierProvider.family<
    ScheduleInteractionNotifier, ScheduleInteractionState, String>(
  (ref, scheduleId) => ScheduleInteractionNotifier(
    ref.watch(scheduleInteractionRepositoryProvider),
    scheduleId,
    ref,
  ),
);

class ScheduleInteractionNotifier
    extends StateNotifier<ScheduleInteractionState> {
  final IScheduleInteractionRepository _repository;
  final String _scheduleId;
  final Ref _ref;
  StreamSubscription<List<ScheduleReaction>>? _reactionsSubscription;
  StreamSubscription<List<ScheduleComment>>? _commentsSubscription;
  late PushNotificationSender _pushNotificationSender;

  ScheduleInteractionNotifier(
    this._repository,
    this._scheduleId,
    this._ref,
  ) : super(const ScheduleInteractionState()) {
    _pushNotificationSender = PushNotificationSender();
    _initializeSubscriptions();
  }

  Future<void> _initializeSubscriptions() async {
    try {
      // 認証状態を確認
      final authState = await _ref.read(authNotifierProvider.future);
      if (authState.user == null) {
        throw Exception('User not authenticated');
      }

      // リアクションの監視を開始
      _reactionsSubscription = _repository.watchReactions(_scheduleId).listen(
            (reactions) => state = state.copyWith(reactions: reactions),
            onError: (error) => state = state.copyWith(error: error.toString()),
          );

      // コメントの監視を開始
      _commentsSubscription = _repository.watchComments(_scheduleId).listen(
            (comments) => state = state.copyWith(comments: comments),
            onError: (error) => state = state.copyWith(error: error.toString()),
          );
    } catch (e) {
      AppLogger.error('Error initializing subscriptions: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> toggleReaction(String userId, ReactionType type) async {
    try {
      AppLogger.debug('toggleReaction called - userId: $userId, type: $type');
      AppLogger.debug(
          'Current state before update: ${state.reactions.length} reactions');

      // isLoading状態を設定する前に現在の状態をキャプチャ
      final currentReactions = [...state.reactions];
      final currentReaction = state.getUserReaction(userId);
      AppLogger.debug('Current reaction before update: $currentReaction');

      state = state.copyWith(isLoading: true, error: null);

      final scheduleStream =
          _ref.read(scheduleRepositoryProvider).watchSchedule(_scheduleId);
      final schedule = await scheduleStream.first;
      AppLogger.debug('Schedule data: $schedule');
      if (schedule == null) {
        throw Exception('Schedule not found');
      }

      final userDoc = await _ref.read(userRepositoryProvider).getUser(userId);
      AppLogger.debug('User data: $userDoc');
      if (userDoc == null) {
        throw Exception('User not found');
      }

      if (currentReaction != null) {
        if (currentReaction.type == type) {
          AppLogger.debug(
              'Removing same reaction - userId: $userId, type: $type');
          await _repository.removeReaction(_scheduleId, userId);

          // リアクション除去後の状態を反映（Stream更新を待たずに反映）
          final updatedReactions =
              currentReactions.where((r) => r.userId != userId).toList();
          AppLogger.debug(
              'Optimistically updating state after removing reaction: ${updatedReactions.length} reactions');
          state = state.copyWith(isLoading: false, reactions: updatedReactions);
        } else {
          AppLogger.debug(
              'Updating to different reaction - from: ${currentReaction.type}, to: $type');
          // 前のリアクションを削除
          await _repository.removeReaction(_scheduleId, userId);

          // 新しいリアクションを追加
          final reactionId =
              await _repository.addReaction(_scheduleId, userId, type);

          // 楽観的に状態を更新
          final updatedReactions = currentReactions.map((r) {
            if (r.userId == userId) {
              // 同じユーザーのリアクションを新しいタイプに更新
              return ScheduleReaction(
                id: reactionId,
                userId: userId,
                type: type,
                createdAt: DateTime.now(),
                userDisplayName: userDoc.displayName,
                userPhotoUrl: userDoc.iconUrl,
              );
            }
            return r;
          }).toList();

          AppLogger.debug(
              'Optimistically updating state after changing reaction: ${updatedReactions.length} reactions');
          state = state.copyWith(isLoading: false, reactions: updatedReactions);

          if (userId != schedule.ownerId) {
            AppLogger.debug(
                'Creating notification for reaction update - fromUserId: $userId, toUserId: ${schedule.ownerId}');
            await _ref
                .read(notificationNotifierProvider.notifier)
                .createReactionNotification(
                  toUserId: schedule.ownerId,
                  fromUserId: userId,
                  scheduleId: _scheduleId,
                  interactionId: reactionId,
                  fromUserDisplayName: userDoc.displayName,
                );

            // プッシュ通知送信
            await _pushNotificationSender.sendReactionNotification(
              toUserId: schedule.ownerId,
              fromUserId: userId,
              fromUserName: userDoc.displayName ?? 'ユーザー',
              scheduleId: _scheduleId,
              interactionId: reactionId,
            );

            AppLogger.debug(
                'Notification created successfully for reaction update');
          } else {
            AppLogger.debug(
                'Skipping notification creation - user is the schedule owner');
          }
        }
      } else {
        AppLogger.debug('Adding new reaction');
        final reactionId =
            await _repository.addReaction(_scheduleId, userId, type);

        // 楽観的に状態を更新
        final newReaction = ScheduleReaction(
          id: reactionId,
          userId: userId,
          type: type,
          createdAt: DateTime.now(),
          userDisplayName: userDoc.displayName,
          userPhotoUrl: userDoc.iconUrl,
        );

        final updatedReactions = [...currentReactions, newReaction];
        AppLogger.debug(
            'Optimistically updating state after adding reaction: ${updatedReactions.length} reactions');
        state = state.copyWith(isLoading: false, reactions: updatedReactions);

        if (userId != schedule.ownerId) {
          AppLogger.debug(
              'Creating notification for new reaction - fromUserId: $userId, toUserId: ${schedule.ownerId}');
          await _ref
              .read(notificationNotifierProvider.notifier)
              .createReactionNotification(
                toUserId: schedule.ownerId,
                fromUserId: userId,
                scheduleId: _scheduleId,
                interactionId: reactionId,
                fromUserDisplayName: userDoc.displayName,
              );

          // プッシュ通知送信
          await _pushNotificationSender.sendReactionNotification(
            toUserId: schedule.ownerId,
            fromUserId: userId,
            fromUserName: userDoc.displayName ?? 'ユーザー',
            scheduleId: _scheduleId,
            interactionId: reactionId,
          );

          AppLogger.debug('Notification created successfully for new reaction');
        } else {
          AppLogger.debug(
              'Skipping notification creation - user is the schedule owner');
        }
      }

      AppLogger.debug(
          'Final state after reaction update: ${state.reactions.length} reactions');
    } catch (e, stack) {
      AppLogger.error('Error in toggleReaction: $e');
      AppLogger.error('Stack trace: $stack');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addComment(String userId, String content) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // スケジュール情報を取得
      final scheduleStream =
          _ref.read(scheduleRepositoryProvider).watchSchedule(_scheduleId);
      final schedule = await scheduleStream.first;
      if (schedule == null) {
        throw Exception('Schedule not found');
      }

      // ユーザー情報を取得
      final userDoc = await _ref.read(userRepositoryProvider).getUser(userId);
      if (userDoc == null) {
        throw Exception('User not found');
      }

      final commentId =
          await _repository.addComment(_scheduleId, userId, content);

      // 自分の投稿以外の場合のみ通知を作成
      if (userId != schedule.ownerId) {
        await _ref
            .read(notificationNotifierProvider.notifier)
            .createCommentNotification(
              toUserId: schedule.ownerId,
              fromUserId: userId,
              scheduleId: _scheduleId,
              interactionId: commentId,
              fromUserDisplayName: userDoc.displayName,
            );

        // プッシュ通知送信
        await _pushNotificationSender.sendCommentNotification(
          toUserId: schedule.ownerId,
          fromUserId: userId,
          fromUserName: userDoc.displayName ?? 'ユーザー',
          scheduleId: _scheduleId,
          interactionId: commentId,
          commentContent: content,
        );
      }

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// コメントを削除する
  ///
  /// [commentId] 削除するコメントのID
  Future<void> deleteComment(String commentId) async {
    try {
      AppLogger.debug(
          'Deleting comment - scheduleId: $_scheduleId, commentId: $commentId');
      await _repository.deleteComment(_scheduleId, commentId);

      AppLogger.debug('Successfully deleted comment: $commentId');
    } catch (e, stackTrace) {
      AppLogger.error('Error deleting comment: $e');
      AppLogger.error('Stack trace: $stackTrace');
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// コメントを更新する
  ///
  /// [commentId] 更新するコメントのID
  /// [content] 更新するコメント内容
  Future<void> updateComment(String commentId, String content) async {
    try {
      AppLogger.debug('======= コメント更新処理開始 =======');
      AppLogger.debug('スケジュールID: $_scheduleId, コメントID: $commentId');
      AppLogger.debug('更新内容: $content');

      // 現在のユーザーIDを確認
      final authState = await _ref.read(authNotifierProvider.future);
      if (authState.user == null) {
        throw Exception('ユーザーが認証されていません');
      }

      final userId = authState.user!.id;
      AppLogger.debug('現在のユーザーID: $userId');

      // 既存コメントを確認
      final comments = await _repository.getComments(_scheduleId);
      final targetComment = comments.firstWhere(
        (c) => c.id == commentId,
        orElse: () => throw Exception('コメントが見つかりません: $commentId'),
      );

      AppLogger.debug('対象コメント: $targetComment');
      AppLogger.debug('コメント所有者ID: ${targetComment.userId}');

      if (targetComment.userId != userId) {
        throw Exception('このコメントを編集する権限がありません');
      }

      await _repository.updateComment(_scheduleId, commentId, content);

      AppLogger.debug('コメント更新成功: $commentId');
      AppLogger.debug('======= コメント更新処理完了 =======');
    } catch (e, stackTrace) {
      AppLogger.error('コメント更新エラー: $e');
      AppLogger.error('スタックトレース: $stackTrace');
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// コメントを監視する
  ///
  /// コメントの変更を[ScheduleInteractionState]の`comments`に反映します。
  void _watchComments() {
    // ... existing code ...
  }

  @override
  void dispose() {
    _reactionsSubscription?.cancel();
    _commentsSubscription?.cancel();
    super.dispose();
  }
}
