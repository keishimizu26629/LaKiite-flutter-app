import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/utils/date_formatter.dart';

void main() {
  group('DateFormatter Tests', () {
    late DateTime baseTime;

    setUp(() {
      // テスト用の基準時間（2024年1月1日 12:00:00）
      baseTime = DateTime(2024, 1, 1, 12, 0, 0);
    });

    group('formatRelativeTime - 正常ケース', () {
      test('1分未満は「たった今」と表示される', () {
        // Arrange
        final testCases = [
          baseTime, // 現在時刻と同じ
          baseTime.subtract(const Duration(seconds: 30)), // 30秒前
          baseTime.subtract(const Duration(seconds: 59)), // 59秒前
        ];

        // Act & Assert
        for (final testCase in testCases) {
          // DateTime.nowをモックできないため、差分を計算してテスト
          final now = DateTime.now();
          final targetTime = now.subtract(Duration(
            seconds: baseTime.difference(testCase).inSeconds,
          ));

          final result = DateFormatter.formatRelativeTime(targetTime);
          expect(result, 'たった今');
        }
      });

      test('1時間未満は「X分前」と表示される', () {
        // Arrange & Act & Assert
        final now = DateTime.now();

        // 1分前
        final oneMinuteAgo = now.subtract(const Duration(minutes: 1));
        expect(DateFormatter.formatRelativeTime(oneMinuteAgo), '1分前');

        // 30分前
        final thirtyMinutesAgo = now.subtract(const Duration(minutes: 30));
        expect(DateFormatter.formatRelativeTime(thirtyMinutesAgo), '30分前');

        // 59分前
        final fiftyNineMinutesAgo = now.subtract(const Duration(minutes: 59));
        expect(DateFormatter.formatRelativeTime(fiftyNineMinutesAgo), '59分前');
      });

      test('24時間未満は「X時間前」と表示される', () {
        // Arrange & Act & Assert
        final now = DateTime.now();

        // 1時間前
        final oneHourAgo = now.subtract(const Duration(hours: 1));
        expect(DateFormatter.formatRelativeTime(oneHourAgo), '1時間前');

        // 12時間前
        final twelveHoursAgo = now.subtract(const Duration(hours: 12));
        expect(DateFormatter.formatRelativeTime(twelveHoursAgo), '12時間前');

        // 23時間前
        final twentyThreeHoursAgo = now.subtract(const Duration(hours: 23));
        expect(DateFormatter.formatRelativeTime(twentyThreeHoursAgo), '23時間前');
      });

      test('30日未満は「X日前」と表示される', () {
        // Arrange & Act & Assert
        final now = DateTime.now();

        // 1日前
        final oneDayAgo = now.subtract(const Duration(days: 1));
        expect(DateFormatter.formatRelativeTime(oneDayAgo), '1日前');

        // 7日前
        final oneWeekAgo = now.subtract(const Duration(days: 7));
        expect(DateFormatter.formatRelativeTime(oneWeekAgo), '7日前');

        // 29日前
        final twentyNineDaysAgo = now.subtract(const Duration(days: 29));
        expect(DateFormatter.formatRelativeTime(twentyNineDaysAgo), '29日前');
      });

      test('1年未満は「Xヶ月前」と表示される', () {
        // Arrange & Act & Assert
        final now = DateTime.now();

        // 31日前（約1ヶ月）
        final oneMonthAgo = now.subtract(const Duration(days: 31));
        expect(DateFormatter.formatRelativeTime(oneMonthAgo), '1ヶ月前');

        // 90日前（約3ヶ月）
        final threeMonthsAgo = now.subtract(const Duration(days: 90));
        expect(DateFormatter.formatRelativeTime(threeMonthsAgo), '3ヶ月前');

        // 300日前（約10ヶ月）
        final tenMonthsAgo = now.subtract(const Duration(days: 300));
        expect(DateFormatter.formatRelativeTime(tenMonthsAgo), '10ヶ月前');
      });

      test('1年以上は「X年前」と表示される', () {
        // Arrange & Act & Assert
        final now = DateTime.now();

        // 366日前（約1年）
        final oneYearAgo = now.subtract(const Duration(days: 366));
        expect(DateFormatter.formatRelativeTime(oneYearAgo), '1年前');

        // 730日前（約2年）
        final twoYearsAgo = now.subtract(const Duration(days: 730));
        expect(DateFormatter.formatRelativeTime(twoYearsAgo), '2年前');

        // 1095日前（約3年）
        final threeYearsAgo = now.subtract(const Duration(days: 1095));
        expect(DateFormatter.formatRelativeTime(threeYearsAgo), '3年前');
      });
    });

    group('formatRelativeTime - 境界値テスト', () {
      test('ちょうど1分前は「1分前」と表示される', () {
        // Arrange
        final now = DateTime.now();
        final exactlyOneMinuteAgo = now.subtract(const Duration(minutes: 1));

        // Act
        final result = DateFormatter.formatRelativeTime(exactlyOneMinuteAgo);

        // Assert
        expect(result, '1分前');
      });

      test('ちょうど1時間前は「1時間前」と表示される', () {
        // Arrange
        final now = DateTime.now();
        final exactlyOneHourAgo = now.subtract(const Duration(hours: 1));

        // Act
        final result = DateFormatter.formatRelativeTime(exactlyOneHourAgo);

        // Assert
        expect(result, '1時間前');
      });

      test('ちょうど1日前は「1日前」と表示される', () {
        // Arrange
        final now = DateTime.now();
        final exactlyOneDayAgo = now.subtract(const Duration(days: 1));

        // Act
        final result = DateFormatter.formatRelativeTime(exactlyOneDayAgo);

        // Assert
        expect(result, '1日前');
      });

      test('ちょうど30日前は「1ヶ月前」と表示される', () {
        // Arrange
        final now = DateTime.now();
        final exactlyThirtyDaysAgo = now.subtract(const Duration(days: 30));

        // Act
        final result = DateFormatter.formatRelativeTime(exactlyThirtyDaysAgo);

        // Assert
        expect(result, '1ヶ月前');
      });
    });

    group('formatRelativeTime - エラーケース・特殊ケース', () {
      test('未来の日付は「たった今」と表示される', () {
        // Arrange
        final now = DateTime.now();
        final futureTime = now.add(const Duration(hours: 1));

        // Act
        final result = DateFormatter.formatRelativeTime(futureTime);

        // Assert
        expect(result, 'たった今');
      });

      test('UTCとローカルタイムの混在でも正常に動作する', () {
        // Arrange
        final nowUtc = DateTime.now().toUtc();
        final oneHourAgoUtc = nowUtc.subtract(const Duration(hours: 1));

        // Act
        final result = DateFormatter.formatRelativeTime(oneHourAgoUtc);

        // Assert
        // UTCからローカルタイムに変換されるため、約1時間前になるはず
        expect(result, contains('時間前'));
      });

      test('非常に古い日付（100年前）も正常に処理される', () {
        // Arrange
        final now = DateTime.now();
        final veryOldDate = now.subtract(const Duration(days: 36500)); // 約100年

        // Act
        final result = DateFormatter.formatRelativeTime(veryOldDate);

        // Assert
        expect(result, contains('年前'));
        // 100年前なので、大きな数値になる
        final yearsPart = int.tryParse(result.replaceAll('年前', ''));
        expect(yearsPart, greaterThanOrEqualTo(90));
      });
    });

    group('formatRelativeTime - パフォーマンステスト', () {
      test('大量の日付処理でも適切な時間で実行される', () {
        // Arrange
        final now = DateTime.now();
        final testDates = List.generate(
            1000, (index) => now.subtract(Duration(minutes: index)));

        // Act
        final stopwatch = Stopwatch()..start();
        for (final date in testDates) {
          DateFormatter.formatRelativeTime(date);
        }
        stopwatch.stop();

        // Assert
        // 1000件の処理が1秒以内に完了することを確認
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });
    });
  });
}
