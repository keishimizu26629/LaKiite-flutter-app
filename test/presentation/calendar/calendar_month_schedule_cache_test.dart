import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/domain/entity/schedule.dart';
import 'package:lakiite/presentation/calendar/widgets/calendar_page_view.dart';

import '../../mock/providers/test_providers.dart';
import '../../utils/test_utils.dart';

void main() {
  group('calendar month schedule cache', () {
    setUp(() {
      TestProviders.reset();
    });

    tearDown(() {
      TestProviders.reset();
    });

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

    test('取得対象は表示月と前後1ヶ月の3ヶ月だけにする', () {
      final months = getCalendarSchedulePrefetchMonths(DateTime(2026, 5, 30));

      expect(months, [
        DateTime(2026, 4),
        DateTime(2026, 5),
        DateTime(2026, 6),
      ]);
    });

    test('月ページには表示月と前後1ヶ月のキャッシュを合成して渡す', () {
      final aprilSchedule = _schedule(
        id: 'april',
        title: '4月予定',
        startDateTime: DateTime(2026, 4, 30, 9),
        endDateTime: DateTime(2026, 4, 30, 10),
      );
      final maySchedule = _schedule(
        id: 'may',
        title: '5月予定',
        startDateTime: DateTime(2026, 5, 30, 9),
        endDateTime: DateTime(2026, 5, 30, 10),
      );
      final juneSchedule = _schedule(
        id: 'june',
        title: '6月予定',
        startDateTime: DateTime(2026, 6, 1, 9),
        endDateTime: DateTime(2026, 6, 1, 10),
      );

      final schedules = getCalendarPageSchedules(
        userId: 'user-1',
        visibleMonth: DateTime(2026, 5),
        scheduleMemoryCache: {
          'user-1:2026-04': [aprilSchedule],
          'user-1:2026-05': [maySchedule],
          'user-1:2026-06': [juneSchedule],
          'user-1:2026-07': [
            _schedule(
              id: 'july',
              title: '7月予定',
              startDateTime: DateTime(2026, 7, 1, 9),
              endDateTime: DateTime(2026, 7, 1, 10),
            ),
          ],
        },
      );

      expect(schedules, [aprilSchedule, maySchedule, juneSchedule]);
    });

    testWidgets('月ページ本体は予定Providerを購読しない', (tester) async {
      final overrides = TestProviders.authenticated;
      final scheduleRepository = TestProviders.mockScheduleRepository;

      await tester.pumpWidget(
        TestUtils.createTestApp(
          overrides: overrides,
          child: Scaffold(
            body: CalendarPageContent(
              visiblePageDate: DateTime(2026, 5),
              monthKey: '2026-05',
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      expect(scheduleRepository.watchUserSchedulesForMonthCallCount, 0);
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
