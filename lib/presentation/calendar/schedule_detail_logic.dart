import 'package:intl/intl.dart';
import 'package:lakiite/domain/entity/notification.dart' as domain;
import 'package:lakiite/domain/entity/schedule_comment.dart';
import 'package:lakiite/domain/entity/user.dart';
import 'package:lakiite/presentation/user_display_text.dart';

/// 予定詳細画面で使う表示判定と抽出処理を担う純粋ロジック。
///
/// Widgetは描画とユーザー操作に集中し、コメント・通知・日時表示の判断をここへ集約する。
class ScheduleDetailLogic {
  const ScheduleDetailLogic._();

  /// コメントを作成日時の昇順で返す。
  static List<ScheduleComment> sortedComments(List<ScheduleComment> comments) {
    return [...comments]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  /// コメントが現在ユーザー本人のものかどうかを返す。
  static bool isMyComment(String? currentUserId, ScheduleComment comment) {
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
  static String formatDateTimeRange(
    DateTime start,
    DateTime end, {
    bool isAllDay = false,
  }) {
    final dateFormat = DateFormat('yyyy年M月d日（E）', 'ja_JP');
    final timeFormat = DateFormat('HH:mm', 'ja_JP');

    if (isAllDay) {
      if (_isSameDay(start, end)) {
        return '${dateFormat.format(start)} 終日（時間未定など）';
      }

      return '${dateFormat.format(start)} - ${dateFormat.format(end)} 終日（時間未定など）';
    }

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

  /// コメント編集で送信可能な入力かどうかを返す。
  static bool canSubmitComment(String content) {
    return content.trim().isNotEmpty;
  }

  /// コメント更新エラーを画面表示用の文言へ変換する。
  static String commentUpdateErrorMessage(Object error) {
    var errorMsg = 'コメント更新に失敗しました';
    final errorText = error.toString();

    if (errorText.contains('permission-denied')) {
      errorMsg += ': 権限エラー - Firebaseルールによりアクセスが拒否されました';
    } else if (errorText.contains('content')) {
      errorMsg += ': フィールド名の不一致（contentフィールド）';
    } else if (errorText.contains('text')) {
      errorMsg += ': フィールド名の不一致（textフィールド）';
    }

    return errorMsg;
  }

  /// リアクションユーザー取得結果から、削除済みなどで取得できないユーザーを除外する。
  static List<PublicUserModel> availableReactionUsers(
    List<PublicUserModel?> users,
  ) {
    return users.whereType<PublicUserModel>().toList();
  }

  /// コメント投稿者名を表示用に返す。
  static String commentAuthorDisplayName(ScheduleComment comment) {
    return comment.userDisplayName ?? retiredUserDisplayName;
  }
}
