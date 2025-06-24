import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lakiite/application/auth/auth_notifier.dart' as notifier;
import 'package:lakiite/application/auth/auth_state.dart';
import 'package:lakiite/domain/entity/user.dart';
import 'package:riverpod/riverpod.dart';
import '../../mock/repository/mock_auth_repository.dart';
import '../../mock/providers/test_providers.dart';

/// テスト用のプロバイダーコンテナーを作成する関数
ProviderContainer createTestProviderContainer({
  List<Override>? overrides,
}) {
  return ProviderContainer(
    overrides: overrides ?? [],
  );
}

void main() {
  group('AuthNotifier - アカウント削除機能', () {
    late ProviderContainer container;
    late MockAuthRepository mockAuthRepository;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      container = createTestProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
        ],
      );
    });

    tearDown(() {
      container.dispose();
      mockAuthRepository.reset();
    });

    test('正常なアカウント削除処理', () async {
      // 準備: ユーザーがログイン済みの状態にする
      final testUser = MockAuthRepository.createTestUser(
        name: 'テストユーザー',
        displayName: 'テスト表示名',
      );
      mockAuthRepository.setCurrentUser(testUser);

      final authNotifier =
          container.read(notifier.authNotifierProvider.notifier);

      // 実行: アカウント削除を実行
      final result = await authNotifier.deleteAccount();

      // 検証
      expect(result, isTrue);

      // 認証状態が未認証になっていることを確認
      final state = container.read(notifier.authNotifierProvider);
      expect(state.hasValue, isTrue);
      expect(state.value?.isAuthenticated, isFalse);
    });

    test('再認証が必要な場合のエラーハンドリング', () async {
      // 準備: ユーザーがログイン済みだが、削除時に再認証が必要な状態
      final testUser = MockAuthRepository.createTestUser(
        name: 'テストユーザー',
        displayName: 'テスト表示名',
      );
      mockAuthRepository.setCurrentUser(testUser);
      mockAuthRepository.setShouldFailDelete(true);

      final authNotifier =
          container.read(notifier.authNotifierProvider.notifier);

      // 実行 & 検証: 適切な例外が投げられることを確認
      expect(
        () => authNotifier.deleteAccount(),
        throwsA(isA<FirebaseAuthException>()),
      );
    });

    test('未ログイン状態でのアカウント削除エラー', () async {
      // 準備: 未ログイン状態
      mockAuthRepository.setCurrentUser(null);

      final authNotifier =
          container.read(notifier.authNotifierProvider.notifier);

      // 実行 & 検証: 適切な例外が投げられることを確認
      expect(
        () => authNotifier.deleteAccount(),
        throwsA(isA<Exception>()),
      );
    });

    test('アカウント削除後の状態確認', () async {
      // 準備: ユーザーがログイン済みの状態
      final testUser = MockAuthRepository.createTestUser(
        name: 'テストユーザー',
        displayName: 'テスト表示名',
      );
      mockAuthRepository.setCurrentUser(testUser);

      final authNotifier =
          container.read(notifier.authNotifierProvider.notifier);

      // 実行: アカウント削除
      await authNotifier.deleteAccount();

      // 検証: 削除後の状態
      final stateAfter = container.read(notifier.authNotifierProvider);
      expect(stateAfter.hasValue, isTrue);
      expect(stateAfter.value?.isAuthenticated, isFalse);
      expect(stateAfter.value?.user, isNull);
    });
  });
}
