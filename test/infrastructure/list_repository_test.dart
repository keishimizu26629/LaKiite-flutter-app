import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/domain/entity/list.dart';
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

    group('sortByName', () {
      test('listNameの昇順に並べる', () {
        final lists = [
          _list(id: '3', listName: 'Zoo'),
          _list(id: '2', listName: 'apple'),
          _list(id: '1', listName: 'Family'),
        ];

        final result = ListRepository.sortByName(lists);

        expect(result.map((list) => list.id), ['2', '1', '3']);
      });

      test('同名の場合はid順に並べる', () {
        final lists = [
          _list(id: 'b', listName: 'Family'),
          _list(id: 'a', listName: 'Family'),
        ];

        final result = ListRepository.sortByName(lists);

        expect(result.map((list) => list.id), ['a', 'b']);
      });
    });
  });
}

UserList _list({
  required String id,
  required String listName,
}) {
  return UserList(
    id: id,
    listName: listName,
    ownerId: 'owner',
    memberIds: const [],
    createdAt: DateTime(2026, 6, 14),
  );
}
