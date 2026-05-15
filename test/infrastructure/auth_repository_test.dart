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

  @override
  firebase_auth.User? get currentUser => _currentUser;

  void setCurrentUser(firebase_auth.User? user) {
    _currentUser = user;
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
