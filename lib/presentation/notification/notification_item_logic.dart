import '../../domain/entity/notification.dart' as domain;

/// 通知一覧アイテムの表示文言を決める純粋ロジック。
class NotificationItemLogic {
  const NotificationItemLogic._();

  /// 通知ステータスの表示ラベルを返す。
  static String statusLabel(domain.NotificationStatus status) =>
      switch (status) {
        domain.NotificationStatus.pending => '未処理',
        domain.NotificationStatus.accepted => '承認済み',
        domain.NotificationStatus.rejected => '拒否済み',
        domain.NotificationStatus.expired => '承認不可',
      };

  /// 通知本文の補足文を返す。
  ///
  /// 退会済みユーザーからの友達申請は承認できないため、通常の申請文言と分けて表示する。
  static String subtitle(domain.Notification notification) {
    final fromName =
        notification.sendUserDisplayName ?? notification.sendUserId;
    return switch ((notification.type, notification.status)) {
      (domain.NotificationType.friend, domain.NotificationStatus.expired) =>
        '退会済みユーザーからのフレンド申請です',
      (domain.NotificationType.friend, _) => '$fromNameさんからフレンド申請が届いています',
      (domain.NotificationType.groupInvitation, _) =>
        '$fromNameさんからグループ招待が届いています',
      (domain.NotificationType.reaction, _) => '$fromNameさんがあなたの投稿にリアクションしました',
      (domain.NotificationType.comment, _) => '$fromNameさんがあなたの投稿にコメントしました',
    };
  }
}
