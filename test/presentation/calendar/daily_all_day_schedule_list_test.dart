import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

    expect(find.text('終日予定'), findsOneWidget);
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
}

Schedule _schedule({
  required String id,
  required String title,
  required DateTime createdAt,
  required DateTime date,
}) {
  return Schedule(
    id: id,
    title: title,
    description: '',
    startDateTime: date,
    endDateTime: date,
    isAllDay: true,
    ownerId: 'owner',
    ownerDisplayName: 'Owner',
    sharedLists: const [],
    visibleTo: const ['owner'],
    createdAt: createdAt,
    updatedAt: createdAt,
  );
}
