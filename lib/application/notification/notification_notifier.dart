import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entity/notification.dart' as domain;
import '../../domain/interfaces/i_notification_repository.dart';
import '../../infrastructure/notification_repository.dart';
import '../../utils/logger.dart';
import '../auth/auth_notifier.dart';
import '../../infrastructure/user_repository.dart';

typedef Notification = domain.Notification;
typedef NotificationType = domain.NotificationType;

/// 通知リポジトリのインスタンスを提供する
final notificationRepositoryProvider = Provider<INotificationRepository>((ref) {
  return NotificationRepository();
});

/// 現在のユーザーIDを提供するプロバイダー
final currentUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.value?.user?.id;
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

  NotificationNotifier(this._repository) : super(const AsyncValue.data(null));

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
      final notification = Notification.createFriendRequest(
        fromUserId: fromUserId,
        toUserId: toUserId,
        fromUserDisplayName: fromUserDisplayName,
        toUserDisplayName: toUserDisplayName,
      );
      await _repository.createNotification(notification);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
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
    String? fromUserDisplayName,
    String? toUserDisplayName,
  }) async {
    state = const AsyncValue.loading();
    try {
      final notification = Notification.createGroupInvitation(
        fromUserId: fromUserId,
        toUserId: toUserId,
        groupId: groupId,
        fromUserDisplayName: fromUserDisplayName,
        toUserDisplayName: toUserDisplayName,
      );
      await _repository.createNotification(notification);
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
        // フレンド申請承認時は明示的にユーザーリポジトリのキャッシュをクリア
        // これは通常、プロバイダーのinvalidateによって行われるが、
        // さらに確実に行うためにリポジトリのキャッシュも明示的にクリア
        try {
          final userRepository = UserRepository();
          userRepository.clearCache();
        } catch (e) {
          // キャッシュクリアに失敗しても処理は続行
          AppLogger.error('Failed to clear user repository cache: $e');
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
    state = const AsyncValue.loading();
    try {
      await _repository.markAsRead(notificationId);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
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
  return NotificationNotifier(repository);
});
