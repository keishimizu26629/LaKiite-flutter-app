import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/domain/entity/notification.dart' as domain;
import 'package:lakiite/presentation/notification/notification_item_logic.dart';

void main() {
  group('NotificationItemLogic', () {
    test('通知ステータスの表示文言を返す', () {
      expect(
        NotificationItemLogic.statusLabel(domain.NotificationStatus.pending),
        '未処理',
      );
      expect(
        NotificationItemLogic.statusLabel(domain.NotificationStatus.accepted),
        '承認済み',
      );
      expect(
        NotificationItemLogic.statusLabel(domain.NotificationStatus.rejected),
        '拒否済み',
      );
      expect(
        NotificationItemLogic.statusLabel(domain.NotificationStatus.expired),
        '承認不可',
      );
    });

    test('期限切れの友達申請は退会済みユーザーとして説明する', () {
      final notification = domain.Notification(
        id: 'notification-id',
        type: domain.NotificationType.friend,
        sendUserId: 'deleted-user-id',
        receiveUserId: 'receiver-id',
        sendUserDisplayName: '削除前の名前',
        status: domain.NotificationStatus.expired,
        createdAt: DateTime(2026, 5, 22),
        updatedAt: DateTime(2026, 5, 22),
        isRead: true,
      );

      expect(
        NotificationItemLogic.subtitle(notification),
        '退会済みユーザーからのフレンド申請です',
      );
    });
  });
}
