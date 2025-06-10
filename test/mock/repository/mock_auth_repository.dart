import 'package:lakiite/domain/interfaces/i_auth_repository.dart';
import 'package:lakiite/domain/entity/user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../base_mock.dart';

class MockAuthRepository extends BaseMock implements IAuthRepository {
  UserModel? _currentUser;
  bool _shouldFailLogin = false;
  bool _shouldFailSignUp = false;
  bool _shouldFailDelete = false;

  /// ログイン失敗のテストケース用
  void setShouldFailLogin(bool shouldFail) {
    _shouldFailLogin = shouldFail;
  }

  /// サインアップ失敗のテストケース用
  void setShouldFailSignUp(bool shouldFail) {
    _shouldFailSignUp = shouldFail;
  }

  /// アカウント削除失敗のテストケース用
  void setShouldFailDelete(bool shouldFail) {
    _shouldFailDelete = shouldFail;
  }

  /// 現在のユーザーを手動で設定（テスト用）
  void setCurrentUser(UserModel? user) {
    _currentUser = user;
  }

  @override
  Stream<UserModel?> authStateChanges() {
    return Stream.value(_currentUser);
  }

  @override
  Future<UserModel?> signIn(String email, String password) async {
    // 実際のAPIと同じような遅延を模倣
    await Future.delayed(const Duration(milliseconds: 300));

    if (_shouldFailLogin) {
      throw FirebaseAuthException(
        code: 'invalid-credential',
        message: 'テスト用ログイン失敗',
      );
    }

    // 基本的なバリデーション
    if (!email.contains('@')) {
      throw FirebaseAuthException(
        code: 'invalid-email',
        message: '無効なメールアドレス',
      );
    }

    if (password.length < 6) {
      throw FirebaseAuthException(
        code: 'weak-password',
        message: 'パスワードが短すぎます',
      );
    }

    // テスト用の有効な認証情報
    if (email == BaseMock.testEmail && password == 'password123') {
      _currentUser = BaseMock.createTestUser();
      return _currentUser;
    }

    throw FirebaseAuthException(
      code: 'user-not-found',
      message: 'ユーザーが見つかりません',
    );
  }

  @override
  Future<UserModel?> signUp(String email, String password, String name) async {
    // 実際のAPIと同じような遅延を模倣
    await Future.delayed(const Duration(milliseconds: 500));

    if (_shouldFailSignUp) {
      throw FirebaseAuthException(
        code: 'email-already-in-use',
        message: 'テスト用サインアップ失敗',
      );
    }

    // 基本的なバリデーション
    if (!email.contains('@')) {
      throw FirebaseAuthException(
        code: 'invalid-email',
        message: '無効なメールアドレス',
      );
    }

    if (password.length < 6) {
      throw FirebaseAuthException(
        code: 'weak-password',
        message: 'パスワードが短すぎます',
      );
    }

    if (name.trim().isEmpty) {
      throw ArgumentError('名前を入力してください');
    }

    _currentUser = BaseMock.createTestUser(
      name: name,
      displayName: name,
    );
    return _currentUser;
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _currentUser = null;
  }

  @override
  Future<bool> deleteAccount() async {
    await Future.delayed(const Duration(milliseconds: 400));

    if (_shouldFailDelete) {
      throw FirebaseAuthException(
        code: 'requires-recent-login',
        message: 'テスト用削除失敗',
      );
    }

    _currentUser = null;
    return true;
  }

  /// テスト用のリセット機能
  void reset() {
    _currentUser = null;
    _shouldFailLogin = false;
    _shouldFailSignUp = false;
    _shouldFailDelete = false;
  }
}
