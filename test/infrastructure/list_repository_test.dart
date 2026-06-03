import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/infrastructure/list_repository.dart';

void main() {
  group('ListRepository', () {
    group('parseCreatedAt', () {
      test('TimestampをDateTimeに変換する', () {
        final createdAt = DateTime(2026, 6, 3, 9);

        final result =
            ListRepository.parseCreatedAt(Timestamp.fromDate(createdAt));

        expect(result, createdAt);
      });

      test('ISO文字列をDateTimeに変換する', () {
        final createdAt = DateTime(2026, 6, 3, 9);

        final result =
            ListRepository.parseCreatedAt(createdAt.toIso8601String());

        expect(result, createdAt);
      });

      test('DateTimeはそのまま返す', () {
        final createdAt = DateTime(2026, 6, 3, 9);

        final result = ListRepository.parseCreatedAt(createdAt);

        expect(result, createdAt);
      });

      test('nullはfallbackを返す', () {
        final fallback = DateTime(2026, 6, 3, 9);

        final result = ListRepository.parseCreatedAt(null, fallback: fallback);

        expect(result, fallback);
      });
    });
  });
}
