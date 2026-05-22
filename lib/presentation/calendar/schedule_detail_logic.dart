import 'package:intl/intl.dart';
import 'package:lakiite/domain/entity/notification.dart' as domain;
import 'package:lakiite/domain/entity/schedule_comment.dart';

/// 予定詳細画面で使う表示判定と抽出処理を担う純粋ロジック。
///
/// Widgetは描画とユーザー操作に集中し、コメント・通知・日時表示の判断をここへ集約する。
class ScheduleDetailLogic {
  const ScheduleDetailLogic._();

  /// コメントを作成日時の昇順で返す。
  static List<ScheduleComment> sortedComments(
    List<ScheduleComment> comments,
  ) {
    return [...comments]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  /// コメントが現在ユーザー本人のものかどうかを返す。
  static bool isMyComment(
    String? currentUserId,
    ScheduleComment comment,
  ) {
    return currentUserId != null && comment.userId == currentUserId;
  }

  /// 通知遷移時に強調表示する対象コメントかどうかを返す。
  static bool isTargetComment({
    required bool fromNotification,
    required domain.NotificationType? notificationType,
    required String? interactionId,
    required ScheduleComment comment,
  }) {
    return fromNotification &&
        notificationType == domain.NotificationType.comment &&
        interactionId == comment.id;
  }

  /// 関連通知を既読にできるユーザーかどうかを返す。
  static bool canMarkRelatedNotificationsAsRead({
    required String scheduleOwnerId,
    required String? currentUserId,
  }) {
    return currentUserId != null && scheduleOwnerId == currentUserId;
  }

  /// この予定に紐づく未読のリアクション・コメント通知だけを返す。
  static List<domain.Notification> unreadRelatedNotifications({
    required List<domain.Notification> notifications,
    required String scheduleId,
  }) {
    return notifications
        .where(
          (notification) =>
              !notification.isRead &&
              (notification.type == domain.NotificationType.reaction ||
                  notification.type == domain.NotificationType.comment) &&
              notification.relatedItemId == scheduleId,
        )
        .toList();
  }

  /// 予定の開始・終了日時を画面表示用の文字列に整形する。
  static String formatDateTimeRange(DateTime start, DateTime end) {
    final dateFormat = DateFormat('yyyy年M月d日（E）', 'ja_JP');
    final timeFormat = DateFormat('HH:mm', 'ja_JP');

    if (_isSameDay(start, end)) {
      return '${dateFormat.format(start)} ${timeFormat.format(start)} - ${timeFormat.format(end)}';
    }

    return '${dateFormat.format(start)} ${timeFormat.format(start)} - ${dateFormat.format(end)} ${timeFormat.format(end)}';
  }

  static bool _isSameDay(DateTime start, DateTime end) {
    return start.year == end.year &&
        start.month == end.month &&
        start.day == end.day;
  }
}
