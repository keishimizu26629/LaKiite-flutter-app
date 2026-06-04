import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/domain/entity/display_list.dart';
import 'package:lakiite/domain/service/display_list_membership.dart';

void main() {
  group('DisplayListMembership', () {
    test('finds the display list containing a schedule owner', () {
      final displayLists = [
        _displayList(id: 'family', colorKey: 'red', memberIds: ['friend-1']),
        _displayList(id: 'work', colorKey: 'blue', memberIds: ['friend-2']),
      ];

      final result = DisplayListMembership.findListForUser(
        displayLists: displayLists,
        userId: 'friend-2',
      );

      expect(result?.id, 'work');
      expect(result?.colorKey, 'blue');
    });

    test('returns null when the user is not in any display list', () {
      final displayLists = [
        _displayList(id: 'family', colorKey: 'red', memberIds: ['friend-1']),
      ];

      final result = DisplayListMembership.findListForUser(
        displayLists: displayLists,
        userId: 'friend-2',
      );

      expect(result, isNull);
    });

    test('detects membership in another display list', () {
      final displayLists = [
        _displayList(id: 'family', colorKey: 'red', memberIds: ['friend-1']),
        _displayList(id: 'work', colorKey: 'blue', memberIds: ['friend-2']),
      ];

      final result = DisplayListMembership.findConflictingList(
        displayLists: displayLists,
        targetListId: 'family',
        userId: 'friend-2',
      );

      expect(result?.id, 'work');
    });
  });
}

DisplayList _displayList({
  required String id,
  required String colorKey,
  required List<String> memberIds,
}) {
  final now = DateTime(2026, 6, 3);
  return DisplayList(
    id: id,
    name: id,
    ownerId: 'owner',
    colorKey: colorKey,
    memberIds: memberIds,
    createdAt: now,
    updatedAt: now,
  );
}
