import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lakiite/main.dart' as app;
import 'package:lakiite/di/repository_providers.dart';
import 'firebase_test_utils.dart';
import 'mock_auth_repository.dart';
import 'package:lakiite/config/app_config.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('end-to-end test', () {
    setUp(() async {
      await FirebaseTestUtils.setupFirebaseForTesting();
    });

    tearDown(() async {
      await FirebaseTestUtils.cleanupFirebaseAfterTesting();
    });

    testWidgets('ログインフロー', (tester) async {
      // テスト用のプロバイダーオーバーライドを設定
      final overrides = [
        authRepositoryProvider.overrideWithValue(MockAuthRepository()),
      ];

      // アプリの起動（テスト用のオーバーライドを適用）
      await app.startApp(Environment.development, overrides);
      await tester.pumpAndSettle();

      // スプラッシュ画面の待機（必要に応じて時間を調整）
      await Future.delayed(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      // ログイン画面が表示されていることを確認
      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.text('メールアドレス'), findsOneWidget);
      expect(find.text('パスワード'), findsOneWidget);

      // メールアドレス入力
      await tester.enterText(
        find.widgetWithText(TextField, 'メールアドレス'),
        'test@example.com',
      );
      await tester.pumpAndSettle();

      // パスワード入力
      await tester.enterText(
        find.widgetWithText(TextField, 'パスワード'),
        'password123',
      );
      await tester.pumpAndSettle();

      // ログインボタンをタップ
      final loginButton = find.ancestor(
        of: find.text('ログイン'),
        matching: find.byType(ElevatedButton),
      );
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // ログイン処理の待機
      await Future.delayed(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // ホーム画面への遷移を確認
      expect(find.text('ホーム'), findsOneWidget);
    });
  });
}
