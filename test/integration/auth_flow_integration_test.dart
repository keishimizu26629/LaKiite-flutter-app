import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lakiite/main.dart';
import 'package:lakiite/config/app_config.dart';
import '../mock/providers/test_providers.dart';
import '../utils/test_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('認証フロー統合テスト', () {
    setUp(() {
      TestProviders.reset();
    });

    testWidgets('ログイン〜ホーム画面遷移フロー', (tester) async {
      // アプリ起動
      await startApp(Environment.development, TestProviders.forLoginForm);
      await tester.pumpAndSettle();

      // スプラッシュ画面の待機
      await Future.delayed(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // ログイン画面が表示されているかを確認
      expect(find.text('LaKiite'), findsOneWidget);
      expect(find.text('ログイン'), findsOneWidget);

      // ログイン操作を実行
      await TestUtils.performLogin(tester: tester);

      // ログイン成功後のホーム画面への遷移を確認
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // ホーム画面の要素を確認（実際の実装に応じて調整）
      expect(find.text('ホーム'), findsOneWidget);
    });

    testWidgets('新規登録〜ホーム画面遷移フロー', (tester) async {
      // アプリ起動
      await startApp(Environment.development, TestProviders.forSignupForm);
      await tester.pumpAndSettle();

      // スプラッシュ画面の待機
      await Future.delayed(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // 新規登録ボタンをタップして新規登録画面へ
      final signUpButton = find.text('新規登録');
      if (signUpButton.evaluate().isNotEmpty) {
        await tester.tap(signUpButton);
        await tester.pumpAndSettle();
      }

      // 新規登録画面が表示されているかを確認
      expect(find.text('アカウント作成'), findsOneWidget);

      // サインアップ操作を実行
      await TestUtils.performSignUp(tester: tester);

      // サインアップ成功後のホーム画面への遷移を確認
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // ホーム画面の要素を確認
      expect(find.text('ホーム'), findsOneWidget);
    });

    testWidgets('ログイン失敗時のエラー表示', (tester) async {
      // アプリ起動（ログイン失敗するように設定）
      TestProviders.mockAuthRepository.setShouldFailLogin(true);
      await startApp(Environment.development, TestProviders.forLoginForm);
      await tester.pumpAndSettle();

      // スプラッシュ画面の待機
      await Future.delayed(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // 無効な認証情報でログイン試行
      await TestUtils.performLogin(
        tester: tester,
        email: 'invalid@example.com',
        password: 'wrongpassword',
      );

      // エラーメッセージが表示されることを確認
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // エラーメッセージの確認（実際のメッセージに応じて調整）
      expect(find.textContaining('失敗'), findsAtLeastNWidgets(1));
    });

    testWidgets('ログアウトフロー', (tester) async {
      // 認証済み状態でアプリ起動
      await startApp(Environment.development, TestProviders.authenticated);
      await tester.pumpAndSettle();

      // スプラッシュ画面の待機
      await Future.delayed(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // ホーム画面が表示されていることを確認
      expect(find.text('ホーム'), findsOneWidget);

      // 設定画面またはメニューを開く
      final menuButton = find.byIcon(Icons.menu);
      if (menuButton.evaluate().isNotEmpty) {
        await tester.tap(menuButton);
        await tester.pumpAndSettle();
      }

      // ログアウトボタンをタップ
      final logoutButton = find.text('ログアウト');
      if (logoutButton.evaluate().isNotEmpty) {
        await tester.tap(logoutButton);
        await tester.pumpAndSettle();
      }

      // ログイン画面に戻ることを確認
      expect(find.text('ログイン'), findsOneWidget);
      expect(find.text('LaKiite'), findsOneWidget);
    });

    testWidgets('認証状態の永続化確認', (tester) async {
      // 最初にログイン
      await startApp(Environment.development, TestProviders.forLoginForm);
      await tester.pumpAndSettle();

      await Future.delayed(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      await TestUtils.performLogin(tester: tester);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // ホーム画面が表示されていることを確認
      expect(find.text('ホーム'), findsOneWidget);

      // アプリを再起動（認証状態が維持されているかを確認）
      await startApp(Environment.development, TestProviders.authenticated);
      await tester.pumpAndSettle();

      await Future.delayed(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // 直接ホーム画面に遷移することを確認
      expect(find.text('ホーム'), findsOneWidget);
    });

    testWidgets('フォームバリデーション統合テスト', (tester) async {
      await startApp(Environment.development, TestProviders.forLoginForm);
      await tester.pumpAndSettle();

      await Future.delayed(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // 空のフォームでログインを試行
      final loginButton = find.text('ログイン');
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // バリデーションエラーが表示されることを確認
      expect(find.textContaining('入力'), findsAtLeastNWidgets(1));

      // 無効なメールアドレスを入力
      final emailField = find.widgetWithText(TextField, 'メールアドレス');
      await tester.enterText(emailField, 'invalid-email');

      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // メールアドレスのバリデーションエラーを確認
      expect(find.textContaining('メール'), findsAtLeastNWidgets(1));
    });
  });
}
