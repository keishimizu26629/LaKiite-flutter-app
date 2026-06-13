import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/domain/entity/display_list.dart';
import 'package:lakiite/infrastructure/display_list_repository.dart';

void main() {
  group('DisplayListRepository', () {
    group('sortByName', () {
      test('nameの昇順に並べる', () {
        final displayLists = [
          _displayList(id: '3', name: 'Zoo'),
          _displayList(id: '2', name: 'apple'),
          _displayList(id: '1', name: 'Family'),
        ];

        final result = DisplayListRepository.sortByName(displayLists);

        expect(result.map((list) => list.id), ['2', '1', '3']);
      });

      test('同名の場合はid順に並べる', () {
        final displayLists = [
          _displayList(id: 'b', name: 'Family'),
          _displayList(id: 'a', name: 'Family'),
        ];

        final result = DisplayListRepository.sortByName(displayLists);

        expect(result.map((list) => list.id), ['a', 'b']);
      });
    });
  });
}

DisplayList _displayList({
  required String id,
  required String name,
}) {
  return DisplayList(
    id: id,
    name: name,
    ownerId: 'owner',
    colorKey: 'red',
    memberIds: const [],
    createdAt: DateTime(2026, 6, 14),
    updatedAt: DateTime(2026, 6, 14),
  );
}
