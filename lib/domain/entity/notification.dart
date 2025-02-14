import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  friend,
  groupInvitation,
}

enum NotificationStatus {
  pending,
  accepted,
  rejected,
}

class Notification {
  final String id;
  final NotificationType type;
  final String sendUserId;
  final String receiveUserId;
  final String? sendUserDisplayName;
  final String? receiveUserDisplayName;
  final NotificationStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int rejectionCount;
  final bool isRead;
  final String? groupId; // グループ招待の場合に使用

  const Notification({
    required this.id,
    required this.type,
    required this.sendUserId,
    required this.receiveUserId,
    this.sendUserDisplayName,
    this.receiveUserDisplayName,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.rejectionCount = 0,
    this.isRead = false,
    this.groupId,
  });

  factory Notification.createFriendRequest({
    required String fromUserId,
    required String toUserId,
    String? fromUserDisplayName,
    String? toUserDisplayName,
  }) {
    final now = DateTime.now();
    return Notification(
      id: '', // Firestoreで自動生成
      type: NotificationType.friend,
      sendUserId: fromUserId,
      receiveUserId: toUserId,
      sendUserDisplayName: fromUserDisplayName,
      receiveUserDisplayName: toUserDisplayName,
      status: NotificationStatus.pending,
      createdAt: now,
      updatedAt: now,
      rejectionCount: 0,
      isRead: false,
    );
  }

  factory Notification.createGroupInvitation({
    required String fromUserId,
    required String toUserId,
    required String groupId,
    String? fromUserDisplayName,
    String? toUserDisplayName,
  }) {
    final now = DateTime.now();
    return Notification(
      id: '', // Firestoreで自動生成
      type: NotificationType.groupInvitation,
      sendUserId: fromUserId,
      receiveUserId: toUserId,
      sendUserDisplayName: fromUserDisplayName,
      receiveUserDisplayName: toUserDisplayName,
      status: NotificationStatus.pending,
      createdAt: now,
      updatedAt: now,
      rejectionCount: 0,
      isRead: false,
      groupId: groupId,
    );
  }

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'] as String,
      type: NotificationType.values.firstWhere(
        (e) => e.name == (json['type'] as String),
      ),
      sendUserId: json['sendUserId'] as String,
      receiveUserId: json['receiveUserId'] as String,
      sendUserDisplayName: json['sendUserDisplayName'] as String?,
      receiveUserDisplayName: json['receiveUserDisplayName'] as String?,
      status: NotificationStatus.values.firstWhere(
        (e) => e.name == (json['status'] as String? ?? NotificationStatus.pending.name),
      ),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
      rejectionCount: json['rejectionCount'] as int? ?? 0,
      isRead: json['isRead'] as bool? ?? false,
      groupId: json['groupId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'sendUserId': sendUserId,
        'receiveUserId': receiveUserId,
        'sendUserDisplayName': sendUserDisplayName,
        'receiveUserDisplayName': receiveUserDisplayName,
        'status': status.name,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'rejectionCount': rejectionCount,
        'isRead': isRead,
        if (groupId != null) 'groupId': groupId,
      };

  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json.remove('id'); // idはドキュメントIDとして使用するため、データから除外
    return {
      ...json,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Notification &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type &&
          sendUserId == other.sendUserId &&
          receiveUserId == other.receiveUserId &&
          status == other.status &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          rejectionCount == other.rejectionCount &&
          isRead == other.isRead &&
          groupId == other.groupId;

  @override
  int get hashCode =>
      id.hashCode ^
      type.hashCode ^
      sendUserId.hashCode ^
      receiveUserId.hashCode ^
      status.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode ^
      rejectionCount.hashCode ^
      isRead.hashCode ^
      (groupId?.hashCode ?? 0);

  @override
  String toString() =>
      'Notification(id: $id, type: $type, sendUserId: $sendUserId, receiveUserId: $receiveUserId, status: $status, createdAt: $createdAt, updatedAt: $updatedAt, rejectionCount: $rejectionCount, isRead: $isRead, groupId: $groupId)';
}
