import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/domain/value/schedule_month_range.dart';

void main() {
  group('ScheduleMonthRange', () {
    test('表示月の前月月初から翌々月月初直前までを取得範囲にする', () {
      final range = ScheduleMonthRange.forDisplayMonth(DateTime(2026, 3, 20));

      expect(range.startInclusive, DateTime(2026, 2, 1));
      expect(range.endExclusive, DateTime(2026, 5, 1));
    });

    test('Firestore のISO文字列として月範囲境界を表現する', () {
      final range = ScheduleMonthRange.forDisplayMonth(DateTime(2026, 1, 31));

      expect(range.startInclusiveIso, '2025-12-01T00:00:00.000');
      expect(range.endExclusiveIso, '2026-03-01T00:00:00.000');
    });
  });
}
