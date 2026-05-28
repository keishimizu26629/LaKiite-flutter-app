import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import {
  calculateAllowedViewerIds,
  diffViewerIds,
  inferDirectUserIdsFromLegacyVisibleTo,
} from '../src/sharedSharingCalculator.js';

describe('sharedSharingCalculator', () => {
  it('combines owner, legacy visibility, direct users, and list members', () => {
    const viewerIds = calculateAllowedViewerIds({
      ownerId: 'owner-1',
      baseVisibleTo: ['owner-1', 'legacy-user'],
      directUserIds: ['direct-user'],
      membersByListId: {
        'list-1': ['friend-1', 'friend-2'],
        'list-2': ['friend-2', 'friend-3'],
      },
    });

    assert.deepEqual(new Set(viewerIds), new Set([
      'owner-1',
      'legacy-user',
      'direct-user',
      'friend-1',
      'friend-2',
      'friend-3',
    ]));
  });

  it('infers direct users from legacy visibleTo', () => {
    const directUserIds = inferDirectUserIdsFromLegacyVisibleTo({
      ownerId: 'owner-1',
      legacyVisibleTo: ['owner-1', 'friend-1', 'direct-user', 'stale-user'],
      membersByListId: {
        'list-1': ['friend-1', 'friend-2'],
      },
    });

    assert.deepEqual(new Set(directUserIds), new Set([
      'direct-user',
      'stale-user',
    ]));
  });

  it('calculates viewer index diff', () => {
    const diff = diffViewerIds({
      currentViewerIds: ['owner-1', 'friend-1', 'friend-2'],
      nextViewerIds: ['owner-1', 'friend-2', 'friend-3'],
    });

    assert.deepEqual(diff, {
      toAdd: ['friend-3'],
      toRemove: ['friend-1'],
    });
  });
});
