import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/domain/entity/list.dart';
import 'package:lakiite/domain/entity/schedule.dart';
import 'package:lakiite/presentation/calendar/schedule_form_logic.dart';

void main() {
  group('ScheduleFormLogic', () {
    test('既存予定がある場合は初期日時に予定の日時を使う', () {
      final schedule = _schedule(
        startDateTime: DateTime(2026, 5, 1, 9, 30),
        endDateTime: DateTime(2026, 5, 1, 10, 45),
      );

      expect(
        ScheduleFormLogic.initialStartDate(
          schedule: schedule,
          initialDate: DateTime(2026, 6, 1),
          now: DateTime(2026, 7, 1, 12),
        ),
        DateTime(2026, 5, 1, 9, 30),
      );
      expect(
        ScheduleFormLogic.initialEndDate(
          schedule: schedule,
          initialDate: DateTime(2026, 6, 1),
          now: DateTime(2026, 7, 1, 12),
        ),
        DateTime(2026, 5, 1, 10, 45),
      );
    });

    test('新規作成で日付指定がある場合は指定日と現在時刻を組み合わせる', () {
      final now = DateTime(2026, 5, 23, 14, 15);
      final initialDate = DateTime(2026, 8, 10);

      expect(
        ScheduleFormLogic.initialStartDate(
          schedule: null,
          initialDate: initialDate,
          now: now,
        ),
        DateTime(2026, 8, 10, 14, 15),
      );
      expect(
        ScheduleFormLogic.initialEndDate(
          schedule: null,
          initialDate: initialDate,
          now: now,
        ),
        DateTime(2026, 8, 10, 15, 15),
      );
    });

    test('日付と時刻を保存用DateTimeへ組み合わせる', () {
      expect(
        ScheduleFormLogic.combineDateAndTime(
          DateTime(2026, 8, 10),
          const TimeOfDay(hour: 21, minute: 45),
        ),
        DateTime(2026, 8, 10, 21, 45),
      );
    });

    test('終了日時が開始日時より前の場合のみ不正な時間範囲になる', () {
      final startDate = DateTime(2026, 8, 10);
      final endDate = DateTime(2026, 8, 10);

      expect(
        ScheduleFormLogic.hasInvalidTimeRange(
          startDate: startDate,
          startTime: const TimeOfDay(hour: 10, minute: 0),
          endDate: endDate,
          endTime: const TimeOfDay(hour: 9, minute: 59),
        ),
        isTrue,
      );
      expect(
        ScheduleFormLogic.hasInvalidTimeRange(
          startDate: startDate,
          startTime: const TimeOfDay(hour: 10, minute: 0),
          endDate: endDate,
          endTime: const TimeOfDay(hour: 10, minute: 0),
        ),
        isFalse,
      );
    });

    test('編集対象の共有リストIDに一致するリストだけ初期選択する', () {
      final lists = [
        _list(id: 'list-1'),
        _list(id: 'list-2'),
        _list(id: 'list-3'),
      ];
      final schedule = _schedule(sharedLists: const ['list-1', 'list-3']);

      expect(
        ScheduleFormLogic.selectedListsForSchedule(
          schedule: schedule,
          lists: lists,
        ),
        [lists[0], lists[2]],
      );
    });

    test('保存用に空文字の場所だけnullへ正規化する', () {
      expect(ScheduleFormLogic.optionalLocation(''), isNull);
      expect(ScheduleFormLogic.optionalLocation('  '), '  ');
      expect(ScheduleFormLogic.optionalLocation('会議室'), '会議室');
    });

    test('タイトルと場所が入力されている場合だけ必須項目入力済みになる', () {
      expect(
        ScheduleFormLogic.hasRequiredScheduleFields(
          title: '予定',
          location: '未定',
        ),
        isTrue,
      );
      expect(
        ScheduleFormLogic.hasRequiredScheduleFields(
          title: '',
          location: '未定',
        ),
        isFalse,
      );
      expect(
        ScheduleFormLogic.hasRequiredScheduleFields(
          title: '   ',
          location: '未定',
        ),
        isFalse,
      );
      expect(
        ScheduleFormLogic.hasRequiredScheduleFields(
          title: '予定',
          location: '',
        ),
        isFalse,
      );
      expect(
        ScheduleFormLogic.hasRequiredScheduleFields(
          title: '予定',
          location: '   ',
        ),
        isFalse,
      );
    });
  });
}

Schedule _schedule({
  DateTime? startDateTime,
  DateTime? endDateTime,
  List<String> sharedLists = const [],
}) {
  return Schedule(
    id: 'schedule-1',
    title: '予定',
    description: '説明',
    startDateTime: startDateTime ?? DateTime(2026, 1, 1, 10),
    endDateTime: endDateTime ?? DateTime(2026, 1, 1, 11),
    ownerId: 'user-1',
    ownerDisplayName: 'User',
    sharedLists: sharedLists,
    visibleTo: const ['user-1'],
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

UserList _list({required String id}) {
  return UserList(
    id: id,
    listName: id,
    ownerId: 'user-1',
    memberIds: const ['user-1'],
    createdAt: DateTime(2026, 1, 1),
  );
}
