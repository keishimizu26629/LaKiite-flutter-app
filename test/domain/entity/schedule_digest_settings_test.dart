import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/domain/entity/schedule_digest_settings.dart';

void main() {
  group('ScheduleDigestSettings', () {
    test('missing document defaults to enabled at 8', () {
      final settings = ScheduleDigestSettings.defaults('user-1');

      expect(settings.userId, 'user-1');
      expect(settings.enabled, isTrue);
      expect(settings.notifyHour, 8);
      expect(settings.lastSentDate, isNull);
    });

    test('serializes notifyHour and enabled fields for Firestore', () {
      final settings = ScheduleDigestSettings(
        userId: 'user-1',
        enabled: false,
        notifyHour: 7,
        lastSentDate: '2026-06-03',
      );

      final data = settings.toFirestore();

      expect(data['enabled'], isFalse);
      expect(data['notifyHour'], 7);
      expect(data['lastSentDate'], '2026-06-03');
      expect(data['updatedAt'], isA<FieldValue>());
    });

    test('rejects notifyHour outside morning range', () {
      expect(
        () => ScheduleDigestSettings(
          userId: 'user-1',
          enabled: true,
          notifyHour: 10,
        ),
        throwsArgumentError,
      );
    });
  });
}
