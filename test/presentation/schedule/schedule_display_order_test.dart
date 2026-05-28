import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/domain/entity/schedule.dart';
import 'package:lakiite/presentation/schedule/schedule_display_order.dart';

void main() {
  test('日別表示は終日をcreatedAt昇順、時間指定を開始時刻昇順で並べる', () {
    final date = DateTime(2026, 5, 28);
    final schedules = [
      _schedule(
        id: 'timed-late',
        title: '11時予定',
        startDateTime: DateTime(2026, 5, 28, 11),
        endDateTime: DateTime(2026, 5, 28, 12),
        createdAt: DateTime(2026, 5, 28, 7),
      ),
      _schedule(
        id: 'all-day-new',
        title: '新しい終日',
        startDateTime: date,
        endDateTime: date,
        isAllDay: true,
        createdAt: DateTime(2026, 5, 28, 10),
      ),
      _schedule(
        id: 'timed-early',
        title: '9時予定',
        startDateTime: DateTime(2026, 5, 28, 9),
        endDateTime: DateTime(2026, 5, 28, 10),
        createdAt: DateTime(2026, 5, 28, 11),
      ),
      _schedule(
        id: 'all-day-old',
        title: '古い終日',
        startDateTime: date,
        endDateTime: date,
        isAllDay: true,
        createdAt: DateTime(2026, 5, 28, 8),
      ),
    ];

    final sorted = ScheduleDisplayOrder.sortedWithinDay(schedules);

    expect(
      sorted.map((schedule) => schedule.id),
      ['all-day-old', 'all-day-new', 'timed-early', 'timed-late'],
    );
  });

  test('タイムラインは日付順を維持し同日内だけ日別表示順に並べる', () {
    final schedules = [
      _schedule(
        id: 'tomorrow-all-day',
        title: '明日の終日',
        startDateTime: DateTime(2026, 5, 29),
        endDateTime: DateTime(2026, 5, 29),
        isAllDay: true,
        createdAt: DateTime(2026, 5, 28, 8),
      ),
      _schedule(
        id: 'today-timed',
        title: '今日の時間予定',
        startDateTime: DateTime(2026, 5, 28, 9),
        endDateTime: DateTime(2026, 5, 28, 10),
        createdAt: DateTime(2026, 5, 28, 12),
      ),
      _schedule(
        id: 'today-all-day',
        title: '今日の終日',
        startDateTime: DateTime(2026, 5, 28),
        endDateTime: DateTime(2026, 5, 28),
        isAllDay: true,
        createdAt: DateTime(2026, 5, 28, 11),
      ),
    ];

    final sorted = ScheduleDisplayOrder.sortedTimeline(schedules);

    expect(
      sorted.map((schedule) => schedule.id),
      ['today-all-day', 'today-timed', 'tomorrow-all-day'],
    );
  });
}

Schedule _schedule({
  required String id,
  required String title,
  required DateTime startDateTime,
  required DateTime endDateTime,
  required DateTime createdAt,
  bool isAllDay = false,
}) {
  return Schedule(
    id: id,
    title: title,
    description: '',
    startDateTime: startDateTime,
    endDateTime: endDateTime,
    isAllDay: isAllDay,
    ownerId: 'owner',
    ownerDisplayName: 'Owner',
    sharedLists: const [],
    visibleTo: const ['owner'],
    createdAt: createdAt,
    updatedAt: createdAt,
  );
}
