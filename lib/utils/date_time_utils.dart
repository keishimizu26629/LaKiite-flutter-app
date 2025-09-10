import 'package:intl/intl.dart';

/// 日付と時間に関するユーティリティクラス
class DateTimeUtils {
  /// 現在の日時をUTCからローカルタイムに変換して取得
  ///
  /// タイムゾーンの問題を解決するために、一度UTCに変換してからローカルタイムに戻す
  static DateTime getNow() {
    return DateTime.now().toUtc().toLocal();
  }

  /// 日付のフォーマット（年月日）
  static String formatDate(DateTime dateTime) {
    return DateFormat('yyyy年MM月dd日').format(dateTime);
  }

  /// 時間のフォーマット（時分）
  static String formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  /// 日付と時間のフォーマット（年月日 時分）
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy年MM月dd日 HH:mm').format(dateTime);
  }

  /// 2つの日付が同じ日かどうかを判定
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// 指定した日付が今日かどうかを判定
  static bool isToday(DateTime date) {
    final now = getNow();
    return isSameDay(date, now);
  }
}
