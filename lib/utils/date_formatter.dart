import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'logger.dart';

/// 日付を相対的な時間（何分前、何時間前など）の形式で表示するためのユーティリティクラス
class DateFormatter {
  /// 日付を相対的な時間形式で返す
  ///
  /// [date] 対象の日時
  ///
  /// 以下のフォーマットで返します：
  /// - 1分未満: 「たった今」
  /// - 1時間未満: 「X分前」
  /// - 24時間未満: 「X時間前」
  /// - 30日未満: 「X日前」
  /// - 1年未満: 「Xヶ月前」
  /// - 1年以上: 「X年前」
  static String formatRelativeTime(DateTime date) {
    try {
      final now = DateTime.now();

      // デバッグ情報（テスト時には出力を制限）
      // テスト時の大量ログを防ぐため一時的にコメントアウト
      // if (kDebugMode && !_isInTest()) {
      //   AppLogger.debug('処理対象の日付: $date');
      //   AppLogger.debug('現在の日付: $now');
      //   AppLogger.debug('差: ${now.difference(date).inSeconds}秒');
      // }

      // UTCとローカルタイムの調整（必要に応じて）
      DateTime adjustedDate = date;
      if (date.isUtc && !now.isUtc) {
        adjustedDate = date.toLocal();
      }

      final difference = now.difference(adjustedDate);

      // エラーケース: 未来の日付 (タイムゾーンの問題やサーバー時間のずれの可能性)
      if (difference.isNegative) {
        // 将来の日付の場合はデフォルトで「たった今」と表示
        return 'たった今';
      }

      if (difference.inMinutes < 1) {
        return 'たった今';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}分前';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}時間前';
      } else if (difference.inDays < 30) {
        return '${difference.inDays}日前';
      } else if (difference.inDays < 365) {
        // 月数を概算で計算（30日で割る）
        final months = (difference.inDays / 30).floor();
        return '$monthsヶ月前';
      } else {
        // 年数を計算（365日で割る）
        final years = (difference.inDays / 365).floor();
        return '$years年前';
      }
    } catch (e) {
      // 例外発生時は年月日で表示
      if (kDebugMode) {
        AppLogger.error('DateFormatter.formatRelativeTime エラー: $e');
      }
      try {
        final formatter = DateFormat('yyyy/MM/dd');
        return formatter.format(date);
      } catch (_) {
        return '不明な時間';
      }
    }
  }
}
