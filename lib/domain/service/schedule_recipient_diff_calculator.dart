class ScheduleRecipientDiff {
  const ScheduleRecipientDiff({
    required this.beforeRecipientIds,
    required this.afterRecipientIds,
    required this.addedUserIds,
    required this.removedUserIds,
  });

  final Set<String> beforeRecipientIds;
  final Set<String> afterRecipientIds;
  final Set<String> addedUserIds;
  final Set<String> removedUserIds;

  bool get requiresRekey => removedUserIds.isNotEmpty;

  bool get requiresRewrap => removedUserIds.isEmpty && addedUserIds.isNotEmpty;

  bool get hasNoKeyChange => addedUserIds.isEmpty && removedUserIds.isEmpty;
}

class ScheduleRecipientDiffCalculator {
  const ScheduleRecipientDiffCalculator._();

  static ScheduleRecipientDiff calculate({
    required String ownerId,
    required Iterable<String> beforeSharedListIds,
    required Iterable<String> afterSharedListIds,
    required Map<String, Iterable<String>> membersByListId,
    Map<String, Iterable<String>>? afterMembersByListId,
  }) {
    final beforeRecipientIds = _expandRecipientIds(
      ownerId: ownerId,
      sharedListIds: beforeSharedListIds,
      membersByListId: membersByListId,
    );
    final afterRecipientIds = _expandRecipientIds(
      ownerId: ownerId,
      sharedListIds: afterSharedListIds,
      membersByListId: afterMembersByListId ?? membersByListId,
    );

    return ScheduleRecipientDiff(
      beforeRecipientIds: beforeRecipientIds,
      afterRecipientIds: afterRecipientIds,
      addedUserIds: afterRecipientIds.difference(beforeRecipientIds),
      removedUserIds: beforeRecipientIds.difference(afterRecipientIds),
    );
  }

  static Set<String> _expandRecipientIds({
    required String ownerId,
    required Iterable<String> sharedListIds,
    required Map<String, Iterable<String>> membersByListId,
  }) {
    return {
      if (ownerId.isNotEmpty) ownerId,
      for (final listId in sharedListIds)
        for (final memberId in membersByListId[listId] ?? const <String>[])
          if (memberId.isNotEmpty) memberId,
    };
  }
}
