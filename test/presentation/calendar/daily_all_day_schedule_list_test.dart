import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lakiite/application/notification/notification_notifier.dart';
import 'package:lakiite/domain/entity/schedule.dart';
import 'package:lakiite/presentation/calendar/widgets/daily_schedule_content.dart';

void main() {
  testWidgets('終日予定はcreatedAt昇順で2件まで表示し残数を表示する', (tester) async {
    final baseDate = DateTime(2026, 5, 28);
    final schedules = [
      _schedule(
        id: 'late',
        title: '新しい予定',
        createdAt: DateTime(2026, 5, 28, 12),
        date: baseDate,
      ),
      _schedule(
        id: 'early',
        title: '古い予定',
        createdAt: DateTime(2026, 5, 28, 8),
        date: baseDate,
      ),
      _schedule(
        id: 'middle',
        title: '次の予定',
        createdAt: DateTime(2026, 5, 28, 10),
        date: baseDate,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DailyAllDayScheduleList(
            date: baseDate,
            schedules: schedules,
            allSchedules: schedules,
            currentUserId: 'owner',
          ),
        ),
      ),
    );

    expect(find.text('古い予定'), findsOneWidget);
    expect(find.text('次の予定'), findsOneWidget);
    expect(find.text('新しい予定'), findsNothing);
    expect(find.text('+1'), findsOneWidget);
    expect(find.text('終日'), findsNothing);

    final earlyTop = tester.getTopLeft(find.text('古い予定')).dy;
    final middleTop = tester.getTopLeft(find.text('次の予定')).dy;
    expect(earlyTop, lessThan(middleTop));

    final plusOneText = tester.widget<Text>(find.text('+1'));
    expect(plusOneText.style?.fontSize, 16.8);

    final listRight =
        tester.getTopRight(find.byType(DailyAllDayScheduleList)).dx;
    final plusOneRight = tester.getTopRight(find.text('+1')).dx;
    expect(listRight - plusOneRight, lessThan(20));

    await tester.tap(find.text('+1'));
    await tester.pumpAndSettle();

    expect(find.text('予定一覧'), findsOneWidget);
    expect(find.text('古い予定'), findsOneWidget);
    expect(find.text('次の予定'), findsOneWidget);
    expect(find.text('新しい予定'), findsOneWidget);
  });

  testWidgets('終日予定が2件の場合は内容分の高さだけ確保する', (tester) async {
    final baseDate = DateTime(2026, 5, 28);
    final schedules = [
      _schedule(
        id: 'first',
        title: '1件目',
        createdAt: DateTime(2026, 5, 28, 8),
        date: baseDate,
      ),
      _schedule(
        id: 'second',
        title: '2件目',
        createdAt: DateTime(2026, 5, 28, 9),
        date: baseDate,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DailyAllDayScheduleList(
            date: baseDate,
            schedules: schedules,
            allSchedules: schedules,
            currentUserId: 'owner',
          ),
        ),
      ),
    );

    expect(find.text('+1'), findsNothing);

    final firstTop = tester.getTopLeft(find.text('1件目')).dy;
    final secondTop = tester.getTopLeft(find.text('2件目')).dy;
    final listBottom =
        tester.getBottomLeft(find.byType(DailyAllDayScheduleList)).dy;

    expect(secondTop - firstTop, greaterThan(0));
    expect(listBottom - secondTop, lessThan(48));
  });

  testWidgets('時間指定予定が同じ時間に3件ある場合は2件まで表示し残数から予定一覧へ遷移する', (tester) async {
    final baseDate = DateTime(2026, 5, 28);
    final allDaySchedule = _schedule(
      id: 'all-day',
      title: '終日予定',
      createdAt: DateTime(2026, 5, 28, 7),
      date: baseDate,
    );
    final timedSchedules = [
      _schedule(
        id: 'timed-1',
        title: '時間予定1',
        createdAt: DateTime(2026, 5, 28, 8),
        date: baseDate,
        isAllDay: false,
        startDateTime: DateTime(2026, 5, 28, 9),
        endDateTime: DateTime(2026, 5, 28, 10),
      ),
      _schedule(
        id: 'timed-2',
        title: '時間予定2',
        createdAt: DateTime(2026, 5, 28, 9),
        date: baseDate,
        isAllDay: false,
        startDateTime: DateTime(2026, 5, 28, 9),
        endDateTime: DateTime(2026, 5, 28, 10),
      ),
      _schedule(
        id: 'timed-3',
        title: '時間予定3',
        createdAt: DateTime(2026, 5, 28, 10),
        date: baseDate,
        isAllDay: false,
        startDateTime: DateTime(2026, 5, 28, 9),
        endDateTime: DateTime(2026, 5, 28, 10),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [currentUserIdProvider.overrideWithValue('owner')],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DailyScheduleContent(
                date: baseDate,
                schedules: timedSchedules,
                allSchedules: [allDaySchedule, ...timedSchedules],
              ),
            ),
          ),
        ),
      ),
    );

    await tester.ensureVisible(find.text('+1'));
    await tester.pumpAndSettle();

    expect(find.text('時間予定1'), findsOneWidget);
    expect(find.text('時間予定2'), findsOneWidget);
    expect(find.text('時間予定3'), findsNothing);
    expect(find.text('+1'), findsOneWidget);

    await tester.tap(find.text('+1'));
    await tester.pumpAndSettle();

    expect(find.text('予定一覧'), findsOneWidget);
    expect(find.text('終日予定'), findsOneWidget);
    expect(find.text('時間予定1'), findsOneWidget);
    expect(find.text('時間予定2'), findsOneWidget);
    expect(find.text('時間予定3'), findsOneWidget);
    expect(find.text('09:00〜10:00'), findsNWidgets(3));

    final allDayTop = tester.getTopLeft(find.text('終日予定')).dy;
    final firstTimedTop = tester.getTopLeft(find.text('時間予定1')).dy;
    expect(allDayTop, lessThan(firstTimedTop));
  });
}

Schedule _schedule({
  required String id,
  required String title,
  required DateTime createdAt,
  required DateTime date,
  bool isAllDay = true,
  DateTime? startDateTime,
  DateTime? endDateTime,
}) {
  return Schedule(
    id: id,
    title: title,
    description: '',
    startDateTime: startDateTime ?? date,
    endDateTime: endDateTime ?? date,
    isAllDay: isAllDay,
    ownerId: 'owner',
    ownerDisplayName: 'Owner',
    sharedLists: const [],
    visibleTo: const ['owner'],
    createdAt: createdAt,
    updatedAt: createdAt,
  );
}
