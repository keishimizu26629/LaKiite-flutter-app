import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lakiite/domain/entity/notification.dart' as domain;
import 'package:lakiite/domain/entity/schedule_comment.dart';
import 'package:lakiite/presentation/calendar/schedule_detail_logic.dart';

void main() {
  group('ScheduleDetailLogic', () {
    test('コメントを作成日時の昇順へ並べる', () {
      final newer = _comment(
        id: 'newer',
        createdAt: DateTime(2026, 5, 1, 12),
      );
      final older = _comment(
        id: 'older',
        createdAt: DateTime(2026, 5, 1, 10),
      );

      expect(
        ScheduleDetailLogic.sortedComments([newer, older]).map((c) => c.id),
        ['older', 'newer'],
      );
    });

    test('現在ユーザーIDとコメント投稿者IDが一致する場合だけ自分のコメントになる', () {
      final comment = _comment(userId: 'user-1');

      expect(ScheduleDetailLogic.isMyComment('user-1', comment), isTrue);
      expect(ScheduleDetailLogic.isMyComment('user-2', comment), isFalse);
      expect(ScheduleDetailLogic.isMyComment(null, comment), isFalse);
    });

    test('コメント通知から対象interactionへ遷移した場合だけ対象コメントになる', () {
      final comment = _comment(id: 'comment-1');

      expect(
        ScheduleDetailLogic.isTargetComment(
          fromNotification: true,
          notificationType: domain.NotificationType.comment,
          interactionId: 'comment-1',
          comment: comment,
        ),
        isTrue,
      );
      expect(
        ScheduleDetailLogic.isTargetComment(
          fromNotification: true,
          notificationType: domain.NotificationType.reaction,
          interactionId: 'comment-1',
          comment: comment,
        ),
        isFalse,
      );
    });

    test('所有者本人の場合だけ関連通知を既読化できる', () {
      expect(
        ScheduleDetailLogic.canMarkRelatedNotificationsAsRead(
          scheduleOwnerId: 'owner-1',
          currentUserId: 'owner-1',
        ),
        isTrue,
      );
      expect(
        ScheduleDetailLogic.canMarkRelatedNotificationsAsRead(
          scheduleOwnerId: 'owner-1',
          currentUserId: 'user-2',
        ),
        isFalse,
      );
      expect(
        ScheduleDetailLogic.canMarkRelatedNotificationsAsRead(
          scheduleOwnerId: 'owner-1',
          currentUserId: null,
        ),
        isFalse,
      );
    });

    test('未読かつ同じ予定に紐づくリアクション・コメント通知だけ抽出する', () {
      final notifications = [
        _notification(
          id: 'reaction',
          type: domain.NotificationType.reaction,
          relatedItemId: 'schedule-1',
        ),
        _notification(
          id: 'comment',
          type: domain.NotificationType.comment,
          relatedItemId: 'schedule-1',
        ),
        _notification(
          id: 'read-comment',
          type: domain.NotificationType.comment,
          relatedItemId: 'schedule-1',
          isRead: true,
        ),
        _notification(
          id: 'other-schedule',
          type: domain.NotificationType.comment,
          relatedItemId: 'schedule-2',
        ),
        _notification(
          id: 'friend',
          type: domain.NotificationType.friend,
          relatedItemId: 'schedule-1',
        ),
      ];

      expect(
        ScheduleDetailLogic.unreadRelatedNotifications(
          notifications: notifications,
          scheduleId: 'schedule-1',
        ).map((n) => n.id),
        ['reaction', 'comment'],
      );
    });

    test('日時範囲は同日なら日付を1回だけ、別日なら両方の日付を表示する', () async {
      await initializeDateFormatting('ja_JP');

      expect(
        ScheduleDetailLogic.formatDateTimeRange(
          DateTime(2026, 5, 1, 10),
          DateTime(2026, 5, 1, 11, 30),
        ),
        contains('10:00 - 11:30'),
      );
      expect(
        ScheduleDetailLogic.formatDateTimeRange(
          DateTime(2026, 5, 1, 23),
          DateTime(2026, 5, 2, 1),
        ),
        contains('2026年5月2日'),
      );
    });
  });
}

ScheduleComment _comment({
  String id = 'comment-1',
  String userId = 'user-1',
  DateTime? createdAt,
}) {
  return ScheduleComment(
    id: id,
    userId: userId,
    content: 'コメント',
    createdAt: createdAt ?? DateTime(2026, 5, 1),
  );
}

domain.Notification _notification({
  required String id,
  required domain.NotificationType type,
  required String relatedItemId,
  bool isRead = false,
}) {
  return domain.Notification(
    id: id,
    type: type,
    sendUserId: 'sender',
    receiveUserId: 'receiver',
    status: domain.NotificationStatus.accepted,
    createdAt: DateTime(2026, 5, 1),
    updatedAt: DateTime(2026, 5, 1),
    isRead: isRead,
    relatedItemId: relatedItemId,
  );
}
