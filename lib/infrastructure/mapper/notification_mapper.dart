import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lakiite/domain/entity/notification.dart';

/// Firestore の通知ドキュメントと domain の [Notification] を相互変換する mapper。
class NotificationMapper {
  const NotificationMapper._();

  /// Firestore のドキュメント ID とデータから [Notification] を生成する。
  static Notification fromFirestore({
    required String id,
    required Map<String, dynamic> data,
  }) {
    return Notification(
      id: id,
      type: NotificationType.values.firstWhere(
        (type) => type.name == data['type'] as String,
      ),
      sendUserId: data['sendUserId'] as String,
      receiveUserId: data['receiveUserId'] as String,
      sendUserDisplayName: data['sendUserDisplayName'] as String?,
      receiveUserDisplayName: data['receiveUserDisplayName'] as String?,
      status: NotificationStatus.values.firstWhere(
        (status) =>
            status.name ==
            (data['status'] as String? ?? NotificationStatus.pending.name),
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      rejectionCount: data['rejectionCount'] as int? ?? 0,
      isRead: data['isRead'] as bool? ?? false,
      groupId: data['groupId'] as String?,
      relatedItemId: data['relatedItemId'] as String?,
      interactionId: data['interactionId'] as String?,
    );
  }

  /// [Notification] を Firestore 保存用の Map に変換する。
  ///
  /// ドキュメント ID として扱う [Notification.id] は保存データに含めない。
  static Map<String, dynamic> toFirestore(Notification notification) {
    return {
      'type': notification.type.name,
      'sendUserId': notification.sendUserId,
      'receiveUserId': notification.receiveUserId,
      'sendUserDisplayName': notification.sendUserDisplayName,
      'receiveUserDisplayName': notification.receiveUserDisplayName,
      'status': notification.status.name,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'rejectionCount': notification.rejectionCount,
      'isRead': notification.isRead,
      if (notification.groupId != null) 'groupId': notification.groupId,
      if (notification.relatedItemId != null)
        'relatedItemId': notification.relatedItemId,
      if (notification.interactionId != null)
        'interactionId': notification.interactionId,
    };
  }
}
