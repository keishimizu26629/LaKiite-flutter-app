import 'dart:async';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lakiite/domain/entity/schedule_reaction.dart';
import 'package:lakiite/domain/entity/schedule_comment.dart';
import 'package:lakiite/domain/interfaces/i_schedule_interaction_repository.dart';
import 'package:lakiite/application/schedule/schedule_interaction_state.dart';
import 'package:lakiite/utils/logger.dart';
import 'package:lakiite/application/notification/notification_notifier.dart';
import 'package:lakiite/presentation/presentation_provider.dart';
import '../../infrastructure/firebase/push_notification_sender.dart';

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
  final bool _enablePushNotifications;
  PushNotificationSender? _pushNotificationSender;

  ScheduleInteractionNotifier(
    this._repository,
    this._scheduleId,
    this._ref, {
    PushNotificationSender? pushNotificationSender,
    bool enablePushNotifications = true,
  })  : _enablePushNotifications = enablePushNotifications,
        super(const ScheduleInteractionState()) {
    if (_enablePushNotifications) {
      _pushNotificationSender =
          pushNotificationSender ?? PushNotificationSender();
    } else {
      _pushNotificationSender = pushNotificationSender;
    }
    _initializeSubscriptions();
  }

  Future<void> _initializeSubscriptions() async {
    try {
      final authState = await _ref.read(authNotifierProvider.future);
      if (!mounted) {
        return;
      }
      if (authState.user == null) {
        throw Exception('User not authenticated');
      }

      _reactionsSubscription = _repository.watchReactions(_scheduleId).listen(
        (reactions) {
          if (!mounted) return;
          state = state.copyWith(reactions: reactions);
        },
        onError: (error) {
          if (!mounted) return;
          state = state.copyWith(error: error.toString());
        },
      );

      _commentsSubscription = _repository.watchComments(_scheduleId).listen(
        (comments) {
          if (!mounted) return;
          state = state.copyWith(comments: comments);
        },
        onError: (error) {
          if (!mounted) return;
          state = state.copyWith(error: error.toString());
        },
      );
    } catch (e) {
      AppLogger.error('Error initializing subscriptions: $e');
      if (mounted) {
        state = state.copyWith(error: e.toString());
      }
    }
  }

  Future<void> toggleReaction(String userId, ReactionType type) async {
    try {
      AppLogger.debug('toggleReaction called - userId: $userId, type: $type');
      AppLogger.debug(
          'Current state before update: ${state.reactions.length} reactions');

      final currentReaction = state.getUserReaction(userId);
      AppLogger.debug('Current reaction before update: $currentReaction');

      state = state.copyWith(isLoading: true, error: null);

      final scheduleStream =
          _ref.read(scheduleRepositoryProvider).watchSchedule(_scheduleId);
      final schedule = await scheduleStream.first;
      if (!mounted) {
        return;
      }
      AppLogger.debug('Schedule data: $schedule');
      if (schedule == null) {
        throw Exception('Schedule not found');
      }

      final userDoc = await _ref.read(userRepositoryProvider).getUser(userId);
      if (!mounted) {
        return;
      }
      AppLogger.debug('User data: $userDoc');
      if (userDoc == null) {
        throw Exception('User not found');
      }

      if (currentReaction != null) {
        if (currentReaction.type == type) {
          AppLogger.debug(
              'Removing same reaction - userId: $userId, type: $type');
          await _repository.removeReaction(_scheduleId, userId);

          final latestReactions = state.reactions;
          final updatedReactions =
              latestReactions.where((r) => r.userId != userId).toList();
          AppLogger.debug(
              'Optimistically updating state after removing reaction: ${updatedReactions.length} reactions');
          if (!mounted) return;
          state = state.copyWith(isLoading: false, reactions: updatedReactions);
        } else {
          AppLogger.debug(
              'Updating to different reaction - from: ${currentReaction.type}, to: $type');
          await _repository.removeReaction(_scheduleId, userId);

          final reactionId =
              await _repository.addReaction(_scheduleId, userId, type);

          final latestReactions = state.reactions
              .where((reaction) => reaction.userId != userId)
              .toList();
          final updatedReactions = [
            ...latestReactions,
            ScheduleReaction(
              id: reactionId,
              userId: userId,
              type: type,
              createdAt: DateTime.now(),
              userDisplayName: userDoc.displayName,
              userPhotoUrl: userDoc.iconUrl,
            ),
          ];

          AppLogger.debug(
              'Optimistically updating state after changing reaction: ${updatedReactions.length} reactions');
          if (!mounted) return;
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
            if (!mounted) return;
            if (_enablePushNotifications && _pushNotificationSender != null) {
              await _pushNotificationSender!.sendReactionNotification(
                toUserId: schedule.ownerId,
                fromUserId: userId,
                fromUserName: userDoc.displayName,
                scheduleId: _scheduleId,
                interactionId: reactionId,
              );
            }

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

        final newReaction = ScheduleReaction(
          id: reactionId,
          userId: userId,
          type: type,
          createdAt: DateTime.now(),
          userDisplayName: userDoc.displayName,
          userPhotoUrl: userDoc.iconUrl,
        );

        final latestReactions = state.reactions
            .where((reaction) => reaction.userId != userId)
            .toList();
        final updatedReactions = [...latestReactions, newReaction];
        AppLogger.debug(
            'Optimistically updating state after adding reaction: ${updatedReactions.length} reactions');
        if (!mounted) return;
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
          if (!mounted) return;
          if (_enablePushNotifications && _pushNotificationSender != null) {
            await _pushNotificationSender!.sendReactionNotification(
              toUserId: schedule.ownerId,
              fromUserId: userId,
              fromUserName: userDoc.displayName,
              scheduleId: _scheduleId,
              interactionId: reactionId,
            );
          }

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
      if (mounted) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
    }
  }

  Future<void> addComment(String userId, String content) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final scheduleStream =
          _ref.read(scheduleRepositoryProvider).watchSchedule(_scheduleId);
      final schedule = await scheduleStream.first;
      if (!mounted) {
        return;
      }
      if (schedule == null) {
        throw Exception('Schedule not found');
      }

      final userDoc = await _ref.read(userRepositoryProvider).getUser(userId);
      if (!mounted) {
        return;
      }
      if (userDoc == null) {
        throw Exception('User not found');
      }

      final commentId =
          await _repository.addComment(_scheduleId, userId, content);

      // TODO: 通知機能は後で実装
      AppLogger.debug('Comment added: $commentId');

      if (!mounted) {
        return;
      }
      state = state.copyWith(isLoading: false);
    } catch (e) {
      if (mounted) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
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

  @override
  void dispose() {
    _reactionsSubscription?.cancel();
    _commentsSubscription?.cancel();
    super.dispose();
  }
}
