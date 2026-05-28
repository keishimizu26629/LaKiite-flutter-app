export function calculateAllowedViewerIds({
  ownerId,
  baseVisibleTo = [],
  directUserIds = [],
  membersByListId = {},
}) {
  const viewerIds = new Set([ownerId]);

  for (const userId of baseVisibleTo) addIfPresent(viewerIds, userId);
  for (const userId of directUserIds) addIfPresent(viewerIds, userId);

  for (const memberIds of Object.values(membersByListId)) {
    for (const userId of memberIds ?? []) addIfPresent(viewerIds, userId);
  }

  return [...viewerIds];
}

export function inferDirectUserIdsFromLegacyVisibleTo({
  ownerId,
  legacyVisibleTo = [],
  membersByListId = {},
}) {
  const listMemberIds = new Set();

  for (const memberIds of Object.values(membersByListId)) {
    for (const userId of memberIds ?? []) addIfPresent(listMemberIds, userId);
  }

  return [
    ...new Set(
      legacyVisibleTo.filter(
        (userId) => userId && userId !== ownerId && !listMemberIds.has(userId),
      ),
    ),
  ];
}

export function diffViewerIds({ currentViewerIds = [], nextViewerIds = [] }) {
  const current = new Set(currentViewerIds.filter(Boolean));
  const next = new Set(nextViewerIds.filter(Boolean));

  return {
    toAdd: [...next].filter((userId) => !current.has(userId)),
    toRemove: [...current].filter((userId) => !next.has(userId)),
  };
}

function addIfPresent(target, value) {
  if (value) target.add(value);
}
