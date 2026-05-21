import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification.freezed.dart';

/// アプリ内通知の種類。
///
/// 種類ごとに参照する補助 ID が異なる。グループ招待では [Notification.groupId]、
/// リアクションとコメントでは [Notification.relatedItemId] と
/// [Notification.interactionId] を使用する。
enum NotificationType {
  /// フレンド申請通知。
  friend,

  /// グループへの招待通知。
  groupInvitation,

  /// スケジュールへのリアクション通知。
  reaction,

  /// スケジュールへのコメント通知。
  comment,
}

/// ユーザー操作が必要な通知の処理状態。
enum NotificationStatus {
  /// 承認または拒否の操作待ち。
  pending,

  /// 承認済み。
  accepted,

  /// 拒否済み。
  rejected,
}

/// アプリ内でユーザーに届ける通知を表すドメインモデル。
///
/// Firestore の Timestamp や FieldValue などの保存形式は持たず、
/// domain では通知種別・状態・関連 ID を型付きの値として扱う。
@freezed
class Notification with _$Notification {
  const factory Notification({
    required String id,
    required NotificationType type,
    required String sendUserId,
    required String receiveUserId,
    String? sendUserDisplayName,
    String? receiveUserDisplayName,
    required NotificationStatus status,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(0) int rejectionCount,
    @Default(false) bool isRead,
    String? groupId,
    String? relatedItemId,
    String? interactionId,
  }) = _Notification;

  factory Notification.createCommentNotification({
    required String fromUserId,
    required String toUserId,
    required String relatedItemId,
    required String interactionId,
    String? fromUserDisplayName,
  }) {
    final now = DateTime.now();
    return Notification(
      id: '',
      type: NotificationType.comment,
      sendUserId: fromUserId,
      receiveUserId: toUserId,
      sendUserDisplayName: fromUserDisplayName,
      status: NotificationStatus.accepted,
      createdAt: now,
      updatedAt: now,
      relatedItemId: relatedItemId,
      interactionId: interactionId,
    );
  }

  factory Notification.createReactionNotification({
    required String fromUserId,
    required String toUserId,
    required String relatedItemId,
    required String interactionId,
    String? fromUserDisplayName,
  }) {
    final now = DateTime.now();
    return Notification(
      id: '',
      type: NotificationType.reaction,
      sendUserId: fromUserId,
      receiveUserId: toUserId,
      sendUserDisplayName: fromUserDisplayName,
      status: NotificationStatus.accepted,
      createdAt: now,
      updatedAt: now,
      relatedItemId: relatedItemId,
      interactionId: interactionId,
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
      id: '',
      type: NotificationType.groupInvitation,
      sendUserId: fromUserId,
      receiveUserId: toUserId,
      sendUserDisplayName: fromUserDisplayName,
      receiveUserDisplayName: toUserDisplayName,
      status: NotificationStatus.pending,
      createdAt: now,
      updatedAt: now,
      groupId: groupId,
    );
  }

  factory Notification.createFriendRequest({
    required String fromUserId,
    required String toUserId,
    String? fromUserDisplayName,
    String? toUserDisplayName,
  }) {
    final now = DateTime.now();
    return Notification(
      id: '',
      type: NotificationType.friend,
      sendUserId: fromUserId,
      receiveUserId: toUserId,
      sendUserDisplayName: fromUserDisplayName,
      receiveUserDisplayName: toUserDisplayName,
      status: NotificationStatus.pending,
      createdAt: now,
      updatedAt: now,
    );
  }
}
