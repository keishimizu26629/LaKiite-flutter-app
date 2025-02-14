import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entity/notification.dart';
import '../../domain/interfaces/i_notification_repository.dart';
import '../../infrastructure/notification_repository.dart';
import '../auth/auth_notifier.dart';

final notificationRepositoryProvider = Provider<INotificationRepository>((ref) {
  return NotificationRepository();
});

/// 現在のユーザーIDを提供するプロバイダー
final currentUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.value?.user?.id;
});

/// 未読の通知数を監視するプロバイダー
final unreadNotificationCountProvider = StreamProvider<int>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(0);
  return repository.watchUnreadCount(userId);
});

/// タイプ別の未読通知数を監視するプロバイダー
final unreadNotificationCountByTypeProvider = StreamProvider.family<int, NotificationType>((ref, type) {
  final repository = ref.watch(notificationRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(0);
  return repository.watchUnreadCountByType(userId, type);
});

/// 受信した通知一覧を監視するプロバイダー
final receivedNotificationsProvider = StreamProvider<List<Notification>>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);
  return repository.watchReceivedNotifications(userId);
});

/// タイプ別の受信通知一覧を監視するプロバイダー
final receivedNotificationsByTypeProvider = StreamProvider.family<List<Notification>, NotificationType>((ref, type) {
  final repository = ref.watch(notificationRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);
  return repository.watchReceivedNotificationsByType(userId, type);
});

/// 送信した通知一覧を監視するプロバイダー
final sentNotificationsProvider = StreamProvider<List<Notification>>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);
  return repository.watchSentNotifications(userId);
});

/// タイプ別の送信通知一覧を監視するプロバイダー
final sentNotificationsByTypeProvider = StreamProvider.family<List<Notification>, NotificationType>((ref, type) {
  final repository = ref.watch(notificationRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);
  return repository.watchSentNotificationsByType(userId, type);
});

/// 通知の作成、更新、承認などの操作を提供するNotifier
class NotificationNotifier extends StateNotifier<AsyncValue<void>> {
  final INotificationRepository _repository;

  NotificationNotifier(this._repository) : super(const AsyncValue.data(null));

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

  Future<void> acceptNotification(String notificationId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.acceptNotification(notificationId);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> rejectNotification(String notificationId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.rejectNotification(notificationId);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> markAsRead(String notificationId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.markAsRead(notificationId);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final notificationNotifierProvider = StateNotifierProvider<NotificationNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return NotificationNotifier(repository);
});
