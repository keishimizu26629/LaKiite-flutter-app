import 'package:firebase_auth/firebase_auth.dart';
import 'package:lakiite/domain/entity/user.dart';
import 'package:lakiite/domain/interfaces/i_auth_repository.dart';

class MockAuthRepository implements IAuthRepository {
  UserModel? _currentUser;

  @override
  Stream<UserModel?> authStateChanges() {
    // テスト時は常に未認証状態を返す
    return Stream.value(null);
  }

  @override
  Future<UserModel?> signIn(String email, String password) async {
    // テスト用の認証処理
    if (email == 'test@example.com' && password == 'password123') {
      _currentUser = _createMockUser();
      return Future.value(_currentUser);
    }
    throw FirebaseAuthException(code: 'invalid-credential');
  }

  @override
  Future<UserModel?> signUp(String email, String password, String name) async {
    _currentUser = _createMockUser();
    return Future.value(_currentUser);
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
  }

  @override
  Future<bool> deleteAccount() async {
    await Future.delayed(const Duration(milliseconds: 200));

    if (_currentUser == null) {
      throw Exception('ユーザーがログインしていません');
    }

    _currentUser = null;
    return true;
  }

  @override
  Future<bool> reauthenticateWithPassword(String password) async {
    await Future.delayed(const Duration(milliseconds: 100));

    if (_currentUser == null) {
      throw Exception('ユーザーがログインしていません');
    }

    // テスト用の簡単な再認証シミュレーション
    if (password.isEmpty) {
      throw Exception('パスワードが正しくありません');
    }

    return true;
  }

  @override
  Future<bool> deleteAccountWithReauth(String password) async {
    await Future.delayed(const Duration(milliseconds: 300));

    if (_currentUser == null) {
      throw Exception('ユーザーがログインしていません');
    }

    // 再認証をシミュレート
    if (password.isEmpty) {
      throw Exception('パスワードが正しくありません');
    }

    // アカウント削除をシミュレート
    _currentUser = null;
    return true;
  }

  UserModel _createMockUser() {
    return UserModel.create(
      id: 'test-user-id',
      name: 'Test User',
      displayName: 'Test User Display Name',
    );
  }
}
