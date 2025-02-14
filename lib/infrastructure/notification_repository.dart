import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../domain/entity/notification.dart';
import '../domain/interfaces/i_notification_repository.dart';

/// 通知関連のFirestoreとのデータアクセスを管理するリポジトリクラス
class NotificationRepository implements INotificationRepository {
  final FirebaseFirestore _firestore;

  NotificationRepository() : _firestore = FirebaseFirestore.instance;

  /// 新しい通知を作成する
  ///
  /// [notification] 作成する通知オブジェクト
  @override
  Future<void> createNotification(Notification notification) async {
    // 作成する通知の内容をログ
    debugPrint('Creating notification: ${notification.toFirestore()}');
    try {
      final docRef = _firestore.collection('notifications').doc();
      await docRef.set(notification.toFirestore());
      // 作成成功をログ
      debugPrint('Notification created successfully with ID: ${docRef.id}');
    } catch (e) {
      debugPrint('Error creating notification: $e');
      rethrow;
    }
  }

  /// 既存の通知を更新する
  ///
  /// [notification] 更新する通知オブジェクト
  @override
  Future<void> updateNotification(Notification notification) async {
    // 更新する通知IDをログ
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

  /// 指定したIDの通知を取得する
  ///
  /// [notificationId] 取得する通知のID
  /// 通知が存在しない場合はnullを返す
  @override
  Future<Notification?> getNotification(String notificationId) async {
    debugPrint('Getting notification: $notificationId');
    try {
      final doc = await _firestore
          .collection('notifications')
          .doc(notificationId)
          .get();
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

  /// 指定したユーザーが受信した通知のストリームを監視する
  ///
  /// [userId] 監視対象のユーザーID
  /// createdAtの降順でソートされた通知リストのストリームを返す
  @override
  Stream<List<Notification>> watchReceivedNotifications(String userId) {
    debugPrint('Watching received notifications for user: $userId');
    return _firestore
        .collection('notifications')
        .where('receiveUserId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .orderBy('__name__', descending: true) // ドキュメントIDでの安定したソート
        .snapshots()
        .distinct()
        .map(_mapQuerySnapshotToNotifications);
  }

  /// 指定したユーザーが受信した特定タイプの通知のストリームを監視する
  ///
  /// [userId] 監視対象のユーザーID
  /// [type] 監視対象の通知タイプ
  /// createdAtの降順でソートされた通知リストのストリームを返す
  @override
  Stream<List<Notification>> watchReceivedNotificationsByType(
    String userId,
    NotificationType type,
  ) {
    debugPrint(
        'Watching received notifications for user: $userId, type: ${type.name}');
    return _firestore
        .collection('notifications')
        .where('receiveUserId', isEqualTo: userId)
        .where('type', isEqualTo: type.name)
        .orderBy('createdAt', descending: true)
        .orderBy('__name__', descending: true) // ドキュメントIDでの安定したソート
        .snapshots()
        .distinct()
        .map(_mapQuerySnapshotToNotifications);
  }

  /// 指定したユーザーが送信した通知のストリームを監視する
  ///
  /// [userId] 監視対象のユーザーID
  /// createdAtの降順でソートされた通知リストのストリームを返す
  @override
  Stream<List<Notification>> watchSentNotifications(String userId) {
    debugPrint('Watching sent notifications for user: $userId');
    return _firestore
        .collection('notifications')
        .where('sendUserId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .orderBy('__name__', descending: true) // ドキュメントIDでの安定したソート
        .snapshots()
        .distinct()
        .map(_mapQuerySnapshotToNotifications);
  }

  /// 指定したユーザーが送信した特定タイプの通知のストリームを監視する
  ///
  /// [userId] 監視対象のユーザーID
  /// [type] 監視対象の通知タイプ
  /// createdAtの降順でソートされた通知リストのストリームを返す
  @override
  Stream<List<Notification>> watchSentNotificationsByType(
    String userId,
    NotificationType type,
  ) {
    debugPrint(
        'Watching sent notifications for user: $userId, type: ${type.name}');
    return _firestore
        .collection('notifications')
        .where('sendUserId', isEqualTo: userId)
        .where('type', isEqualTo: type.name)
        .orderBy('createdAt', descending: true)
        .orderBy('__name__', descending: true) // ドキュメントIDでの安定したソート
        .snapshots()
        .distinct()
        .map(_mapQuerySnapshotToNotifications);
  }

  /// QuerySnapshotを通知オブジェクトのリストに変換する内部メソッド
  List<Notification> _mapQuerySnapshotToNotifications(QuerySnapshot snapshot) {
    final notifications = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return Notification.fromJson(data);
    }).toList();
    debugPrint('Received ${notifications.length} notifications');
    return notifications;
  }

  /// 保留中のフレンド申請が存在するか確認する
  ///
  /// [fromUserId] 送信者のユーザーID
  /// [toUserId] 受信者のユーザーID
  /// 保留中のフレンド申請が存在する場合はtrueを返す
  @override
  Future<bool> hasPendingFriendRequest(
      String fromUserId, String toUserId) async {
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

  /// 保留中のグループ招待が存在するか確認する
  ///
  /// [fromUserId] 送信者のユーザーID
  /// [toUserId] 受信者のユーザーID
  /// [groupId] グループID
  /// 保留中のグループ招待が存在する場合はtrueを返す
  @override
  Future<bool> hasPendingGroupInvitation(
    String fromUserId,
    String toUserId,
    String groupId,
  ) async {
    debugPrint(
        'Checking pending group invitation from $fromUserId to $toUserId for group $groupId');
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('type', isEqualTo: NotificationType.groupInvitation.name)
          .where('groupId', isEqualTo: groupId)
          .where('status', isEqualTo: NotificationStatus.pending.name)
          .where('receiveUserId', isEqualTo: toUserId)
          .where('sendUserId', isEqualTo: fromUserId)
          .get();
      final hasPending = snapshot.docs.isNotEmpty;
      debugPrint('Pending group invitation check result: $hasPending');
      return hasPending;
    } catch (e) {
      debugPrint('Error checking pending group invitation: $e');
      rethrow;
    }
  }

  /// 通知を承認する
  ///
  /// [notificationId] 承認する通知のID
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

  /// 通知を拒否する
  ///
  /// [notificationId] 拒否する通知のID
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

  /// 通知を既読にする
  ///
  /// [notificationId] 既読にする通知のID
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

  /// 指定したユーザーの未読通知数のストリームを監視する
  ///
  /// [userId] 監視対象のユーザーID
  /// 未読通知数のストリームを返す
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

  /// 指定したユーザーの特定タイプの未読通知数のストリームを監視する
  ///
  /// [userId] 監視対象のユーザーID
  /// [type] 監視対象の通知タイプ
  /// 未読通知数のストリームを返す
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

  /// 指定したグループに対する保留中の招待を持つユーザーIDのリストを取得する
  ///
  /// [groupId] グループID
  /// [friendIds] 確認対象のフレンドIDリスト
  /// 保留中の招待を持つユーザーIDのリストを返す
  Future<List<String>> getPendingGroupInvitations(
      String groupId, List<String> friendIds) async {
    debugPrint(
        'Getting pending group invitations for group: $groupId and friends: $friendIds');
    if (friendIds.isEmpty) {
      return [];
    }
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('type', isEqualTo: NotificationType.groupInvitation.name)
          .where('groupId', isEqualTo: groupId)
          .where('status', isEqualTo: NotificationStatus.pending.name)
          .where('receiveUserId', whereIn: friendIds)
          .get();

      return snapshot.docs
          .map((doc) =>
              (doc.data() as Map<String, dynamic>)['receiveUserId'] as String)
          .toList();
    } catch (e) {
      debugPrint('Error getting pending group invitations: $e');
      rethrow;
    }
  }

  /// 指定したグループに対する保留中の招待を持つユーザーIDのリストのストリームを監視する
  ///
  /// [groupId] グループID
  /// [friendIds] 監視対象のフレンドIDリスト
  /// 保留中の招待を持つユーザーIDのリストのストリームを返す
  Stream<List<String>> watchPendingGroupInvitations(
      String groupId, List<String> friendIds) {
    debugPrint(
        'Watching pending group invitations for group: $groupId and friends: $friendIds');
    if (friendIds.isEmpty) {
      return Stream.value([]);
    }

    return _firestore
        .collection('notifications')
        .where('type', isEqualTo: NotificationType.groupInvitation.name)
        .where('groupId', isEqualTo: groupId)
        .where('status', isEqualTo: NotificationStatus.pending.name)
        .where('receiveUserId', whereIn: friendIds)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                (doc.data() as Map<String, dynamic>)['receiveUserId'] as String)
            .toList());
  }
}
