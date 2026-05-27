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
