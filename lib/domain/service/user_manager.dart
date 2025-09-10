import 'package:lakiite/domain/entity/user.dart';
import 'package:lakiite/domain/interfaces/i_user_repository.dart';

/// ユーザー関連のビジネスロジックを集約するManager
///
/// 機能:
/// - 統合されたユーザー情報の提供
/// - フレンド一覧の管理
/// - ユーザープロフィールの統合
abstract class IUserManager {
  /// 統合されたユーザー情報を取得
  Future<UserModel?> getIntegratedUser(String userId);

  /// 統合されたユーザー情報を監視
  Stream<UserModel?> watchIntegratedUser(String userId);

  /// 認証済みユーザーのフレンド一覧を取得
  Future<List<PublicUserModel>> getAuthenticatedUserFriends(String userId);

  /// 認証済みユーザーのフレンド一覧を監視
  Stream<List<PublicUserModel>> watchAuthenticatedUserFriends(String userId);
}

class UserManager implements IUserManager {
  final IUserRepository _userRepository;

  UserManager(this._userRepository);

  @override
  Future<UserModel?> getIntegratedUser(String userId) async {
    // ユーザー情報を直接取得
    return await _userRepository.getUser(userId);
  }

  @override
  Stream<UserModel?> watchIntegratedUser(String userId) {
    // ユーザー情報を監視
    return _userRepository.watchUser(userId);
  }

  @override
  Future<List<PublicUserModel>> getAuthenticatedUserFriends(
      String userId) async {
    final user = await _userRepository.getUser(userId);
    if (user == null || user.friends.isEmpty) {
      return [];
    }

    final profiles = await _userRepository.getPublicProfiles(user.friends);
    return profiles;
  }

  @override
  Stream<List<PublicUserModel>> watchAuthenticatedUserFriends(String userId) {
    return _userRepository.watchUser(userId).asyncMap((user) async {
      if (user == null || user.friends.isEmpty) {
        return <PublicUserModel>[];
      }

      final profiles = await _userRepository.getPublicProfiles(user.friends);
      return profiles;
    });
  }
}
