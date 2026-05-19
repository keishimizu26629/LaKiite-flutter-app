import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:lakiite/infrastructure/auth_repository.dart';
import 'package:lakiite/domain/interfaces/i_user_repository.dart';
import 'package:lakiite/domain/entity/user.dart' as domain;
import 'package:lakiite/domain/value/user_id.dart';

class MockUser implements firebase_auth.User {
  @override
  String get uid => 'test-user-id';

  @override
  String? get email => 'test@example.com';

  @override
  Future<void> delete() async {
    // モック実装 - 何もしない
  }

  @override
  Future<firebase_auth.UserCredential> reauthenticateWithCredential(
      firebase_auth.AuthCredential credential) async {
    // モック実装 - 正常に完了したと仮定
    return MockUserCredential(this);
  }

  // 他のすべての未実装メソッドをnoSuchMethodで処理
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockUserCredential implements firebase_auth.UserCredential {
  MockUserCredential(this.mockUser);
  final firebase_auth.User mockUser;

  @override
  firebase_auth.User? get user => mockUser;

  // 他のすべての未実装メソッドをnoSuchMethodで処理
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockFirebaseAuth implements firebase_auth.FirebaseAuth {
  firebase_auth.User? _currentUser;
  firebase_auth.FirebaseAuthException? _signInException;
  firebase_auth.FirebaseAuthException? _signUpException;
  bool didSignOut = false;

  @override
  firebase_auth.User? get currentUser => _currentUser;

  void setCurrentUser(firebase_auth.User? user) {
    _currentUser = user;
  }

  void setSignInException(firebase_auth.FirebaseAuthException exception) {
    _signInException = exception;
  }

  void setSignUpException(firebase_auth.FirebaseAuthException exception) {
    _signUpException = exception;
  }

  @override
  Future<firebase_auth.UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final exception = _signInException;
    if (exception != null) {
      throw exception;
    }
    return MockUserCredential(MockUser());
  }

  @override
  Future<firebase_auth.UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final exception = _signUpException;
    if (exception != null) {
      throw exception;
    }
    return MockUserCredential(MockUser());
  }

  @override
  Future<void> signOut() async {
    didSignOut = true;
    _currentUser = null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockUserRepository implements IUserRepository {
  @override
  Future<void> deleteUser(String id) async {
    // ユーザー削除のシミュレーション
  }

  @override
  Future<domain.UserModel?> getUser(String id) async {
    throw UnimplementedError('テストでは使用しません');
  }

  @override
  Future<void> createUser(domain.UserModel user) async {
    throw UnimplementedError('テストでは使用しません');
  }

  @override
  Future<void> updateUser(domain.UserModel user) async {
    throw UnimplementedError('テストでは使用しません');
  }

  Future<List<domain.UserModel>> getUsers(List<String> userIds) async {
    throw UnimplementedError('テストでは使用しません');
  }

  Future<List<domain.UserModel>> searchUsersByName(String query) async {
    throw UnimplementedError('テストでは使用しません');
  }

  Future<domain.UserModel?> getUserBySearchId(String searchId) async {
    throw UnimplementedError('テストでは使用しません');
  }

  Future<List<domain.UserModel>> getFriends(String userId) async {
    throw UnimplementedError('テストでは使用しません');
  }

  @override
  Future<String?> uploadUserIcon(String userId, Uint8List imageBytes) async {
    throw UnimplementedError('テストでは使用しません');
  }

  @override
  Future<domain.PublicUserModel?> getFriendPublicProfile(String id) async {
    throw UnimplementedError('テストでは使用しません');
  }

  @override
  Future<domain.SearchUserModel?> findByUserId(UserId userId) async {
    throw UnimplementedError('テストでは使用しません');
  }

  @override
  Future<bool> isUserIdUnique(UserId userId) async {
    throw UnimplementedError('テストでは使用しません');
  }

  @override
  Stream<domain.PublicUserModel?> watchPublicProfile(String id) {
    throw UnimplementedError('テストでは使用しません');
  }

  @override
  Stream<domain.PrivateUserModel?> watchPrivateProfile(String id) {
    throw UnimplementedError('テストでは使用しません');
  }

  @override
  Stream<domain.UserModel?> watchUser(String id) {
    throw UnimplementedError('テストでは使用しません');
  }

  @override
  Future<domain.SearchUserModel?> findBySearchId(String searchId) async {
    throw UnimplementedError('テストでは使用しません');
  }

  @override
  Future<void> addToList(String userId, String memberId) async {
    throw UnimplementedError('テストでは使用しません');
  }

  @override
  Future<void> removeFromList(String userId, String memberId) async {
    throw UnimplementedError('テストでは使用しません');
  }

  @override
  Future<List<domain.PublicUserModel>> getPublicProfiles(
      List<String> userIds) async {
    throw UnimplementedError('テストでは使用しません');
  }

  @override
  Future<void> deleteUserIcon(String userId) async {
    throw UnimplementedError('テストでは使用しません');
  }
}

void main() {
  group('AuthRepository - ログインエラー', () {
    late AuthRepository authRepository;
    late MockFirebaseAuth mockFirebaseAuth;
    late MockUserRepository mockUserRepository;

    setUp(() {
      mockFirebaseAuth = MockFirebaseAuth();
      mockUserRepository = MockUserRepository();
      authRepository = AuthRepository(mockFirebaseAuth, mockUserRepository);
    });

    test('invalid-credential はパスワード誤りとしてユーザー向け文言に変換する', () async {
      mockFirebaseAuth.setSignInException(
        firebase_auth.FirebaseAuthException(
          code: 'invalid-credential',
          message:
              'The supplied auth credential is incorrect, malformed or has expired.',
        ),
      );

      await expectLater(
        authRepository.signIn('test@example.com', 'wrong-password'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          allOf(
            contains('パスワードが間違っています'),
            isNot(contains('Firebase')),
            isNot(contains('auth credential')),
          ),
        )),
      );
      expect(mockFirebaseAuth.didSignOut, isTrue);
    });

    test('invalid-email はメールアドレス形式のエラーとしてユーザー向け文言に変換する', () async {
      mockFirebaseAuth.setSignInException(
        firebase_auth.FirebaseAuthException(
          code: 'invalid-email',
          message: 'The email address is badly formatted.',
        ),
      );

      await expectLater(
        authRepository.signIn('invalid-email', 'password123'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          allOf(
            contains('メールアドレスの形式が正しくありません'),
            isNot(contains('Firebase')),
            isNot(contains('badly formatted')),
          ),
        )),
      );
      expect(mockFirebaseAuth.didSignOut, isTrue);
    });
  });

  group('AuthRepository - サインアップエラー', () {
    late AuthRepository authRepository;
    late MockFirebaseAuth mockFirebaseAuth;
    late MockUserRepository mockUserRepository;

    setUp(() {
      mockFirebaseAuth = MockFirebaseAuth();
      mockUserRepository = MockUserRepository();
      authRepository = AuthRepository(mockFirebaseAuth, mockUserRepository);
    });

    test('email-already-in-use はユーザー向け文言に変換する', () async {
      mockFirebaseAuth.setSignUpException(
        firebase_auth.FirebaseAuthException(
          code: 'email-already-in-use',
          message: 'The email address is already in use by another account.',
        ),
      );

      await expectLater(
        authRepository.signUp('test@example.com', 'password123', 'テストユーザー'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          allOf(
            contains('このメールアドレスは既に使用されています'),
            isNot(contains('Firebase')),
            isNot(contains('already in use')),
          ),
        )),
      );
    });
  });

  group('AuthRepository - アカウント削除機能', () {
    late AuthRepository authRepository;
    late MockFirebaseAuth mockFirebaseAuth;
    late MockUserRepository mockUserRepository;

    setUp(() {
      mockFirebaseAuth = MockFirebaseAuth();
      mockUserRepository = MockUserRepository();
      authRepository = AuthRepository(mockFirebaseAuth, mockUserRepository);
    });

    test('正常なアカウント削除処理', () async {
      // 準備: ログイン済みユーザーを設定
      final mockUser = MockUser();
      mockFirebaseAuth.setCurrentUser(mockUser);

      // 実行: アカウント削除
      final result = await authRepository.deleteAccount();

      // 検証
      expect(result, isTrue);
    });

    test('未ログイン状態でのアカウント削除エラー', () async {
      // 準備: 未ログイン状態に設定
      mockFirebaseAuth.setCurrentUser(null);

      // 実行 & 検証: 適切な例外が投げられることを確認
      expect(
        () => authRepository.deleteAccount(),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('ユーザーがログインしていません'),
        )),
      );
    });

    test('再認証が必要な場合のエラーハンドリング', () async {
      // 準備: 再認証が必要なユーザーを設定
      final mockUser = MockUserWithReauthError();
      mockFirebaseAuth.setCurrentUser(mockUser);

      // 実行 & 検証: 適切な例外が投げられることを確認
      expect(
        () => authRepository.deleteAccount(),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('セキュリティのため再認証が必要です'),
        )),
      );
    });

    test('再認証機能の正常動作', () async {
      // 準備: ログイン済みユーザーを設定
      final mockUser = MockUser();
      mockFirebaseAuth.setCurrentUser(mockUser);

      // 実行: 再認証
      final result =
          await authRepository.reauthenticateWithPassword('password123');

      // 検証
      expect(result, isTrue);
    });

    test('再認証機能のエラーハンドリング - 未ログイン状態', () async {
      // 準備: 未ログイン状態に設定
      mockFirebaseAuth.setCurrentUser(null);

      // 実行 & 検証: 適切な例外が投げられることを確認
      expect(
        () => authRepository.reauthenticateWithPassword('password123'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('ユーザーがログインしていません'),
        )),
      );
    });

    test('再認証付きアカウント削除の正常動作', () async {
      // 準備: ログイン済みユーザーを設定
      final mockUser = MockUser();
      mockFirebaseAuth.setCurrentUser(mockUser);

      // 実行: 再認証付きアカウント削除
      final result =
          await authRepository.deleteAccountWithReauth('password123');

      // 検証
      expect(result, isTrue);
    });

    test('再認証付きアカウント削除のエラーハンドリング - 未ログイン状態', () async {
      // 準備: 未ログイン状態に設定
      mockFirebaseAuth.setCurrentUser(null);

      // 実行 & 検証: 適切な例外が投げられることを確認
      expect(
        () => authRepository.deleteAccountWithReauth('password123'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('ユーザーがログインしていません'),
        )),
      );
    });
  });
}

class MockUserWithReauthError implements firebase_auth.User {
  @override
  String get uid => 'test-user-id';

  @override
  String? get email => 'test@example.com';

  @override
  Future<void> delete() async {
    throw firebase_auth.FirebaseAuthException(
      code: 'requires-recent-login',
      message: '再認証が必要です',
    );
  }

  @override
  Future<firebase_auth.UserCredential> reauthenticateWithCredential(
      firebase_auth.AuthCredential credential) async {
    throw firebase_auth.FirebaseAuthException(
      code: 'requires-recent-login',
      message: 'セキュリティのため再認証が必要です。',
    );
  }

  // 他のすべての未実装メソッドをnoSuchMethodで処理
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
