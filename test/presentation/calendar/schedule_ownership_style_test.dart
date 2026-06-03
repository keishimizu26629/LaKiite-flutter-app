import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/domain/entity/display_list.dart';
import 'package:lakiite/domain/entity/schedule.dart';
import 'package:lakiite/presentation/calendar/widgets/schedule_ownership_style.dart';
import 'package:lakiite/presentation/list/display_list_palette.dart';

void main() {
  group('ScheduleOwnershipStyle', () {
    testWidgets('uses gray for the current user schedule', (tester) async {
      late ScheduleOwnershipStyle style;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              style = ScheduleOwnershipStyle.resolve(
                context,
                schedule: _schedule(ownerId: 'current-user'),
                currentUserId: 'current-user',
                displayLists: const [],
              );
              return const SizedBox();
            },
          ),
        ),
      );

      expect(style.borderColor, Colors.grey.withValues(alpha: 0.8));
    });

    testWidgets('uses display list color for a listed friend schedule',
        (tester) async {
      late ScheduleOwnershipStyle style;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              style = ScheduleOwnershipStyle.resolve(
                context,
                schedule: _schedule(ownerId: 'friend-1'),
                currentUserId: 'current-user',
                displayLists: [
                  _displayList(colorKey: 'teal', memberIds: ['friend-1']),
                ],
              );
              return const SizedBox();
            },
          ),
        ),
      );

      expect(
        style.borderColor,
        DisplayListPalette.colorForKey('teal').withValues(alpha: 0.8),
      );
    });

    testWidgets('uses primary color for an unlisted friend schedule',
        (tester) async {
      const primaryColor = Colors.deepOrange;
      late ScheduleOwnershipStyle style;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(primaryColor: primaryColor),
          home: Builder(
            builder: (context) {
              style = ScheduleOwnershipStyle.resolve(
                context,
                schedule: _schedule(ownerId: 'friend-2'),
                currentUserId: 'current-user',
                displayLists: [
                  _displayList(colorKey: 'teal', memberIds: ['friend-1']),
                ],
              );
              return const SizedBox();
            },
          ),
        ),
      );

      expect(style.borderColor, primaryColor.withValues(alpha: 0.8));
    });
  });
}

DisplayList _displayList({
  required String colorKey,
  required List<String> memberIds,
}) {
  final now = DateTime(2026, 6, 3);
  return DisplayList(
    id: 'display-list',
    name: '表示用リスト',
    ownerId: 'current-user',
    colorKey: colorKey,
    memberIds: memberIds,
    createdAt: now,
    updatedAt: now,
  );
}

Schedule _schedule({required String ownerId}) {
  final now = DateTime(2026, 6, 3, 10);
  return Schedule(
    id: 'schedule',
    title: '予定',
    description: '',
    startDateTime: now,
    endDateTime: now.add(const Duration(hours: 1)),
    ownerId: ownerId,
    ownerDisplayName: 'Owner',
    sharedLists: const [],
    visibleTo: const [],
    createdAt: now,
    updatedAt: now,
  );
}
