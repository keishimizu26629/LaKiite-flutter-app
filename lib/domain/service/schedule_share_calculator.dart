/// Calculates schedule visibility from legacy list sharing inputs.
///
/// This service is intentionally pure so migration scripts, Functions logic,
/// and Flutter-side tests can share the same expected behavior.
class ScheduleShareCalculator {
  const ScheduleShareCalculator._();

  /// Returns the users who should be able to view a schedule.
  ///
  /// [baseVisibleTo] is retained for legacy compatibility. In the current app
  /// it usually contains only the owner, but the method accepts a wider base
  /// set so existing callers can preserve direct visibility while list members
  /// are expanded.
  static List<String> calculateAllowedViewerIds({
    required String ownerId,
    Iterable<String> baseVisibleTo = const [],
    Iterable<String> directUserIds = const [],
    required Map<String, Iterable<String>> membersByListId,
  }) {
    final viewerIds = <String>{
      ownerId,
      ...baseVisibleTo.where(_isNotEmpty),
      ...directUserIds.where(_isNotEmpty),
    };

    for (final memberIds in membersByListId.values) {
      viewerIds.addAll(memberIds.where(_isNotEmpty));
    }

    return viewerIds.toList(growable: false);
  }

  /// Infers direct shares from legacy `visibleTo`.
  ///
  /// Use this only for migration reporting or an explicit backfill policy.
  /// Existing `visibleTo` values may already be stale, so callers should prefer
  /// dry-run reporting before applying this as production data.
  static List<String> inferDirectUserIdsFromLegacyVisibleTo({
    required String ownerId,
    required Iterable<String> legacyVisibleTo,
    required Map<String, Iterable<String>> membersByListId,
  }) {
    final listMemberIds = <String>{};
    for (final memberIds in membersByListId.values) {
      listMemberIds.addAll(memberIds.where(_isNotEmpty));
    }

    return legacyVisibleTo
        .where(_isNotEmpty)
        .where((userId) => userId != ownerId)
        .where((userId) => !listMemberIds.contains(userId))
        .toSet()
        .toList(growable: false);
  }

  /// Calculates add/remove operations for viewer indexes.
  static ViewerDiff diffViewerIds({
    required Iterable<String> currentViewerIds,
    required Iterable<String> nextViewerIds,
  }) {
    final current = currentViewerIds.where(_isNotEmpty).toSet();
    final next = nextViewerIds.where(_isNotEmpty).toSet();

    return ViewerDiff(
      toAdd: next.difference(current).toList(growable: false),
      toRemove: current.difference(next).toList(growable: false),
    );
  }

  static bool _isNotEmpty(String value) => value.isNotEmpty;
}

class ViewerDiff {
  const ViewerDiff({
    required this.toAdd,
    required this.toRemove,
  });

  final List<String> toAdd;
  final List<String> toRemove;
}
