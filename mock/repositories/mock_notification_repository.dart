import 'package:lakiite/domain/entity/notification.dart';
import 'package:lakiite/domain/interfaces/i_notification_repository.dart';

class MockNotificationRepository implements INotificationRepository {
  final List<Notification> _notifications = [];

  void addTestNotification(Notification notification) {
    _notifications.add(notification);
  }

  void reset() {
    _notifications.clear();
  }

  @override
  Future<void> acceptNotification(String notificationId) async {}

  @override
  Future<void> createNotification(Notification notification) async {
    _notifications.add(notification);
  }

  @override
  Future<Notification?> getNotification(String notificationId) async {
    for (final notification in _notifications) {
      if (notification.id == notificationId) {
        return notification;
      }
    }
    return null;
  }

  @override
  Future<bool> hasPendingFriendRequest(String fromUserId, String toUserId) async {
    return false;
  }

  @override
  Future<bool> hasPendingGroupInvitation(
    String fromUserId,
    String toUserId,
    String groupId,
  ) async {
    return false;
  }

  @override
  Future<void> markAsRead(String notificationId) async {}

  @override
  Future<void> rejectNotification(String notificationId) async {}

  @override
  Future<void> updateNotification(Notification notification) async {}

  @override
  Stream<List<Notification>> watchReceivedNotifications(String userId) async* {
    yield _notifications.where((n) => n.receiveUserId == userId).toList();
  }

  @override
  Stream<List<Notification>> watchReceivedNotificationsByType(
    String userId,
    NotificationType type,
  ) async* {
    yield _notifications
        .where((n) => n.receiveUserId == userId && n.type == type)
        .toList();
  }

  @override
  Stream<List<Notification>> watchSentNotifications(String userId) async* {
    yield _notifications.where((n) => n.sendUserId == userId).toList();
  }

  @override
  Stream<List<Notification>> watchSentNotificationsByType(
    String userId,
    NotificationType type,
  ) async* {
    yield _notifications
        .where((n) => n.sendUserId == userId && n.type == type)
        .toList();
  }

  @override
  Stream<int> watchUnreadCount(String userId) async* {
    yield _notifications
        .where((n) => n.receiveUserId == userId && !n.isRead)
        .length;
  }

  @override
  Stream<int> watchUnreadCountByType(String userId, NotificationType type) async* {
    yield _notifications
        .where(
          (n) => n.receiveUserId == userId && n.type == type && !n.isRead,
        )
        .length;
  }
}
