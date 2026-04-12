import 'package:lakiite/domain/entity/list.dart';
import 'package:lakiite/domain/interfaces/i_list_repository.dart';

class MockListRepository implements IListRepository {
  final List<UserList> _lists = [];

  void addTestList(UserList list) {
    _lists.add(list);
  }

  void reset() {
    _lists.clear();
  }

  @override
  Future<void> addMember(String listId, String userId) async {}

  @override
  Future<UserList> createList({
    required String listName,
    required List<String> memberIds,
    required String ownerId,
    String? iconUrl,
    String? description,
  }) async {
    final list = UserList(
      id: 'list-${_lists.length + 1}',
      listName: listName,
      memberIds: memberIds,
      ownerId: ownerId,
      iconUrl: iconUrl,
      description: description,
      createdAt: DateTime.now(),
    );
    _lists.add(list);
    return list;
  }

  @override
  Future<void> deleteList(String listId) async {
    _lists.removeWhere((list) => list.id == listId);
  }

  @override
  Future<UserList?> getList(String listId) async {
    for (final list in _lists) {
      if (list.id == listId) {
        return list;
      }
    }
    return null;
  }

  @override
  Future<List<UserList>> getLists(String ownerId) async {
    return _lists.where((list) => list.ownerId == ownerId).toList();
  }

  @override
  Future<void> removeMember(String listId, String userId) async {}

  @override
  Future<void> updateList(UserList list) async {
    final index = _lists.indexWhere((item) => item.id == list.id);
    if (index >= 0) {
      _lists[index] = list;
    }
  }

  @override
  Stream<UserList?> watchList(String listId) async* {
    yield await getList(listId);
  }

  @override
  Stream<List<UserList>> watchUserLists(String ownerId) async* {
    yield await getLists(ownerId);
  }
}
