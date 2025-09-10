import 'package:lakiite/domain/interfaces/i_notification_repository.dart';
import 'package:lakiite/domain/entity/notification.dart';
import '../base_mock.dart';

class MockNotificationRepository extends BaseMock
    implements INotificationRepository {
  final List<Notification> _notifications = [];
  bool _shouldFailCreate = false;
  bool _shouldFailUpdate = false;
  bool _shouldFailGet = false;

  void setShouldFailCreate(bool shouldFail) {
    _shouldFailCreate = shouldFail;
  }

  void setShouldFailUpdate(bool shouldFail) {
    _shouldFailUpdate = shouldFail;
  }

  void setShouldFailGet(bool shouldFail) {
    _shouldFailGet = shouldFail;
  }

  void addTestNotification(Notification notification) {
    _notifications.add(notification);
  }

  void clearNotifications() {
    _notifications.clear();
  }

  @override
  Future<void> createNotification(Notification notification) async {
    await Future.delayed(const Duration(milliseconds: 200));

    if (_shouldFailCreate) {
      throw Exception('テスト用作成失敗');
    }

    final newNotification = Notification(
      id: 'notification-${_notifications.length}',
      type: notification.type,
      sendUserId: notification.sendUserId,
      receiveUserId: notification.receiveUserId,
      sendUserDisplayName: notification.sendUserDisplayName,
      receiveUserDisplayName: notification.receiveUserDisplayName,
      status: notification.status,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      rejectionCount: notification.rejectionCount,
      isRead: notification.isRead,
      groupId: notification.groupId,
      relatedItemId: notification.relatedItemId,
      interactionId: notification.interactionId,
    );

    _notifications.add(newNotification);
  }

  @override
  Future<void> updateNotification(Notification notification) async {
    await Future.delayed(const Duration(milliseconds: 200));

    if (_shouldFailUpdate) {
      throw Exception('テスト用更新失敗');
    }

    final index = _notifications.indexWhere((n) => n.id == notification.id);
    if (index >= 0) {
      _notifications[index] = notification;
    } else {
      throw Exception('通知が見つかりません');
    }
  }

  @override
  Future<Notification?> getNotification(String notificationId) async {
    await Future.delayed(const Duration(milliseconds: 100));

    if (_shouldFailGet) {
      throw Exception('テスト用取得失敗');
    }

    try {
      return _notifications.firstWhere((n) => n.id == notificationId);
    } catch (e) {
      return null;
    }
  }

  @override
  Stream<List<Notification>> watchReceivedNotifications(String userId) {
    return Stream.periodic(const Duration(milliseconds: 100), (_) {
      return _notifications.where((n) => n.receiveUserId == userId).toList();
    }).take(1);
  }

  @override
  Stream<List<Notification>> watchReceivedNotificationsByType(
    String userId,
    NotificationType type,
  ) {
    return Stream.periodic(const Duration(milliseconds: 100), (_) {
      return _notifications
          .where((n) => n.receiveUserId == userId && n.type == type)
          .toList();
    }).take(1);
  }

  @override
  Stream<List<Notification>> watchSentNotifications(String userId) {
    return Stream.periodic(const Duration(milliseconds: 100), (_) {
      return _notifications.where((n) => n.sendUserId == userId).toList();
    }).take(1);
  }

  @override
  Stream<List<Notification>> watchSentNotificationsByType(
    String userId,
    NotificationType type,
  ) {
    return Stream.periodic(const Duration(milliseconds: 100), (_) {
      return _notifications
          .where((n) => n.sendUserId == userId && n.type == type)
          .toList();
    }).take(1);
  }

  @override
  Future<bool> hasPendingFriendRequest(
      String fromUserId, String toUserId) async {
    await Future.delayed(const Duration(milliseconds: 100));

    return _notifications.any((n) =>
        n.type == NotificationType.friend &&
        n.sendUserId == fromUserId &&
        n.receiveUserId == toUserId &&
        n.status == NotificationStatus.pending);
  }

  @override
  Future<bool> hasPendingGroupInvitation(
    String fromUserId,
    String toUserId,
    String groupId,
  ) async {
    await Future.delayed(const Duration(milliseconds: 100));

    return _notifications.any((n) =>
        n.type == NotificationType.groupInvitation &&
        n.sendUserId == fromUserId &&
        n.receiveUserId == toUserId &&
        n.groupId == groupId &&
        n.status == NotificationStatus.pending);
  }

  @override
  Future<void> acceptNotification(String notificationId) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index >= 0) {
      final notification = _notifications[index];
      _notifications[index] = Notification(
        id: notification.id,
        type: notification.type,
        sendUserId: notification.sendUserId,
        receiveUserId: notification.receiveUserId,
        sendUserDisplayName: notification.sendUserDisplayName,
        receiveUserDisplayName: notification.receiveUserDisplayName,
        status: NotificationStatus.accepted,
        createdAt: notification.createdAt,
        updatedAt: DateTime.now(),
        rejectionCount: notification.rejectionCount,
        isRead: true,
        groupId: notification.groupId,
        relatedItemId: notification.relatedItemId,
        interactionId: notification.interactionId,
      );
    }
  }

  @override
  Future<void> rejectNotification(String notificationId) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index >= 0) {
      final notification = _notifications[index];
      _notifications[index] = Notification(
        id: notification.id,
        type: notification.type,
        sendUserId: notification.sendUserId,
        receiveUserId: notification.receiveUserId,
        sendUserDisplayName: notification.sendUserDisplayName,
        receiveUserDisplayName: notification.receiveUserDisplayName,
        status: NotificationStatus.rejected,
        createdAt: notification.createdAt,
        updatedAt: DateTime.now(),
        rejectionCount: notification.rejectionCount + 1,
        isRead: true,
        groupId: notification.groupId,
        relatedItemId: notification.relatedItemId,
        interactionId: notification.interactionId,
      );
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index >= 0) {
      final notification = _notifications[index];
      _notifications[index] = Notification(
        id: notification.id,
        type: notification.type,
        sendUserId: notification.sendUserId,
        receiveUserId: notification.receiveUserId,
        sendUserDisplayName: notification.sendUserDisplayName,
        receiveUserDisplayName: notification.receiveUserDisplayName,
        status: notification.status,
        createdAt: notification.createdAt,
        updatedAt: notification.updatedAt,
        rejectionCount: notification.rejectionCount,
        isRead: true,
        groupId: notification.groupId,
        relatedItemId: notification.relatedItemId,
        interactionId: notification.interactionId,
      );
    }
  }

  @override
  Stream<int> watchUnreadCount(String userId) {
    return Stream.periodic(const Duration(milliseconds: 100), (_) {
      return _notifications
          .where((n) => n.receiveUserId == userId && !n.isRead)
          .length;
    }).take(1);
  }

  @override
  Stream<int> watchUnreadCountByType(String userId, NotificationType type) {
    return Stream.periodic(const Duration(milliseconds: 100), (_) {
      return _notifications
          .where(
              (n) => n.receiveUserId == userId && !n.isRead && n.type == type)
          .length;
    }).take(1);
  }

  /// テスト用のリセット機能
  void reset() {
    _notifications.clear();
    _shouldFailCreate = false;
    _shouldFailUpdate = false;
    _shouldFailGet = false;
  }
}
