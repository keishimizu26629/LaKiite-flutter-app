import 'dart:typed_data';
import 'package:lakiite/domain/interfaces/i_user_repository.dart';
import 'package:lakiite/domain/entity/user.dart';
import 'package:lakiite/domain/value/user_id.dart';

class MockUserRepository implements IUserRepository {
  final Map<String, UserModel> _users = {};
  final Map<String, String> _searchIdToId = {};
  bool _shouldFailGet = false;
  bool _shouldFailCreate = false;
  bool _shouldFailUpdate = false;
  bool _shouldFailDelete = false;

  void setShouldFailGet(bool shouldFail) {
    _shouldFailGet = shouldFail;
  }

  void setShouldFailCreate(bool shouldFail) {
    _shouldFailCreate = shouldFail;
  }

  void setShouldFailUpdate(bool shouldFail) {
    _shouldFailUpdate = shouldFail;
  }

  void setShouldFailDelete(bool shouldFail) {
    _shouldFailDelete = shouldFail;
  }

  void addTestUser(UserModel user) {
    _users[user.id] = user;
    _searchIdToId[user.searchId.toString()] = user.id;
  }

  void clearUsers() {
    _users.clear();
    _searchIdToId.clear();
  }

  @override
  Future<UserModel?> getUser(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));

    if (_shouldFailGet) {
      throw Exception('ユーザー取得に失敗しました');
    }

    return _users[id];
  }

  @override
  Future<PublicUserModel?> getFriendPublicProfile(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));

    if (_shouldFailGet) {
      throw Exception('公開プロフィール取得に失敗しました');
    }

    final user = _users[id];
    return user?.publicProfile;
  }

  @override
  Future<void> createUser(UserModel user) async {
    await Future.delayed(const Duration(milliseconds: 200));

    if (_shouldFailCreate) {
      throw Exception('ユーザー作成に失敗しました');
    }

    _users[user.id] = user;
    _searchIdToId[user.searchId.toString()] = user.id;
  }

  @override
  Future<void> updateUser(UserModel user) async {
    await Future.delayed(const Duration(milliseconds: 200));

    if (_shouldFailUpdate) {
      throw Exception('ユーザー更新に失敗しました');
    }

    _users[user.id] = user;
    _searchIdToId[user.searchId.toString()] = user.id;
  }

  @override
  Future<void> deleteUser(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));

    if (_shouldFailDelete) {
      throw Exception('ユーザー削除に失敗しました');
    }

    final user = _users[id];
    if (user != null) {
      _searchIdToId.remove(user.searchId.toString());
    }
    _users.remove(id);
  }

  @override
  Future<String?> uploadUserIcon(String userId, Uint8List imageBytes) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return 'https://example.com/icon/$userId.jpg';
  }

  @override
  Future<void> deleteUserIcon(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // テスト用の実装
  }

  @override
  Future<bool> isUserIdUnique(UserId userId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return !_searchIdToId.containsKey(userId.toString());
  }

  @override
  Future<SearchUserModel?> findByUserId(UserId userId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final id = _searchIdToId[userId.toString()];
    if (id == null) return null;

    final user = _users[id];
    if (user == null) return null;

    return SearchUserModel(
      id: user.id,
      displayName: user.displayName,
      searchId: user.searchId.toString(),
      iconUrl: user.iconUrl,
      shortBio: user.publicProfile.shortBio,
    );
  }

  @override
  Stream<PublicUserModel?> watchPublicProfile(String id) async* {
    final user = _users[id];
    yield user?.publicProfile;
  }

  @override
  Stream<PrivateUserModel?> watchPrivateProfile(String id) async* {
    final user = _users[id];
    yield user?.privateProfile;
  }

  @override
  Stream<UserModel?> watchUser(String id) async* {
    yield _users[id];
  }

  @override
  Future<SearchUserModel?> findBySearchId(String searchId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final id = _searchIdToId[searchId];
    if (id == null) return null;

    final user = _users[id];
    if (user == null) return null;

    return SearchUserModel(
      id: user.id,
      displayName: user.displayName,
      searchId: user.searchId.toString(),
      iconUrl: user.iconUrl,
      shortBio: user.publicProfile.shortBio,
    );
  }

  @override
  Future<void> addToList(String userId, String memberId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // テスト用の実装
  }

  @override
  Future<void> removeFromList(String userId, String memberId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // テスト用の実装
  }

  @override
  Future<List<PublicUserModel>> getPublicProfiles(List<String> userIds) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return userIds
        .map((id) => _users[id]?.publicProfile)
        .where((profile) => profile != null)
        .cast<PublicUserModel>()
        .toList();
  }
}
