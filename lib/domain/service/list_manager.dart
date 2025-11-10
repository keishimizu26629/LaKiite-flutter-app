import 'package:lakiite/domain/entity/list.dart';
import 'package:lakiite/domain/interfaces/i_list_repository.dart';

/// リスト関連のビジネスロジックを集約するManager
///
/// 機能:
/// - 認証状態に基づくリスト取得
/// - リスト作成・更新・削除
/// - リストの監視
abstract class IListManager {
  /// 認証済みユーザーのリスト一覧を取得
  Future<List<UserList>> getAuthenticatedUserLists(String userId);

  /// 認証済みユーザーのリスト監視
  Stream<List<UserList>> watchAuthenticatedUserLists(String userId);

  /// リストの作成
  Future<UserList> createList({
    required String userId,
    required String listName,
    required List<String> memberIds,
    String? description,
    String? iconUrl,
  });

  /// リストの更新
  Future<void> updateList(UserList list);

  /// リストの削除
  Future<void> deleteList(String listId);

  /// 特定のリストを監視
  Stream<UserList?> watchList(String listId);

  /// リストにメンバーを追加
  Future<void> addMember(String listId, String userId);

  /// リストからメンバーを削除
  Future<void> removeMember(String listId, String userId);
}

class ListManager implements IListManager {
  ListManager(this._listRepository);

  final IListRepository _listRepository;

  @override
  Future<List<UserList>> getAuthenticatedUserLists(String userId) async {
    return await _listRepository.getLists(userId);
  }

  @override
  Stream<List<UserList>> watchAuthenticatedUserLists(String userId) {
    return _listRepository.watchUserLists(userId);
  }

  @override
  Future<UserList> createList({
    required String userId,
    required String listName,
    required List<String> memberIds,
    String? description,
    String? iconUrl,
  }) async {
    return await _listRepository.createList(
      listName: listName,
      memberIds: memberIds,
      ownerId: userId,
      description: description,
      iconUrl: iconUrl,
    );
  }

  @override
  Future<void> updateList(UserList list) async {
    await _listRepository.updateList(list);
  }

  @override
  Future<void> deleteList(String listId) async {
    await _listRepository.deleteList(listId);
  }

  @override
  Stream<UserList?> watchList(String listId) {
    return _listRepository.watchList(listId);
  }

  @override
  Future<void> addMember(String listId, String userId) async {
    await _listRepository.addMember(listId, userId);
  }

  @override
  Future<void> removeMember(String listId, String userId) async {
    await _listRepository.removeMember(listId, userId);
  }
}
