import 'package:cloud_firestore/cloud_firestore.dart';

enum FriendRequestStatus {
  pending,
  accepted,
  rejected,
}

class FriendRequest {
  final String id;
  final String sendUserId;
  final String receiveUserId;
  final String? sendUserDisplayName;    // nullable に変更
  final String? receiveUserDisplayName; // nullable に変更
  final FriendRequestStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int rejectionCount;
  final bool isRead;

  const FriendRequest({
    required this.id,
    required this.sendUserId,
    required this.receiveUserId,
    this.sendUserDisplayName,           // required 削除
    this.receiveUserDisplayName,        // required 削除
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.rejectionCount = 0,
    this.isRead = false,
  });

  factory FriendRequest.create({
    required String fromUserId,
    required String toUserId,
    String? fromUserDisplayName,       // nullable に変更
    String? toUserDisplayName,         // nullable に変更
  }) {
    final now = DateTime.now();
    return FriendRequest(
      id: '', // Firestoreで自動生成
      sendUserId: fromUserId,
      receiveUserId: toUserId,
      sendUserDisplayName: fromUserDisplayName,
      receiveUserDisplayName: toUserDisplayName,
      status: FriendRequestStatus.pending,
      createdAt: now,
      updatedAt: now,
      rejectionCount: 0,
      isRead: false,
    );
  }

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      id: json['id'] as String,
      sendUserId: json['sendUserId'] as String,
      receiveUserId: json['receiveUserId'] as String,
      sendUserDisplayName: json['sendUserDisplayName'] as String?,    // nullable キャスト
      receiveUserDisplayName: json['receiveUserDisplayName'] as String?, // nullable キャスト
      status: FriendRequestStatus.values.firstWhere(
        (e) => e.name == (json['status'] as String? ?? FriendRequestStatus.pending.name),
      ),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
      rejectionCount: json['rejectionCount'] as int? ?? 0,
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sendUserId': sendUserId,
        'receiveUserId': receiveUserId,
        'sendUserDisplayName': sendUserDisplayName,
        'receiveUserDisplayName': receiveUserDisplayName,
        'status': status.name,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'rejectionCount': rejectionCount,
        'isRead': isRead,
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
      other is FriendRequest &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          sendUserId == other.sendUserId &&
          receiveUserId == other.receiveUserId &&
          status == other.status &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          rejectionCount == other.rejectionCount &&
          isRead == other.isRead;

  @override
  int get hashCode =>
      id.hashCode ^
      sendUserId.hashCode ^
      receiveUserId.hashCode ^
      status.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode ^
      rejectionCount.hashCode ^
      isRead.hashCode;

  @override
  String toString() =>
      'FriendRequest(id: $id, sendUserId: $sendUserId, receiveUserId: $receiveUserId, status: $status, createdAt: $createdAt, updatedAt: $updatedAt, rejectionCount: $rejectionCount, isRead: $isRead)';
}
