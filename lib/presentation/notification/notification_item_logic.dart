import '../../domain/entity/notification.dart' as domain;

/// 通知一覧アイテムの表示文言を決める純粋ロジック。
class NotificationItemLogic {
  const NotificationItemLogic._();

  /// 通知ステータスの表示ラベルを返す。
  static String statusLabel(domain.NotificationStatus status) {
    switch (status) {
      case domain.NotificationStatus.pending:
        return '未処理';
      case domain.NotificationStatus.accepted:
        return '承認済み';
      case domain.NotificationStatus.rejected:
        return '拒否済み';
      case domain.NotificationStatus.expired:
        return '承認不可';
    }
  }

  /// 通知本文の補足文を返す。
  static String subtitle(domain.Notification notification) {
    if (notification.type == domain.NotificationType.friend &&
        notification.status == domain.NotificationStatus.expired) {
      return '退会済みユーザーからのフレンド申請です';
    }

    final fromName =
        notification.sendUserDisplayName ?? notification.sendUserId;
    switch (notification.type) {
      case domain.NotificationType.friend:
        return '$fromNameさんからフレンド申請が届いています';
      case domain.NotificationType.groupInvitation:
        return '$fromNameさんからグループ招待が届いています';
      case domain.NotificationType.reaction:
        return '$fromNameさんがあなたの投稿にリアクションしました';
      case domain.NotificationType.comment:
        return '$fromNameさんがあなたの投稿にコメントしました';
    }
  }
}
