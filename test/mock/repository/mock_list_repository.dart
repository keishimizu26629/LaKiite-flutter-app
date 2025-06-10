import 'package:lakiite/domain/interfaces/i_list_repository.dart';
import 'package:lakiite/domain/entity/list.dart';
import '../base_mock.dart';

class MockListRepository extends BaseMock implements IListRepository {
  final List<UserList> _lists = [];
  bool _shouldFailCreate = false;
  bool _shouldFailUpdate = false;
  bool _shouldFailDelete = false;
  bool _shouldFailGet = false;

  void setShouldFailCreate(bool shouldFail) {
    _shouldFailCreate = shouldFail;
  }

  void setShouldFailUpdate(bool shouldFail) {
    _shouldFailUpdate = shouldFail;
  }

  void setShouldFailDelete(bool shouldFail) {
    _shouldFailDelete = shouldFail;
  }

  void setShouldFailGet(bool shouldFail) {
    _shouldFailGet = shouldFail;
  }

  void addTestList(UserList list) {
    _lists.add(list);
  }

  void clearLists() {
    _lists.clear();
  }

  @override
  Future<List<UserList>> getLists(String ownerId) async {
    await Future.delayed(const Duration(milliseconds: 200));

    if (_shouldFailGet) {
      throw Exception('テスト用取得失敗');
    }

    return _lists.where((list) => list.ownerId == ownerId).toList();
  }

  @override
  Future<UserList> createList({
    required String listName,
    required List<String> memberIds,
    required String ownerId,
    String? iconUrl,
    String? description,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    if (_shouldFailCreate) {
      throw Exception('テスト用作成失敗');
    }

    if (listName.trim().isEmpty) {
      throw ArgumentError('リスト名を入力してください');
    }

    final newList = UserList(
      id: 'list-${_lists.length}',
      listName: listName,
      memberIds: memberIds,
      ownerId: ownerId,
      iconUrl: iconUrl,
      description: description,
      createdAt: DateTime.now(),
    );

    _lists.add(newList);
    return newList;
  }

  @override
  Future<void> updateList(UserList list) async {
    await Future.delayed(const Duration(milliseconds: 300));

    if (_shouldFailUpdate) {
      throw Exception('テスト用更新失敗');
    }

    final index = _lists.indexWhere((l) => l.id == list.id);
    if (index >= 0) {
      _lists[index] = list;
    } else {
      throw Exception('リストが見つかりません');
    }
  }

  @override
  Future<void> deleteList(String listId) async {
    await Future.delayed(const Duration(milliseconds: 250));

    if (_shouldFailDelete) {
      throw Exception('テスト用削除失敗');
    }

    final initialLength = _lists.length;
    _lists.removeWhere((list) => list.id == listId);

    if (_lists.length == initialLength) {
      throw Exception('削除対象のリストが見つかりません');
    }
  }

  @override
  Future<void> addMember(String listId, String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final listIndex = _lists.indexWhere((list) => list.id == listId);
    if (listIndex < 0) {
      throw Exception('リストが見つかりません');
    }

    final currentList = _lists[listIndex];
    if (currentList.memberIds.contains(userId)) {
      throw Exception('ユーザーは既にリストのメンバーです');
    }

    final updatedList = currentList.copyWith(
      memberIds: [...currentList.memberIds, userId],
    );

    _lists[listIndex] = updatedList;
  }

  @override
  Future<void> removeMember(String listId, String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final listIndex = _lists.indexWhere((list) => list.id == listId);
    if (listIndex < 0) {
      throw Exception('リストが見つかりません');
    }

    final currentList = _lists[listIndex];
    if (!currentList.memberIds.contains(userId)) {
      throw Exception('ユーザーはリストのメンバーではありません');
    }

    final updatedList = currentList.copyWith(
      memberIds: currentList.memberIds.where((id) => id != userId).toList(),
    );

    _lists[listIndex] = updatedList;
  }

  @override
  Stream<List<UserList>> watchUserLists(String ownerId) {
    return Stream.periodic(const Duration(milliseconds: 100), (_) {
      return _lists.where((list) => list.ownerId == ownerId).toList();
    }).take(1);
  }

  @override
  Stream<UserList?> watchList(String listId) {
    return Stream.periodic(const Duration(milliseconds: 100), (_) {
      try {
        return _lists.firstWhere((list) => list.id == listId);
      } catch (e) {
        return null;
      }
    }).take(1);
  }

  @override
  Future<UserList?> getList(String listId) async {
    await Future.delayed(const Duration(milliseconds: 200));

    if (_shouldFailGet) {
      throw Exception('テスト用取得失敗');
    }

    try {
      return _lists.firstWhere((list) => list.id == listId);
    } catch (e) {
      return null;
    }
  }

  /// テスト用のリセット機能
  void reset() {
    _lists.clear();
    _shouldFailCreate = false;
    _shouldFailUpdate = false;
    _shouldFailDelete = false;
    _shouldFailGet = false;
  }
}
