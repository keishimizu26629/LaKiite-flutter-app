import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entity/notification.dart' as domain;
import '../../domain/interfaces/i_notification_repository.dart';
import '../../infrastructure/notification_repository.dart';
import '../../utils/logger.dart';
import '../../infrastructure/user_repository.dart';
import '../../infrastructure/firebase/push_notification_sender.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../../presentation/presentation_provider.dart';

typedef Notification = domain.Notification;
typedef NotificationType = domain.NotificationType;

/// 通知リポジトリのインスタンスを提供する
final notificationRepositoryProvider = Provider<INotificationRepository>((ref) {
  return NotificationRepository();
});

/// FirebaseAuthの状態変更を監視するStreamプロバイダー
final firebaseAuthStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// 現在のユーザーIDを提供するプロバイダー
final currentUserIdProvider = Provider<String?>((ref) {
  // ログ出力を追加
  AppLogger.debug('currentUserIdProvider - 読み込み開始');

  // まず直接FirebaseAuthからユーザーIDを取得
  final firebaseAuth = FirebaseAuth.instance;
  final currentUser = firebaseAuth.currentUser;
  final directUserId = currentUser?.uid;

  // 次にauthStateからユーザーIDを取得 (一般的にこちらの方が信頼性が高い)
  final authState = ref.watch(authNotifierProvider);
  final stateUserId = authState.value?.user?.id;

  // FirebaseAuthの状態変更も監視
  final firebaseAuthState = ref.watch(firebaseAuthStateProvider);
  final firebaseAuthUserId = firebaseAuthState.value?.uid;

  // 優先順位: authState > firebaseAuthState > directUserId
  final effectiveUserId = stateUserId ?? firebaseAuthUserId ?? directUserId;

  AppLogger.debug(
      'currentUserIdProvider - 取得結果比較: FirebaseAuth直接=$directUserId, authState=$stateUserId, firebaseAuthStream=$firebaseAuthUserId, 使用=$effectiveUserId');

  return effectiveUserId;
});

/// 未読の通知数を監視するプロバイダー
///
/// ログインユーザーの全ての未読通知数のストリームを提供する
/// 未ログイン時は0を返す
final unreadNotificationCountProvider = StreamProvider<int>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(0);
  return repository.watchUnreadCount(userId);
});

/// タイプ別の未読通知数を監視するプロバイダー
///
/// [type] 監視対象の通知タイプ
/// ログインユーザーの指定タイプの未読通知数のストリームを提供する
/// 未ログイン時は0を返す
final unreadNotificationCountByTypeProvider =
    StreamProvider.family<int, NotificationType>((ref, type) {
  final repository = ref.watch(notificationRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(0);
  return repository.watchUnreadCountByType(userId, type);
});

/// 受信した通知一覧を監視するプロバイダー
///
/// ログインユーザーが受信した全ての通知のストリームを提供する
/// 未ログイン時は空配列を返す
final receivedNotificationsProvider = StreamProvider<List<Notification>>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);
  return repository.watchReceivedNotifications(userId);
});

/// タイプ別の受信通知一覧を監視するプロバイダー
///
/// [type] 監視対象の通知タイプ
/// ログインユーザーが受信した指定タイプの通知のストリームを提供する
/// 未ログイン時は空配列を返す
final receivedNotificationsByTypeProvider =
    StreamProvider.family<List<Notification>, NotificationType>((ref, type) {
  final repository = ref.watch(notificationRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);
  return repository.watchReceivedNotificationsByType(userId, type);
});

/// 送信した通知一覧を監視するプロバイダー
///
/// ログインユーザーが送信した全ての通知のストリームを提供する
/// 未ログイン時は空配列を返す
final sentNotificationsProvider = StreamProvider<List<Notification>>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);
  return repository.watchSentNotifications(userId);
});

/// タイプ別の送信通知一覧を監視するプロバイダー
///
/// [type] 監視対象の通知タイプ
/// ログインユーザーが送信した指定タイプの通知のストリームを提供する
/// 未ログイン時は空配列を返す
final sentNotificationsByTypeProvider =
    StreamProvider.family<List<Notification>, NotificationType>((ref, type) {
  final repository = ref.watch(notificationRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);
  return repository.watchSentNotificationsByType(userId, type);
});

/// 通知の作成、更新、承認などの操作を提供するNotifier
///
/// 各操作の実行中はローディング状態を提供し、
/// エラーが発生した場合はエラー状態を提供する
class NotificationNotifier extends StateNotifier<AsyncValue<void>> {
  final INotificationRepository _repository;
  final PushNotificationSender _pushNotificationSender;
  final Ref _ref;

  NotificationNotifier(this._repository, this._ref)
      : _pushNotificationSender = PushNotificationSender(),
        super(const AsyncValue.data(null));

  /// フレンド申請通知を作成する
  ///
  /// [toUserId] 送信先のユーザーID
  /// [fromUserId] 送信元のユーザーID
  /// [fromUserDisplayName] 送信元のユーザー表示名（オプション）
  /// [toUserDisplayName] 送信先のユーザー表示名（オプション）
  Future<void> createFriendRequest({
    required String toUserId,
    required String fromUserId,
    String? fromUserDisplayName,
    String? toUserDisplayName,
  }) async {
    state = const AsyncValue.loading();
    try {
      // アプリ内通知を作成
      final notification = Notification.createFriendRequest(
        fromUserId: fromUserId,
        toUserId: toUserId,
        fromUserDisplayName: fromUserDisplayName,
        toUserDisplayName: toUserDisplayName,
      );
      await _repository.createNotification(notification);

      // プッシュ通知を送信
      await _pushNotificationSender.sendFriendRequestNotification(
        toUserId: toUserId,
        fromUserId: fromUserId,
        fromUserName: fromUserDisplayName ?? fromUserId,
      );

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      AppLogger.error('友達申請通知作成エラー: $e');
      AppLogger.error('スタックトレース: $stack');
      state = AsyncValue.error(e, stack);
    }
  }

  /// グループ招待通知を作成する
  ///
  /// [toUserId] 送信先のユーザーID
  /// [fromUserId] 送信元のユーザーID
  /// [groupId] 招待するグループのID
  /// [fromUserDisplayName] 送信元のユーザー表示名（オプション）
  /// [toUserDisplayName] 送信先のユーザー表示名（オプション）
  Future<void> createGroupInvitation({
    required String toUserId,
    required String fromUserId,
    required String groupId,
    String? groupName,
    String? fromUserDisplayName,
    String? toUserDisplayName,
  }) async {
    state = const AsyncValue.loading();
    try {
      // アプリ内通知を作成
      final notification = Notification.createGroupInvitation(
        fromUserId: fromUserId,
        toUserId: toUserId,
        groupId: groupId,
        fromUserDisplayName: fromUserDisplayName,
        toUserDisplayName: toUserDisplayName,
      );
      await _repository.createNotification(notification);

      // グループ名がある場合はプッシュ通知も送信
      if (groupName != null) {
        await _pushNotificationSender.sendGroupInvitationNotification(
          toUserId: toUserId,
          fromUserId: fromUserId,
          fromUserName: fromUserDisplayName ?? fromUserId,
          groupId: groupId,
          groupName: groupName,
        );
      }

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// 通知を承認する
  ///
  /// [notificationId] 承認する通知のID
  Future<void> acceptNotification(String notificationId) async {
    state = const AsyncValue.loading();
    try {
      // 通知の内容を取得して、通知タイプを確認
      final notification = await _repository.getNotification(notificationId);

      // 通知を承認
      await _repository.acceptNotification(notificationId);

      // キャッシュクリア処理
      if (notification != null &&
          notification.type == NotificationType.friend) {
        // フレンド申請承認時は既存のプロバイダーインスタンスのキャッシュをクリア
        try {
          // 既存のプロバイダーインスタンスを使用してキャッシュをクリア
          final userRepo = _ref.read(userRepositoryProvider);
          if (userRepo is UserRepository) {
            userRepo.clearCache();
            AppLogger.debug('フレンド申請承認時にUserRepositoryキャッシュをクリアしました');
          }

          // プロバイダー自体も無効化してより確実にキャッシュをクリア
          _ref.invalidate(userRepositoryProvider);
          AppLogger.debug('フレンド申請承認時にuserRepositoryProviderを無効化しました');
        } catch (e) {
          // キャッシュクリアに失敗しても処理は続行
          AppLogger.error('フレンド申請承認時のキャッシュクリアに失敗: $e');
        }
      }

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// 通知を拒否する
  ///
  /// [notificationId] 拒否する通知のID
  Future<void> rejectNotification(String notificationId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.rejectNotification(notificationId);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// 通知を既読にする
  ///
  /// [notificationId] 既読にする通知のID
  Future<void> markAsRead(String notificationId) async {
    AppLogger.debug('markAsRead called - notificationId: $notificationId');
    state = const AsyncValue.loading();
    try {
      // 最初に通知の情報を取得して詳細をログに出力
      final notification = await _repository.getNotification(notificationId);
      if (notification == null) {
        AppLogger.error('Notification not found: $notificationId');
        throw Exception('Notification not found');
      }

      AppLogger.debug('Found notification: id=${notification.id}, '
          'type=${notification.type.name}, '
          'isRead=${notification.isRead}, '
          'relatedItemId=${notification.relatedItemId ?? "null"}, '
          'interactionId=${notification.interactionId ?? "null"}');

      // すでに既読なら処理をスキップ
      if (notification.isRead) {
        AppLogger.debug('Notification already marked as read: $notificationId');
        state = const AsyncValue.data(null);
        return;
      }

      // 既読にする
      await _repository.markAsRead(notificationId);
      AppLogger.debug(
          'Notification marked as read successfully: $notificationId');
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      AppLogger.error('Error marking notification as read: $e');
      AppLogger.error('Stack trace: $stack');
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// リアクション通知を作成する
  ///
  /// [toUserId] 送信先のユーザーID（投稿作成者）
  /// [fromUserId] 送信元のユーザーID（リアクションした人）
  /// [scheduleId] スケジュールのID
  /// [interactionId] リアクションのID
  /// [fromUserDisplayName] 送信元のユーザー表示名（オプション）
  Future<void> createReactionNotification({
    required String toUserId,
    required String fromUserId,
    required String scheduleId,
    required String interactionId,
    String? fromUserDisplayName,
  }) async {
    AppLogger.debug(
        'Creating reaction notification - toUserId: $toUserId, fromUserId: $fromUserId, scheduleId: $scheduleId, interactionId: $interactionId');
    state = const AsyncValue.loading();
    try {
      final notification = Notification.createReactionNotification(
        fromUserId: fromUserId,
        toUserId: toUserId,
        relatedItemId: scheduleId,
        interactionId: interactionId,
        fromUserDisplayName: fromUserDisplayName,
      );
      AppLogger.debug('Created notification object: $notification');
      await _repository.createNotification(notification);
      AppLogger.debug(
          'Successfully created reaction notification in Firestore');
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      AppLogger.error('Error creating reaction notification: $e');
      AppLogger.error('Stack trace: $stack');
      state = AsyncValue.error(e, stack);
    }
  }

  /// コメント通知を作成する
  ///
  /// [toUserId] 送信先のユーザーID（投稿作成者）
  /// [fromUserId] 送信元のユーザーID（コメントした人）
  /// [scheduleId] スケジュールのID
  /// [interactionId] コメントのID
  /// [fromUserDisplayName] 送信元のユーザー表示名（オプション）
  Future<void> createCommentNotification({
    required String toUserId,
    required String fromUserId,
    required String scheduleId,
    required String interactionId,
    String? fromUserDisplayName,
  }) async {
    AppLogger.debug(
        'Creating comment notification - toUserId: $toUserId, fromUserId: $fromUserId, scheduleId: $scheduleId, interactionId: $interactionId');
    state = const AsyncValue.loading();
    try {
      final notification = Notification.createCommentNotification(
        fromUserId: fromUserId,
        toUserId: toUserId,
        relatedItemId: scheduleId,
        interactionId: interactionId,
        fromUserDisplayName: fromUserDisplayName,
      );
      AppLogger.debug('Created notification object: $notification');
      await _repository.createNotification(notification);
      AppLogger.debug('Successfully created comment notification in Firestore');
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      AppLogger.error('Error creating comment notification: $e');
      AppLogger.error('Stack trace: $stack');
      state = AsyncValue.error(e, stack);
    }
  }
}

/// 通知操作を提供するNotifierのプロバイダー
final notificationNotifierProvider =
    StateNotifierProvider<NotificationNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return NotificationNotifier(repository, ref);
});
