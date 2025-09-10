import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/utils/date_time_utils.dart';

void main() {
  group('DateTimeUtils Tests', () {
    group('getNow', () {
      test('現在時刻が返される', () {
        // Act
        final result = DateTimeUtils.getNow();
        final now = DateTime.now();

        // Assert
        // 1秒以内の差であることを確認
        final difference = now.difference(result).abs();
        expect(difference.inSeconds, lessThanOrEqualTo(1));
        expect(result.isUtc, isFalse); // ローカルタイムであることを確認
      });

      test('連続して呼び出しても適切な時刻が返される', () {
        // Act
        final time1 = DateTimeUtils.getNow();
        final time2 = DateTimeUtils.getNow();

        // Assert
        expect(time2.isAfter(time1) || time2.isAtSameMomentAs(time1), isTrue);
        // 差が1秒以内であることを確認
        expect(time2.difference(time1).inSeconds, lessThanOrEqualTo(1));
      });
    });

    group('formatDate', () {
      test('日付が正しい形式でフォーマットされる', () {
        // Arrange
        final testDate = DateTime(2024, 1, 15);

        // Act
        final result = DateTimeUtils.formatDate(testDate);

        // Assert
        expect(result, '2024年01月15日');
      });

      test('一桁の月日も0埋めされる', () {
        // Arrange
        final testDate = DateTime(2024, 1, 5);

        // Act
        final result = DateTimeUtils.formatDate(testDate);

        // Assert
        expect(result, '2024年01月05日');
      });

      test('12月31日も正しくフォーマットされる', () {
        // Arrange
        final testDate = DateTime(2023, 12, 31);

        // Act
        final result = DateTimeUtils.formatDate(testDate);

        // Assert
        expect(result, '2023年12月31日');
      });
    });

    group('formatTime', () {
      test('時刻が正しい形式でフォーマットされる', () {
        // Arrange
        final testTime = DateTime(2024, 1, 1, 14, 30);

        // Act
        final result = DateTimeUtils.formatTime(testTime);

        // Assert
        expect(result, '14:30');
      });

      test('午前0時も正しくフォーマットされる', () {
        // Arrange
        final testTime = DateTime(2024, 1, 1, 0, 0);

        // Act
        final result = DateTimeUtils.formatTime(testTime);

        // Assert
        expect(result, '00:00');
      });

      test('一桁の時分も0埋めされる', () {
        // Arrange
        final testTime = DateTime(2024, 1, 1, 9, 5);

        // Act
        final result = DateTimeUtils.formatTime(testTime);

        // Assert
        expect(result, '09:05');
      });

      test('23:59も正しくフォーマットされる', () {
        // Arrange
        final testTime = DateTime(2024, 1, 1, 23, 59);

        // Act
        final result = DateTimeUtils.formatTime(testTime);

        // Assert
        expect(result, '23:59');
      });
    });

    group('formatDateTime', () {
      test('日付と時刻が正しい形式でフォーマットされる', () {
        // Arrange
        final testDateTime = DateTime(2024, 1, 15, 14, 30);

        // Act
        final result = DateTimeUtils.formatDateTime(testDateTime);

        // Assert
        expect(result, '2024年01月15日 14:30');
      });

      test('年始の午前0時も正しくフォーマットされる', () {
        // Arrange
        final testDateTime = DateTime(2024, 1, 1, 0, 0);

        // Act
        final result = DateTimeUtils.formatDateTime(testDateTime);

        // Assert
        expect(result, '2024年01月01日 00:00');
      });

      test('年末の深夜も正しくフォーマットされる', () {
        // Arrange
        final testDateTime = DateTime(2023, 12, 31, 23, 59);

        // Act
        final result = DateTimeUtils.formatDateTime(testDateTime);

        // Assert
        expect(result, '2023年12月31日 23:59');
      });
    });

    group('isSameDay', () {
      test('同じ日の異なる時刻はtrueを返す', () {
        // Arrange
        final date1 = DateTime(2024, 1, 15, 9, 0);
        final date2 = DateTime(2024, 1, 15, 18, 30);

        // Act
        final result = DateTimeUtils.isSameDay(date1, date2);

        // Assert
        expect(result, isTrue);
      });

      test('同じ年月日の00:00と23:59はtrueを返す', () {
        // Arrange
        final date1 = DateTime(2024, 1, 15, 0, 0);
        final date2 = DateTime(2024, 1, 15, 23, 59);

        // Act
        final result = DateTimeUtils.isSameDay(date1, date2);

        // Assert
        expect(result, isTrue);
      });

      test('異なる日はfalseを返す', () {
        // Arrange
        final date1 = DateTime(2024, 1, 15, 12, 0);
        final date2 = DateTime(2024, 1, 16, 12, 0);

        // Act
        final result = DateTimeUtils.isSameDay(date1, date2);

        // Assert
        expect(result, isFalse);
      });

      test('異なる月はfalseを返す', () {
        // Arrange
        final date1 = DateTime(2024, 1, 15, 12, 0);
        final date2 = DateTime(2024, 2, 15, 12, 0);

        // Act
        final result = DateTimeUtils.isSameDay(date1, date2);

        // Assert
        expect(result, isFalse);
      });

      test('異なる年はfalseを返す', () {
        // Arrange
        final date1 = DateTime(2024, 1, 15, 12, 0);
        final date2 = DateTime(2025, 1, 15, 12, 0);

        // Act
        final result = DateTimeUtils.isSameDay(date1, date2);

        // Assert
        expect(result, isFalse);
      });

      test('完全に同じ日時はtrueを返す', () {
        // Arrange
        final date1 = DateTime(2024, 1, 15, 12, 30, 45);
        final date2 = DateTime(2024, 1, 15, 12, 30, 45);

        // Act
        final result = DateTimeUtils.isSameDay(date1, date2);

        // Assert
        expect(result, isTrue);
      });
    });

    group('isToday', () {
      test('今日の日付はtrueを返す', () {
        // Arrange
        final today = DateTimeUtils.getNow();

        // Act
        final result = DateTimeUtils.isToday(today);

        // Assert
        expect(result, isTrue);
      });

      test('今日の異なる時刻もtrueを返す', () {
        // Arrange
        final now = DateTimeUtils.getNow();
        final todayMorning = DateTime(now.year, now.month, now.day, 6, 0);
        final todayEvening = DateTime(now.year, now.month, now.day, 22, 0);

        // Act & Assert
        expect(DateTimeUtils.isToday(todayMorning), isTrue);
        expect(DateTimeUtils.isToday(todayEvening), isTrue);
      });

      test('昨日の日付はfalseを返す', () {
        // Arrange
        final yesterday =
            DateTimeUtils.getNow().subtract(const Duration(days: 1));

        // Act
        final result = DateTimeUtils.isToday(yesterday);

        // Assert
        expect(result, isFalse);
      });

      test('明日の日付はfalseを返す', () {
        // Arrange
        final tomorrow = DateTimeUtils.getNow().add(const Duration(days: 1));

        // Act
        final result = DateTimeUtils.isToday(tomorrow);

        // Assert
        expect(result, isFalse);
      });

      test('1年前の同じ日付はfalseを返す', () {
        // Arrange
        final oneYearAgo =
            DateTimeUtils.getNow().subtract(const Duration(days: 365));

        // Act
        final result = DateTimeUtils.isToday(oneYearAgo);

        // Assert
        expect(result, isFalse);
      });
    });

    group('境界値・特殊ケーステスト', () {
      test('うるう年の2月29日も正しく処理される', () {
        // Arrange
        final leapDay = DateTime(2024, 2, 29, 12, 0); // 2024年はうるう年

        // Act & Assert
        expect(DateTimeUtils.formatDate(leapDay), '2024年02月29日');
        expect(DateTimeUtils.formatTime(leapDay), '12:00');
        expect(DateTimeUtils.formatDateTime(leapDay), '2024年02月29日 12:00');
      });

      test('タイムゾーンの影響を受けない', () {
        // Arrange
        final utcTime = DateTime.utc(2024, 1, 15, 12, 0);
        final localTime = utcTime.toLocal();

        // Act
        final utcFormatted = DateTimeUtils.formatDate(utcTime);
        final localFormatted = DateTimeUtils.formatDate(localTime);

        // Assert
        // 日付部分は同じになる（時差があっても同じ日の場合）
        expect(utcFormatted, equals(localFormatted));
      });

      test('極端に古い日付も正しく処理される', () {
        // Arrange
        final oldDate = DateTime(1900, 1, 1, 0, 0);

        // Act & Assert
        expect(DateTimeUtils.formatDate(oldDate), '1900年01月01日');
        expect(DateTimeUtils.formatTime(oldDate), '00:00');
        expect(DateTimeUtils.formatDateTime(oldDate), '1900年01月01日 00:00');
      });

      test('極端に未来の日付も正しく処理される', () {
        // Arrange
        final futureDate = DateTime(9999, 12, 31, 23, 59);

        // Act & Assert
        expect(DateTimeUtils.formatDate(futureDate), '9999年12月31日');
        expect(DateTimeUtils.formatTime(futureDate), '23:59');
        expect(DateTimeUtils.formatDateTime(futureDate), '9999年12月31日 23:59');
      });
    });
  });
}
