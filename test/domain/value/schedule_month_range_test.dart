import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/domain/entity/schedule.dart';
import 'package:lakiite/domain/value/schedule_month_range.dart';

void main() {
  group('ScheduleMonthRange', () {
    test('表示月の42日カレンダーグリッドだけを取得範囲にする', () {
      final range = ScheduleMonthRange.forDisplayMonth(DateTime(2026, 4, 20));

      expect(range.startInclusive, DateTime(2026, 3, 29));
      expect(range.endExclusive, DateTime(2026, 5, 10));
    });

    test('Firestore のISO文字列として42日グリッド境界を表現する', () {
      final range = ScheduleMonthRange.forDisplayMonth(DateTime(2026, 1, 31));

      expect(range.startInclusiveIso, '2025-12-28T00:00:00.000');
      expect(range.endExclusiveIso, '2026-02-08T00:00:00.000');
    });

    test('取得開始日より前に始まり表示範囲内で終わる予定も対象にする', () {
      final range = ScheduleMonthRange.forDisplayMonth(DateTime(2026, 4, 20));
      final schedule = _schedule(
        startDateTime: DateTime(2026, 3, 20),
        endDateTime: DateTime(2026, 3, 29),
      );

      expect(range.overlaps(schedule), isTrue);
    });

    test('42日グリッドより前に終わる予定は対象外にする', () {
      final range = ScheduleMonthRange.forDisplayMonth(DateTime(2026, 4, 20));
      final schedule = _schedule(
        startDateTime: DateTime(2026, 3, 20),
        endDateTime: DateTime(2026, 3, 28, 23, 59),
      );

      expect(range.overlaps(schedule), isFalse);
    });

    test('表示範囲終了日に始まる予定は対象外にする', () {
      final range = ScheduleMonthRange.forDisplayMonth(DateTime(2026, 4, 20));
      final schedule = _schedule(
        startDateTime: DateTime(2026, 5, 10),
        endDateTime: DateTime(2026, 5, 10, 1),
      );

      expect(range.overlaps(schedule), isFalse);
    });
  });
}

Schedule _schedule({
  required DateTime startDateTime,
  required DateTime endDateTime,
}) {
  return Schedule(
    id: 'schedule-id',
    title: '予定',
    description: '',
    startDateTime: startDateTime,
    endDateTime: endDateTime,
    ownerId: 'owner-id',
    ownerDisplayName: 'Owner',
    sharedLists: const [],
    visibleTo: const ['owner-id'],
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
}
