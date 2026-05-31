class ScheduleEnrichmentCache {
  ScheduleEnrichmentCache({
    Duration expiryDuration = const Duration(minutes: 10),
  }) : _expiryDuration = expiryDuration;

  final Duration _expiryDuration;
  final Map<String, int> _reactionCountCache = {};
  final Map<String, int> _commentCountCache = {};
  final Map<String, DateTime> _lastUpdated = {};

  ({int reactionCount, int commentCount})? getInteractionCounts(
    String scheduleId,
  ) {
    final lastUpdated = _lastUpdated[scheduleId];
    if (lastUpdated == null ||
        DateTime.now().difference(lastUpdated) >= _expiryDuration) {
      return null;
    }

    final reactionCount = _reactionCountCache[scheduleId];
    final commentCount = _commentCountCache[scheduleId];
    if (reactionCount == null || commentCount == null) {
      return null;
    }

    return (reactionCount: reactionCount, commentCount: commentCount);
  }

  void storeInteractionCounts(
    String scheduleId, {
    required int reactionCount,
    required int commentCount,
  }) {
    _reactionCountCache[scheduleId] = reactionCount;
    _commentCountCache[scheduleId] = commentCount;
    _lastUpdated[scheduleId] = DateTime.now();
  }

  void invalidateSchedule(String scheduleId) {
    _reactionCountCache.remove(scheduleId);
    _commentCountCache.remove(scheduleId);
    _lastUpdated.remove(scheduleId);
  }

  void clear() {
    _reactionCountCache.clear();
    _commentCountCache.clear();
    _lastUpdated.clear();
  }
}
