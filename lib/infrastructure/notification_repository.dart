import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../domain/entity/notification.dart';
import '../domain/interfaces/i_notification_repository.dart';

class NotificationRepository implements INotificationRepository {
  final FirebaseFirestore _firestore;

  NotificationRepository() : _firestore = FirebaseFirestore.instance;

  @override
  Future<void> createNotification(Notification notification) async {
    debugPrint('Creating notification: ${notification.toFirestore()}');
    try {
      final docRef = _firestore.collection('notifications').doc();
      await docRef.set(notification.toFirestore());
      debugPrint('Notification created successfully with ID: ${docRef.id}');
    } catch (e) {
      debugPrint('Error creating notification: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateNotification(Notification notification) async {
    debugPrint('Updating notification: ${notification.id}');
    try {
      await _firestore
          .collection('notifications')
          .doc(notification.id)
          .update(notification.toFirestore());
      debugPrint('Notification updated successfully: ${notification.id}');
    } catch (e) {
      debugPrint('Error updating notification: $e');
      rethrow;
    }
  }

  @override
  Future<Notification?> getNotification(String notificationId) async {
    debugPrint('Getting notification: $notificationId');
    try {
      final doc = await _firestore.collection('notifications').doc(notificationId).get();
      if (!doc.exists) {
        debugPrint('Notification not found: $notificationId');
        return null;
      }
      final data = doc.data()!;
      data['id'] = doc.id;
      debugPrint('Notification retrieved successfully: $notificationId');
      return Notification.fromJson(data);
    } catch (e) {
      debugPrint('Error getting notification: $e');
      rethrow;
    }
  }

  @override
  Stream<List<Notification>> watchReceivedNotifications(String userId) {
    debugPrint('Watching received notifications for user: $userId');
    return _firestore
        .collection('notifications')
        .where('receiveUserId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .orderBy('__name__', descending: true)  // 追加: ドキュメントIDでの安定したソート
        .snapshots()
        .distinct()
        .map(_mapQuerySnapshotToNotifications);
  }

  @override
  Stream<List<Notification>> watchReceivedNotificationsByType(
    String userId,
    NotificationType type,
  ) {
    debugPrint('Watching received notifications for user: $userId, type: ${type.name}');
    return _firestore
        .collection('notifications')
        .where('receiveUserId', isEqualTo: userId)
        .where('type', isEqualTo: type.name)
        .orderBy('createdAt', descending: true)
        .orderBy('__name__', descending: true)  // 追加: ドキュメントIDでの安定したソート
        .snapshots()
        .distinct()
        .map(_mapQuerySnapshotToNotifications);
  }

  @override
  Stream<List<Notification>> watchSentNotifications(String userId) {
    debugPrint('Watching sent notifications for user: $userId');
    return _firestore
        .collection('notifications')
        .where('sendUserId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .orderBy('__name__', descending: true)  // 追加: ドキュメントIDでの安定したソート
        .snapshots()
        .distinct()
        .map(_mapQuerySnapshotToNotifications);
  }

  @override
  Stream<List<Notification>> watchSentNotificationsByType(
    String userId,
    NotificationType type,
  ) {
    debugPrint('Watching sent notifications for user: $userId, type: ${type.name}');
    return _firestore
        .collection('notifications')
        .where('sendUserId', isEqualTo: userId)
        .where('type', isEqualTo: type.name)
        .orderBy('createdAt', descending: true)
        .orderBy('__name__', descending: true)  // 追加: ドキュメントIDでの安定したソート
        .snapshots()
        .distinct()
        .map(_mapQuerySnapshotToNotifications);
  }

  List<Notification> _mapQuerySnapshotToNotifications(QuerySnapshot snapshot) {
    final notifications = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return Notification.fromJson(data);
    }).toList();
    debugPrint('Received ${notifications.length} notifications');
    return notifications;
  }

  @override
  Future<bool> hasPendingFriendRequest(String fromUserId, String toUserId) async {
    debugPrint('Checking pending friend request from $fromUserId to $toUserId');
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('type', isEqualTo: NotificationType.friend.name)
          .where('sendUserId', isEqualTo: fromUserId)
          .where('receiveUserId', isEqualTo: toUserId)
          .where('status', isEqualTo: NotificationStatus.pending.name)
          .get();
      final hasPending = snapshot.docs.isNotEmpty;
      debugPrint('Pending friend request check result: $hasPending');
      return hasPending;
    } catch (e) {
      debugPrint('Error checking pending friend request: $e');
      rethrow;
    }
  }

  @override
  Future<bool> hasPendingGroupInvitation(
    String fromUserId,
    String toUserId,
    String groupId,
  ) async {
    debugPrint('Checking pending group invitation from $fromUserId to $toUserId for group $groupId');
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('type', isEqualTo: NotificationType.groupInvitation.name)
          .where('sendUserId', isEqualTo: fromUserId)
          .where('receiveUserId', isEqualTo: toUserId)
          .where('groupId', isEqualTo: groupId)
          .where('status', isEqualTo: NotificationStatus.pending.name)
          .get();
      final hasPending = snapshot.docs.isNotEmpty;
      debugPrint('Pending group invitation check result: $hasPending');
      return hasPending;
    } catch (e) {
      debugPrint('Error checking pending group invitation: $e');
      rethrow;
    }
  }

  @override
  Future<void> acceptNotification(String notificationId) async {
    debugPrint('Accepting notification: $notificationId');
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'status': NotificationStatus.accepted.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('Notification accepted successfully: $notificationId');
    } catch (e) {
      debugPrint('Error accepting notification: $e');
      rethrow;
    }
  }

  @override
  Future<void> rejectNotification(String notificationId) async {
    debugPrint('Rejecting notification: $notificationId');
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'status': NotificationStatus.rejected.name,
        'rejectionCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('Notification rejected successfully: $notificationId');
    } catch (e) {
      debugPrint('Error rejecting notification: $e');
      rethrow;
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    debugPrint('Marking notification as read: $notificationId');
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('Notification marked as read successfully: $notificationId');
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      rethrow;
    }
  }

  @override
  Stream<int> watchUnreadCount(String userId) {
    debugPrint('Watching unread count for user: $userId');
    return _firestore
        .collection('notifications')
        .where('receiveUserId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  @override
  Stream<int> watchUnreadCountByType(String userId, NotificationType type) {
    debugPrint('Watching unread count for user: $userId, type: ${type.name}');
    return _firestore
        .collection('notifications')
        .where('receiveUserId', isEqualTo: userId)
        .where('type', isEqualTo: type.name)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.size);
  }
}
