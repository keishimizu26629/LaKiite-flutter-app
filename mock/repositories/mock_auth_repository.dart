import 'dart:async';
import 'package:lakiite/domain/interfaces/i_auth_repository.dart';
import 'package:lakiite/domain/entity/user.dart';
import 'package:lakiite/domain/value/user_id.dart';

class MockAuthRepository implements IAuthRepository {
  UserModel? _currentUser;
  bool _shouldFailSignIn = false;
  bool _shouldFailSignUp = false;
  bool _shouldFailSignOut = false;

  void setUser(UserModel? user) {
    _currentUser = user;
    _authStateController.add(user);
  }

  void setShouldFailSignIn(bool shouldFail) {
    _shouldFailSignIn = shouldFail;
  }

  void setShouldFailSignUp(bool shouldFail) {
    _shouldFailSignUp = shouldFail;
  }

  void setShouldFailSignOut(bool shouldFail) {
    _shouldFailSignOut = shouldFail;
  }

  @override
  Stream<UserModel?> authStateChanges() async* {
    yield _currentUser;

    // 継続的な認証状態の監視をシミュレート
    await for (final user in _authStateController.stream) {
      yield user;
    }
  }

  // 認証状態の変更を通知するStreamController
  final StreamController<UserModel?> _authStateController =
      StreamController<UserModel?>.broadcast();

  @override
  Future<UserModel?> signIn(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (_shouldFailSignIn) {
      throw Exception('サインインに失敗しました');
    }

    // テスト用のユーザーを作成
    _currentUser = UserModel.create(
      id: 'test-user-id',
      name: 'テストユーザー',
      displayName: 'テストユーザー',
    );

    _authStateController.add(_currentUser);
    return _currentUser;
  }

  @override
  Future<UserModel?> signUp(String email, String password, String name) async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (_shouldFailSignUp) {
      throw Exception('サインアップに失敗しました');
    }

    // テスト用のユーザーを作成
    _currentUser = UserModel.create(
      id: 'test-user-id',
      name: name,
      displayName: name,
    );

    _authStateController.add(_currentUser);
    return _currentUser;
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 200));

    if (_shouldFailSignOut) {
      throw Exception('サインアウトに失敗しました');
    }

    _currentUser = null;
    _authStateController.add(null);
  }

  @override
  Future<bool> deleteAccount() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _currentUser = null;
    _authStateController.add(null);
    return true;
  }

  @override
  Future<void> updateEmail(String newEmail) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // テスト用の実装
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // テスト用の実装
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // テスト用の実装
  }

  @override
  Future<void> resetPassword(String newPassword, String actionCode) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // テスト用の実装
  }

  /// リソースの解放
  void dispose() {
    _authStateController.close();
  }
}
