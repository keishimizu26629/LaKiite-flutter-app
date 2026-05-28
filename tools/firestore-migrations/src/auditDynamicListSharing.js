#!/usr/bin/env node
import process from 'node:process';
import { applicationDefault, getApps, initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import {
  calculateAllowedViewerIds,
  inferDirectUserIdsFromLegacyVisibleTo,
} from './sharedSharingCalculator.js';

const args = parseArgs(process.argv.slice(2));

if (args.apply) {
  console.error(
    'This command is audit-only. Refusing --apply because no writes are implemented.',
  );
  process.exit(2);
}

const directSharePolicy = args.directSharePolicy ?? 'none';
if (!['none', 'infer-from-visible-to'].includes(directSharePolicy)) {
  console.error(
    '--direct-share-policy must be one of: none, infer-from-visible-to',
  );
  process.exit(2);
}

if (!getApps().length) {
  initializeApp({
    credential: applicationDefault(),
    projectId: args.projectId,
  });
}

const db = getFirestore();
const report = await auditDynamicListSharing({
  db,
  limit: args.limit ? Number(args.limit) : undefined,
  ownerId: args.ownerId,
  directSharePolicy,
});

console.log(JSON.stringify(report, null, 2));

async function auditDynamicListSharing({
  db,
  limit,
  ownerId,
  directSharePolicy,
}) {
  const legacyListsById = await fetchLegacyListsById(db, ownerId);
  let schedulesQuery = db.collection('schedules');

  if (ownerId) {
    schedulesQuery = schedulesQuery.where('ownerId', '==', ownerId);
  }

  if (Number.isFinite(limit) && limit > 0) {
    schedulesQuery = schedulesQuery.limit(limit);
  }

  const schedulesSnapshot = await schedulesQuery.get();
  const report = createEmptyReport({
    legacyListsScanned: legacyListsById.size,
    directSharePolicy,
    ownerId: ownerId ?? null,
    limit: limit ?? null,
  });

  for (const scheduleDoc of schedulesSnapshot.docs) {
    report.schedulesScanned += 1;

    const schedule = scheduleDoc.data();
    const scheduleOwnerId = valueAsString(schedule.ownerId);
    const sharedListIds = valueAsStringArray(schedule.sharedLists);
    const legacyVisibleTo = valueAsStringArray(schedule.visibleTo);

    if (!scheduleOwnerId) {
      report.schedulesWithoutOwner += 1;
      report.warnings.push({
        type: 'schedule_without_owner',
        scheduleId: scheduleDoc.id,
      });
      continue;
    }

    if (sharedListIds.length > 0) {
      report.schedulesWithSharedLists += 1;
    }

    const membersByListId = {};
    for (const listId of sharedListIds) {
      const list = legacyListsById.get(listId);

      if (!list) {
        report.missingListsReferenced += 1;
        report.warnings.push({
          type: 'missing_legacy_list',
          scheduleId: scheduleDoc.id,
          listId,
        });
        continue;
      }

      if (list.ownerId && list.ownerId !== scheduleOwnerId) {
        report.listOwnerMismatches += 1;
        report.warnings.push({
          type: 'list_owner_mismatch',
          scheduleId: scheduleDoc.id,
          scheduleOwnerId,
          listId,
          listOwnerId: list.ownerId,
        });
      }

      membersByListId[listId] = list.memberIds;
    }

    const directUserIds =
      directSharePolicy === 'infer-from-visible-to'
        ? inferDirectUserIdsFromLegacyVisibleTo({
            ownerId: scheduleOwnerId,
            legacyVisibleTo,
            membersByListId,
          })
        : [];

    const nextViewerIds = calculateAllowedViewerIds({
      ownerId: scheduleOwnerId,
      directUserIds,
      membersByListId,
    });

    const visibleToDiff = symmetricDifferenceCount(
      legacyVisibleTo,
      nextViewerIds,
    );

    if (visibleToDiff > 0) {
      report.legacyVisibleToDiffCount += 1;
    }

    report.shareSourcesToCreate += 1;
    report.listIndexEntriesToCreate += sharedListIds.length;
    report.viewerIndexesToCreate += nextViewerIds.length;
    report.maxViewerCountPerSchedule = Math.max(
      report.maxViewerCountPerSchedule,
      nextViewerIds.length,
    );
    report.directUserIdsInferred += directUserIds.length;
    report.estimatedWrites += 1 + sharedListIds.length + nextViewerIds.length;
  }

  return report;
}

async function fetchLegacyListsById(db, ownerId) {
  let listsQuery = db.collection('lists');

  if (ownerId) {
    listsQuery = listsQuery.where('ownerId', '==', ownerId);
  }

  const snapshot = await listsQuery.get();
  const listsById = new Map();

  for (const doc of snapshot.docs) {
    const data = doc.data();
    listsById.set(doc.id, {
      ownerId: valueAsString(data.ownerId),
      memberIds: valueAsStringArray(data.memberIds),
    });
  }

  return listsById;
}

function createEmptyReport({ legacyListsScanned, directSharePolicy, ownerId, limit }) {
  return {
    mode: 'dry-run',
    directSharePolicy,
    ownerId,
    limit,
    legacyListsScanned,
    schedulesScanned: 0,
    schedulesWithSharedLists: 0,
    schedulesWithoutOwner: 0,
    missingListsReferenced: 0,
    listOwnerMismatches: 0,
    shareSourcesToCreate: 0,
    listIndexEntriesToCreate: 0,
    viewerIndexesToCreate: 0,
    legacyVisibleToDiffCount: 0,
    directUserIdsInferred: 0,
    maxViewerCountPerSchedule: 0,
    estimatedWrites: 0,
    warnings: [],
  };
}

function symmetricDifferenceCount(left, right) {
  const leftSet = new Set(left);
  const rightSet = new Set(right);
  let count = 0;

  for (const value of leftSet) {
    if (!rightSet.has(value)) count += 1;
  }

  for (const value of rightSet) {
    if (!leftSet.has(value)) count += 1;
  }

  return count;
}

function valueAsString(value) {
  return typeof value === 'string' ? value : '';
}

function valueAsStringArray(value) {
  return Array.isArray(value)
    ? value.filter((item) => typeof item === 'string' && item.length > 0)
    : [];
}

function parseArgs(rawArgs) {
  const parsed = {
    dryRun: true,
    apply: false,
  };

  for (const arg of rawArgs) {
    if (arg === '--dry-run') parsed.dryRun = true;
    else if (arg === '--apply') parsed.apply = true;
    else if (arg.startsWith('--project-id=')) {
      parsed.projectId = arg.slice('--project-id='.length);
    } else if (arg.startsWith('--owner-id=')) {
      parsed.ownerId = arg.slice('--owner-id='.length);
    } else if (arg.startsWith('--limit=')) {
      parsed.limit = arg.slice('--limit='.length);
    } else if (arg.startsWith('--direct-share-policy=')) {
      parsed.directSharePolicy = arg.slice('--direct-share-policy='.length);
    } else {
      console.error(`Unknown argument: ${arg}`);
      process.exit(2);
    }
  }

  return parsed;
}
