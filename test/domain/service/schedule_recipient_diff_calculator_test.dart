import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/domain/service/schedule_recipient_diff_calculator.dart';

void main() {
  group('ScheduleRecipientDiffCalculator', () {
    test('does nothing when changed lists resolve to the same users', () {
      final diff = ScheduleRecipientDiffCalculator.calculate(
        ownerId: 'owner',
        beforeSharedListIds: const ['list-a'],
        afterSharedListIds: const ['list-a', 'list-b'],
        membersByListId: const {
          'list-a': ['a', 'b', 'c'],
          'list-b': ['a', 'b', 'c'],
        },
      );

      expect(diff.addedUserIds, isEmpty);
      expect(diff.removedUserIds, isEmpty);
      expect(diff.requiresRewrap, isFalse);
      expect(diff.requiresRekey, isFalse);
      expect(diff.hasNoKeyChange, isTrue);
    });

    test('requires rewrap when users are added without removals', () {
      final diff = ScheduleRecipientDiffCalculator.calculate(
        ownerId: 'owner',
        beforeSharedListIds: const ['list-a'],
        afterSharedListIds: const ['list-a', 'list-b'],
        membersByListId: const {
          'list-a': ['a', 'b', 'c'],
          'list-b': ['c', 'd'],
        },
      );

      expect(diff.addedUserIds, {'d'});
      expect(diff.removedUserIds, isEmpty);
      expect(diff.requiresRewrap, isTrue);
      expect(diff.requiresRekey, isFalse);
      expect(diff.hasNoKeyChange, isFalse);
    });

    test('requires rekey when any user is removed', () {
      final diff = ScheduleRecipientDiffCalculator.calculate(
        ownerId: 'owner',
        beforeSharedListIds: const ['list-a', 'list-b'],
        afterSharedListIds: const ['list-a'],
        membersByListId: const {
          'list-a': ['a', 'b', 'c'],
          'list-b': ['c', 'd'],
        },
      );

      expect(diff.addedUserIds, isEmpty);
      expect(diff.removedUserIds, {'d'});
      expect(diff.requiresRewrap, isFalse);
      expect(diff.requiresRekey, isTrue);
      expect(diff.hasNoKeyChange, isFalse);
    });

    test('keeps owner in recipients but never treats owner as added', () {
      final diff = ScheduleRecipientDiffCalculator.calculate(
        ownerId: 'owner',
        beforeSharedListIds: const [],
        afterSharedListIds: const ['list-a'],
        membersByListId: const {
          'list-a': ['owner', 'a'],
        },
      );

      expect(diff.beforeRecipientIds, {'owner'});
      expect(diff.afterRecipientIds, {'owner', 'a'});
      expect(diff.addedUserIds, {'a'});
      expect(diff.removedUserIds, isEmpty);
    });

    test('detects member changes when list ids are unchanged', () {
      final diff = ScheduleRecipientDiffCalculator.calculate(
        ownerId: 'owner',
        beforeSharedListIds: const ['list-a'],
        afterSharedListIds: const ['list-a'],
        membersByListId: const {
          'list-a': ['a', 'b', 'c'],
        },
        afterMembersByListId: const {
          'list-a': ['b', 'c', 'd'],
        },
      );

      expect(diff.addedUserIds, {'d'});
      expect(diff.removedUserIds, {'a'});
      expect(diff.requiresRekey, isTrue);
      expect(diff.requiresRewrap, isFalse);
    });
  });
}
