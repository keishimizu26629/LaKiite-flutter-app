import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/domain/service/schedule_share_calculator.dart';

void main() {
  group('ScheduleShareCalculator', () {
    test('combines owner, legacy visibility, direct users, and list members',
        () {
      final viewerIds = ScheduleShareCalculator.calculateAllowedViewerIds(
        ownerId: 'owner-1',
        baseVisibleTo: const ['owner-1', 'legacy-user'],
        directUserIds: const ['direct-user'],
        membersByListId: const {
          'list-1': ['friend-1', 'friend-2'],
          'list-2': ['friend-2', 'friend-3'],
        },
      );

      expect(
        viewerIds,
        unorderedEquals([
          'owner-1',
          'legacy-user',
          'direct-user',
          'friend-1',
          'friend-2',
          'friend-3',
        ]),
      );
    });

    test('deduplicates users across multiple lists', () {
      final viewerIds = ScheduleShareCalculator.calculateAllowedViewerIds(
        ownerId: 'owner-1',
        membersByListId: const {
          'list-1': ['friend-1', 'friend-2'],
          'list-2': ['friend-2', 'friend-3'],
        },
      );

      expect(viewerIds.where((id) => id == 'friend-2'), hasLength(1));
      expect(
          viewerIds,
          unorderedEquals([
            'owner-1',
            'friend-1',
            'friend-2',
            'friend-3',
          ]));
    });

    test('infers direct users from legacy visibleTo when requested', () {
      final directUserIds =
          ScheduleShareCalculator.inferDirectUserIdsFromLegacyVisibleTo(
        ownerId: 'owner-1',
        legacyVisibleTo: const [
          'owner-1',
          'friend-1',
          'direct-user',
          'stale-user',
        ],
        membersByListId: const {
          'list-1': ['friend-1', 'friend-2'],
        },
      );

      expect(directUserIds, unorderedEquals(['direct-user', 'stale-user']));
    });

    test('calculates viewer index diff', () {
      final diff = ScheduleShareCalculator.diffViewerIds(
        currentViewerIds: const ['owner-1', 'friend-1', 'friend-2'],
        nextViewerIds: const ['owner-1', 'friend-2', 'friend-3'],
      );

      expect(diff.toAdd, ['friend-3']);
      expect(diff.toRemove, ['friend-1']);
    });
  });
}
