import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lakiite/domain/entity/notification.dart' as domain;
import 'package:lakiite/domain/entity/schedule_comment.dart';
import 'package:lakiite/domain/entity/user.dart';
import 'package:lakiite/domain/value/user_id.dart';
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

    test('コメント編集はtrim後に空でない場合だけ送信できる', () {
      expect(ScheduleDetailLogic.canSubmitComment('コメント'), isTrue);
      expect(ScheduleDetailLogic.canSubmitComment('  コメント  '), isTrue);
      expect(ScheduleDetailLogic.canSubmitComment(''), isFalse);
      expect(ScheduleDetailLogic.canSubmitComment('   '), isFalse);
    });

    test('コメント更新エラー文言を既存表示へ変換する', () {
      expect(
        ScheduleDetailLogic.commentUpdateErrorMessage(
          Exception('permission-denied'),
        ),
        'コメント更新に失敗しました: 権限エラー - Firebaseルールによりアクセスが拒否されました',
      );
      expect(
        ScheduleDetailLogic.commentUpdateErrorMessage(Exception('content')),
        'コメント更新に失敗しました: フィールド名の不一致（contentフィールド）',
      );
      expect(
        ScheduleDetailLogic.commentUpdateErrorMessage(Exception('text')),
        'コメント更新に失敗しました: フィールド名の不一致（textフィールド）',
      );
      expect(
        ScheduleDetailLogic.commentUpdateErrorMessage(Exception('other')),
        'コメント更新に失敗しました',
      );
    });

    test('リアクション投稿者の取得結果から削除済みユーザーを除外する', () {
      final existingUser = _user(id: 'user-1', displayName: 'ユーザー1');

      expect(
        ScheduleDetailLogic.availableReactionUsers([
          existingUser,
          null,
        ]),
        [existingUser],
      );
    });

    test('コメント投稿者名がない場合は退会済みユーザーとして表示する', () {
      expect(
        ScheduleDetailLogic.commentAuthorDisplayName(
          _comment(userDisplayName: '投稿者'),
        ),
        '投稿者',
      );
      expect(
        ScheduleDetailLogic.commentAuthorDisplayName(
          _comment(userDisplayName: null),
        ),
        '退会済みユーザー',
      );
    });
  });
}

ScheduleComment _comment({
  String id = 'comment-1',
  String userId = 'user-1',
  String? userDisplayName,
  DateTime? createdAt,
}) {
  return ScheduleComment(
    id: id,
    userId: userId,
    content: 'コメント',
    createdAt: createdAt ?? DateTime(2026, 5, 1),
    userDisplayName: userDisplayName,
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

UserModel _user({
  required String id,
  required String displayName,
}) {
  return UserModel(
    publicProfile: PublicUserModel(
      id: id,
      displayName: displayName,
      searchId: UserId('USRTEST1'),
      iconUrl: null,
      shortBio: null,
    ),
    privateProfile: PrivateUserModel(
      id: id,
      name: displayName,
      friends: const [],
      groups: const [],
      lists: const [],
      createdAt: DateTime(2026, 5, 1),
    ),
  );
}
