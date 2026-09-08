import '../entity/notification.dart';

abstract class INotificationRepository {
  /// 通知を作成
  Future<void> createNotification(Notification notification);

  /// 通知を更新
  Future<void> updateNotification(Notification notification);

  /// 通知を取得
  Future<Notification?> getNotification(String notificationId);

  /// ユーザーの受信した通知を取得（全種類）
  Stream<List<Notification>> watchReceivedNotifications(String userId);

  /// ユーザーの受信した特定タイプの通知を取得
  Stream<List<Notification>> watchReceivedNotificationsByType(
    String userId,
    NotificationType type,
  );

  /// ユーザーの送信した通知を取得（全種類）
  Stream<List<Notification>> watchSentNotifications(String userId);

  /// ユーザーの送信した特定タイプの通知を取得
  Stream<List<Notification>> watchSentNotificationsByType(
    String userId,
    NotificationType type,
  );

  /// 2人のユーザー間の保留中のフレンド申請を確認
  Future<bool> hasPendingFriendRequest(String fromUserId, String toUserId);

  /// ユーザーとグループ間の保留中のグループ招待を確認
  Future<bool> hasPendingGroupInvitation(
    String fromUserId,
    String toUserId,
    String groupId,
  );

  /// pending の通知を原子的に承認する。
  ///
  /// 実際に pending から accepted へ遷移した場合だけ true を返す。
  Future<bool> acceptNotification(String notificationId);

  /// 通知を拒否
  Future<void> rejectNotification(String notificationId);

  /// 通知を期限切れにする
  Future<void> expireNotification(String notificationId);

  /// 通知を既読にする
  Future<void> markAsRead(String notificationId);

  /// 未読の通知数を取得
  Stream<int> watchUnreadCount(String userId);

  /// タイプ別の未読通知数を取得
  Stream<int> watchUnreadCountByType(String userId, NotificationType type);
}
