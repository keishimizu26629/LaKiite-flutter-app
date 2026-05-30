import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/domain/value/schedule_month_range.dart';

void main() {
  group('ScheduleMonthRange', () {
    test('表示月の月初から翌月月初直前までを取得範囲にする', () {
      final range = ScheduleMonthRange.forDisplayMonth(DateTime(2026, 3, 20));

      expect(range.startInclusive, DateTime(2026, 3, 1));
      expect(range.endExclusive, DateTime(2026, 4, 1));
    });

    test('Firestore のISO文字列として月範囲境界を表現する', () {
      final range = ScheduleMonthRange.forDisplayMonth(DateTime(2026, 1, 31));

      expect(range.startInclusiveIso, '2026-01-01T00:00:00.000');
      expect(range.endExclusiveIso, '2026-02-01T00:00:00.000');
    });
  });
}
