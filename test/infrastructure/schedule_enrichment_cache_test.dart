import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/infrastructure/schedule_enrichment_cache.dart';

void main() {
  group('ScheduleEnrichmentCache', () {
    test('予定本体はキャッシュせず、interaction countだけを再利用する', () {
      final cache = ScheduleEnrichmentCache();

      cache.storeInteractionCounts(
        'schedule-1',
        reactionCount: 2,
        commentCount: 3,
      );

      expect(
        cache.getInteractionCounts('schedule-1'),
        (reactionCount: 2, commentCount: 3),
      );
    });

    test('invalidateScheduleはinteraction countを破棄する', () {
      final cache = ScheduleEnrichmentCache();

      cache.storeInteractionCounts(
        'schedule-1',
        reactionCount: 2,
        commentCount: 3,
      );
      cache.invalidateSchedule('schedule-1');

      expect(cache.getInteractionCounts('schedule-1'), isNull);
    });
  });
}
