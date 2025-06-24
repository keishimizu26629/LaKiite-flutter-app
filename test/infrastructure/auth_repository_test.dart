import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lakiite/infrastructure/auth_repository.dart';
import 'package:lakiite/domain/interfaces/i_user_repository.dart';
import 'package:lakiite/domain/entity/user.dart';

class MockUser extends Mock implements User {
  @override
  String uid = 'test-user-id';

  @override
  Future<void> delete() async {
    // 正常削除のシミュレーション
  }
}

class MockFirebaseAuth extends Mock implements FirebaseAuth {
  User? _currentUser;

  @override
  User? get currentUser => _currentUser;

  void setCurrentUser(User? user) {
    _currentUser = user;
  }
}

class MockUserRepository extends Mock implements IUserRepository {
  @override
  Future<void> deleteUser(String id) async {
    // ユーザー削除のシミュレーション
  }

  @override
  Future<UserModel?> getUser(String id) async {
    throw UnimplementedError('テストでは使用しません');
  }

  @override
  Future<void> createUser(UserModel user) async {
    throw UnimplementedError('テストでは使用しません');
  }

  @override
  Future<void> updateUser(UserModel user) async {
    throw UnimplementedError('テストでは使用しません');
  }

  @override
  Future<List<UserModel>> getUsers(List<String> userIds) async {
    throw UnimplementedError('テストでは使用しません');
  }

  @override
  Future<List<UserModel>> searchUsersByName(String query) async {
    throw UnimplementedError('テストでは使用しません');
  }

  @override
  Future<UserModel?> getUserBySearchId(String searchId) async {
    throw UnimplementedError('テストでは使用しません');
  }

  @override
  Future<List<UserModel>> getFriends(String userId) async {
    throw UnimplementedError('テストでは使用しません');
  }

  @override
  Future<String?> uploadUserIcon(String userId, Uint8List imageBytes) async {
    throw UnimplementedError('テストでは使用しません');
  }
}

class Mock {
  // モック用のベースクラス
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
  });
}

class MockUserWithReauthError extends Mock implements User {
  @override
  String uid = 'test-user-id';

  @override
  Future<void> delete() async {
    throw FirebaseAuthException(
      code: 'requires-recent-login',
      message: '再認証が必要です',
    );
  }
}
