import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/domain/entity/schedule.dart';
import 'package:lakiite/presentation/calendar/widgets/calendar_page_view.dart';

void main() {
  group('calendar month schedule cache', () {
    test('先読み済みの月予定を月別キャッシュへ保存する', () {
      final schedules = [
        _schedule(
          id: 'schedule-1',
          title: '先読み予定',
          startDateTime: DateTime(2026, 5, 30, 9),
          endDateTime: DateTime(2026, 5, 30, 10),
        ),
      ];

      final cache = cacheCalendarMonthSchedules(
        currentCache: const {},
        cacheKey: 'user-1:2026-05',
        schedules: schedules,
      );

      expect(cache['user-1:2026-05'], same(schedules));
    });

    test('予定がまだ届いていない場合は既存キャッシュを維持する', () {
      final existingSchedules = [
        _schedule(
          id: 'schedule-1',
          title: '既存予定',
          startDateTime: DateTime(2026, 5, 30, 9),
          endDateTime: DateTime(2026, 5, 30, 10),
        ),
      ];
      final currentCache = {'user-1:2026-05': existingSchedules};

      final cache = cacheCalendarMonthSchedules(
        currentCache: currentCache,
        cacheKey: 'user-1:2026-05',
        schedules: null,
      );

      expect(cache, same(currentCache));
    });
  });
}

Schedule _schedule({
  required String id,
  required String title,
  required DateTime startDateTime,
  required DateTime endDateTime,
}) {
  return Schedule(
    id: id,
    title: title,
    description: '',
    startDateTime: startDateTime,
    endDateTime: endDateTime,
    ownerId: 'user-1',
    ownerDisplayName: 'User 1',
    sharedLists: const [],
    visibleTo: const ['user-1'],
    createdAt: DateTime(2026, 5, 1),
    updatedAt: DateTime(2026, 5, 1),
  );
}
