import 'dart:typed_data';
import 'package:lakiite/domain/interfaces/i_user_repository.dart';
import 'package:lakiite/domain/entity/user.dart';
import 'package:lakiite/domain/value/user_id.dart';
import '../base_mock.dart';

class MockUserRepository extends BaseMock implements IUserRepository {
  final Map<String, UserModel> _users = {};
  final List<String> _friendConnections = [];
  bool _shouldFailGet = false;
  bool _shouldFailCreate = false;
  bool _shouldFailUpdate = false;
  bool _shouldFailDelete = false;
  bool _shouldFailUpload = false;

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

  void setShouldFailUpload(bool shouldFail) {
    _shouldFailUpload = shouldFail;
  }

  void addTestUser(UserModel user) {
    _users[user.id] = user;
  }

  void addFriendConnection(String userId1, String userId2) {
    final connection = '${userId1}_$userId2';
    if (!_friendConnections.contains(connection)) {
      _friendConnections.add(connection);
    }
  }

  void clearUsers() {
    _users.clear();
    _friendConnections.clear();
  }

  @override
  Future<UserModel?> getUser(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));

    if (_shouldFailGet) {
      throw Exception('テスト用取得失敗');
    }

    return _users[id];
  }

  @override
  Future<PublicUserModel?> getFriendPublicProfile(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));

    if (_shouldFailGet) {
      throw Exception('テスト用取得失敗');
    }

    final user = _users[id];
    return user?.publicProfile;
  }

  @override
  Future<void> createUser(UserModel user) async {
    await Future.delayed(const Duration(milliseconds: 300));

    if (_shouldFailCreate) {
      throw Exception('テスト用作成失敗');
    }

    if (_users.containsKey(user.id)) {
      throw Exception('ユーザーは既に存在します');
    }

    _users[user.id] = user;
  }

  @override
  Future<void> updateUser(UserModel user) async {
    await Future.delayed(const Duration(milliseconds: 300));

    if (_shouldFailUpdate) {
      throw Exception('テスト用更新失敗');
    }

    if (!_users.containsKey(user.id)) {
      throw Exception('ユーザーが見つかりません');
    }

    _users[user.id] = user;
  }

  @override
  Future<void> deleteUser(String id) async {
    await Future.delayed(const Duration(milliseconds: 250));

    if (_shouldFailDelete) {
      throw Exception('テスト用削除失敗');
    }

    if (!_users.containsKey(id)) {
      throw Exception('削除対象のユーザーが見つかりません');
    }

    _users.remove(id);
    _friendConnections.removeWhere((conn) => conn.contains(id));
  }

  @override
  Future<String?> uploadUserIcon(String userId, Uint8List imageBytes) async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (_shouldFailUpload) {
      return null;
    }

    // テスト用のURLを返す
    return 'https://test-storage.example.com/user-icons/$userId.jpg';
  }

  @override
  Future<void> deleteUserIcon(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final user = _users[userId];
    if (user != null) {
      final updatedUser = user.updateProfile(iconUrl: null);
      _users[userId] = updatedUser;
    }
  }

  @override
  Future<bool> isUserIdUnique(UserId userId) async {
    await Future.delayed(const Duration(milliseconds: 150));

    return !_users.values.any((user) => user.searchId == userId);
  }

  @override
  Future<SearchUserModel?> findByUserId(UserId userId) async {
    await Future.delayed(const Duration(milliseconds: 200));

    if (_shouldFailGet) {
      throw Exception('テスト用検索失敗');
    }

    try {
      final user = _users.values.firstWhere((user) => user.searchId == userId);
      return SearchUserModel.fromUserModel(user);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<SearchUserModel?> findBySearchId(String searchId) async {
    await Future.delayed(const Duration(milliseconds: 200));

    if (_shouldFailGet) {
      throw Exception('テスト用検索失敗');
    }

    try {
      final user = _users.values.firstWhere(
        (user) => user.searchId.toString() == searchId,
      );
      return SearchUserModel.fromUserModel(user);
    } catch (e) {
      return null;
    }
  }

  @override
  Stream<PublicUserModel?> watchPublicProfile(String id) {
    return Stream.periodic(const Duration(milliseconds: 100), (_) {
      final user = _users[id];
      return user?.publicProfile;
    }).take(1);
  }

  @override
  Stream<PrivateUserModel?> watchPrivateProfile(String id) {
    return Stream.periodic(const Duration(milliseconds: 100), (_) {
      final user = _users[id];
      return user?.privateProfile;
    }).take(1);
  }

  @override
  Stream<UserModel?> watchUser(String id) {
    return Stream.periodic(const Duration(milliseconds: 100), (_) {
      return _users[id];
    }).take(1);
  }

  @override
  Future<void> addToList(String userId, String memberId) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final user = _users[userId];
    if (user == null) {
      throw Exception('ユーザーが見つかりません');
    }

    if (user.friends.contains(memberId)) {
      throw Exception('ユーザーは既に友達です');
    }

    final updatedUser = UserModel(
      publicProfile: user.publicProfile,
      privateProfile: PrivateUserModel(
        id: user.id,
        name: user.name,
        friends: [...user.friends, memberId],
        groups: user.groups,
        lists: user.privateProfile.lists,
        createdAt: user.createdAt,
        fcmToken: user.fcmToken,
      ),
    );

    _users[userId] = updatedUser;
    addFriendConnection(userId, memberId);
  }

  @override
  Future<void> removeFromList(String userId, String memberId) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final user = _users[userId];
    if (user == null) {
      throw Exception('ユーザーが見つかりません');
    }

    if (!user.friends.contains(memberId)) {
      throw Exception('ユーザーは友達ではありません');
    }

    final updatedUser = UserModel(
      publicProfile: user.publicProfile,
      privateProfile: PrivateUserModel(
        id: user.id,
        name: user.name,
        friends: user.friends.where((id) => id != memberId).toList(),
        groups: user.groups,
        lists: user.privateProfile.lists,
        createdAt: user.createdAt,
        fcmToken: user.fcmToken,
      ),
    );

    _users[userId] = updatedUser;
    _friendConnections.removeWhere((conn) =>
        conn == '${userId}_$memberId' || conn == '${memberId}_$userId');
  }

  @override
  Future<List<PublicUserModel>> getPublicProfiles(List<String> userIds) async {
    await Future.delayed(const Duration(milliseconds: 200));

    if (_shouldFailGet) {
      throw Exception('テスト用取得失敗');
    }

    final profiles = <PublicUserModel>[];
    for (final userId in userIds) {
      final user = _users[userId];
      if (user != null) {
        profiles.add(user.publicProfile);
      }
    }

    return profiles;
  }

  /// テスト用のリセット機能
  void reset() {
    _users.clear();
    _friendConnections.clear();
    _shouldFailGet = false;
    _shouldFailCreate = false;
    _shouldFailUpdate = false;
    _shouldFailDelete = false;
    _shouldFailUpload = false;
  }
}
