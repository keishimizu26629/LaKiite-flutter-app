import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/domain/entity/schedule.dart';
import 'package:lakiite/presentation/calendar/widgets/calendar_page_view.dart';

void main() {
  testWidgets('月次セルは2件まで表示し残数からその日の予定一覧へ遷移する', (tester) async {
    final date = DateTime(2026, 5, 28);
    final schedules = [
      _schedule(
        id: 'all-day-old',
        title: '古い終日',
        date: date,
        isAllDay: true,
        createdAt: DateTime(2026, 5, 28, 8),
      ),
      _schedule(
        id: 'all-day-new',
        title: '新しい終日',
        date: date,
        isAllDay: true,
        createdAt: DateTime(2026, 5, 28, 9),
      ),
      _schedule(
        id: 'timed',
        title: '時間予定',
        date: date,
        startDateTime: DateTime(2026, 5, 28, 10),
        endDateTime: DateTime(2026, 5, 28, 11),
        createdAt: DateTime(2026, 5, 28, 7),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 180,
            height: 160,
            child: OptimizedDateCell(
              date: date,
              schedules: schedules,
              isToday: false,
              isWeekend: false,
              isSaturday: false,
              isCurrentMonth: true,
              isHoliday: false,
              holidayName: '',
              currentUserId: 'owner',
            ),
          ),
        ),
      ),
    );

    expect(find.text('古い終日'), findsOneWidget);
    expect(find.text('新しい終日'), findsOneWidget);
    expect(find.text('時間予定'), findsNothing);
    expect(find.text('+1'), findsOneWidget);

    final plusText = tester.widget<Text>(find.text('+1'));
    expect(plusText.style?.fontSize, 11.2);

    final cellRight = tester.getTopRight(find.byType(OptimizedDateCell)).dx;
    final plusRight = tester.getTopRight(find.text('+1')).dx;
    expect(cellRight - plusRight, lessThan(8));

    await tester.tap(find.text('+1'));
    await tester.pumpAndSettle();

    expect(find.text('予定一覧'), findsOneWidget);
    expect(find.text('古い終日'), findsOneWidget);
    expect(find.text('新しい終日'), findsOneWidget);
    expect(find.text('時間予定'), findsOneWidget);
    expect(find.text('10:00〜11:00'), findsOneWidget);
  });
}

Schedule _schedule({
  required String id,
  required String title,
  required DateTime date,
  required DateTime createdAt,
  bool isAllDay = false,
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
