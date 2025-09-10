import 'dart:async';
import 'package:lakiite/domain/interfaces/i_auth_repository.dart';
import 'package:lakiite/domain/entity/user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../base_mock.dart';

class MockAuthRepository extends BaseMock implements IAuthRepository {
  UserModel? _currentUser;
  bool _shouldFailLogin = false;
  bool _shouldFailSignUp = false;
  bool _shouldFailDelete = false;

  final StreamController<UserModel?> _authStateController =
      StreamController<UserModel?>.broadcast();

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
    _authStateController.add(user);
  }

  /// テスト用ユーザーを作成するファクトリーメソッド
  static UserModel createTestUser({
    String? id,
    required String name,
    required String displayName,
  }) {
    return UserModel.create(
      id: id ?? 'test-user-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      displayName: displayName,
    );
  }

  @override
  Stream<UserModel?> authStateChanges() {
    // 初期値をすぐに送信
    _authStateController.add(_currentUser);
    return _authStateController.stream;
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
        code: 'wrong-password',
        message: 'パスワードが間違っています',
      );
    }

    _currentUser = BaseMock.createTestUser(
      name: 'テストユーザー',
      displayName: 'テスト表示名',
    );
    _authStateController.add(_currentUser);
    return _currentUser;
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
    _authStateController.add(_currentUser);
    return _currentUser;
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _currentUser = null;
    _authStateController.add(null);
  }

  @override
  Future<bool> deleteAccount() async {
    await Future.delayed(const Duration(milliseconds: 200));

    if (_currentUser == null) {
      throw Exception('ユーザーがログインしていません');
    }

    if (_shouldFailDelete) {
      throw FirebaseAuthException(
        code: 'requires-recent-login',
        message: 'セキュリティのため再認証が必要です。一度ログアウトして再度ログインした後に操作してください。',
      );
    }

    _currentUser = null;
    _authStateController.add(null);
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
    _authStateController.add(null);
    return true;
  }

  /// テスト用のリセット機能
  void reset() {
    _currentUser = null;
    _shouldFailLogin = false;
    _shouldFailSignUp = false;
    _shouldFailDelete = false;
    _authStateController.add(null);
  }

  /// リソースの解放
  void dispose() {
    _authStateController.close();
  }
}
