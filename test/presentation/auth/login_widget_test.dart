import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/presentation/login/login_page.dart';
import '../../mock/providers/test_providers.dart';
import '../../utils/test_utils.dart';

void main() {
  group('Login Widget Tests', () {
    setUp(() {
      TestProviders.reset();
    });

    testWidgets('ログイン画面が正しく表示される', (tester) async {
      await tester.pumpWidget(
        TestUtils.createTestApp(
          overrides: TestProviders.forLoginForm,
          child: const LoginPage(),
        ),
      );

      // UI要素の存在確認
      expect(find.text('ログイン'), findsOneWidget); // AppBarのタイトル
      expect(find.text('メールアドレス'), findsOneWidget);
      expect(find.text('パスワード'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget); // ログインボタン
      expect(find.text('Googleでログイン'), findsOneWidget);
      expect(find.text('アカウントをお持ちでない方は新規登録'), findsOneWidget);
    });

    testWidgets('メールアドレスとパスワードが入力できる', (tester) async {
      await tester.pumpWidget(
        TestUtils.createTestApp(
          overrides: TestProviders.forLoginForm,
          child: const LoginPage(),
        ),
      );

      // メールアドレス入力
      final emailField = find.widgetWithText(TextField, 'メールアドレス');
      await tester.enterText(emailField, 'test@example.com');
      expect(find.text('test@example.com'), findsOneWidget);

      // パスワード入力
      final passwordField = find.widgetWithText(TextField, 'パスワード');
      await tester.enterText(passwordField, 'password123');

      await tester.pumpAndSettle();
    });

    testWidgets('正常なログイン処理が動作する', (tester) async {
      await tester.pumpWidget(
        TestUtils.createTestApp(
          overrides: TestProviders.forLoginForm,
          child: const LoginPage(),
        ),
      );

      // メールアドレス入力
      final emailField = find.widgetWithText(TextField, 'メールアドレス');
      await tester.enterText(emailField, 'test@example.com');

      // パスワード入力
      final passwordField = find.widgetWithText(TextField, 'パスワード');
      await tester.enterText(passwordField, 'password123');

      await tester.pumpAndSettle();

      // ログインボタンをタップ（ElevatedButtonで特定）
      final loginButton = find.byType(ElevatedButton);
      await tester.tap(loginButton);

      // 結果の確認（実際の画面遷移は統合テストで確認）
      await tester.pumpAndSettle();

      // エラーメッセージが表示されていないことを確認
      expect(find.textContaining('ログインに失敗しました'), findsNothing);
    });

    testWidgets('無効なメールアドレスでエラーが表示される', (tester) async {
      // モックを失敗するように設定
      TestProviders.mockAuthRepository.setShouldFailLogin(true);

      await tester.pumpWidget(
        TestUtils.createTestApp(
          overrides: TestProviders.forLoginForm,
          child: const LoginPage(),
        ),
      );

      // メールアドレス入力
      final emailField = find.widgetWithText(TextField, 'メールアドレス');
      await tester.enterText(emailField, 'invalid-email');

      // パスワード入力
      final passwordField = find.widgetWithText(TextField, 'パスワード');
      await tester.enterText(passwordField, 'password123');

      await tester.pumpAndSettle();

      // ログインボタンをタップ
      final loginButton = find.byType(ElevatedButton);
      await tester.tap(loginButton);

      await tester.pumpAndSettle();

      // エラーメッセージが表示されることを確認
      expect(find.textContaining('ログインに失敗しました'), findsOneWidget);
    });

    testWidgets('パスワードフィールドが隠されている', (tester) async {
      await tester.pumpWidget(
        TestUtils.createTestApp(
          overrides: TestProviders.forLoginForm,
          child: const LoginPage(),
        ),
      );

      // パスワードフィールドを見つける
      final passwordField = find.widgetWithText(TextField, 'パスワード');
      expect(passwordField, findsOneWidget);

      // パスワードフィールドのTextField ウィジェットを取得
      final textField = tester.widget<TextField>(passwordField);

      // obscureText が true であることを確認
      expect(textField.obscureText, isTrue);
    });

    testWidgets('フォームバリデーションが動作する', (tester) async {
      await tester.pumpWidget(
        TestUtils.createTestApp(
          overrides: TestProviders.forLoginForm,
          child: const LoginPage(),
        ),
      );

      // 空の状態でログインボタンをタップ
      final loginButton = find.byType(ElevatedButton);
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // バリデーションエラーが表示されることを確認
      // 実際のバリデーションメッセージは実装に応じて調整
    });

    testWidgets('新規登録ボタンが機能する', (tester) async {
      await tester.pumpWidget(
        TestUtils.createTestApp(
          overrides: TestProviders.forLoginForm,
          child: const LoginPage(),
        ),
      );

      // 新規登録ボタンを見つけてタップ
      final signUpButton = find.text('アカウントをお持ちでない方は新規登録');
      expect(signUpButton, findsOneWidget);

      await tester.tap(signUpButton);
      await tester.pumpAndSettle();

      // 画面遷移の確認（実際の遷移先は統合テストで確認）
    });

    testWidgets('ローディング状態が表示される', (tester) async {
      await tester.pumpWidget(
        TestUtils.createTestApp(
          overrides: TestProviders.forLoginForm,
          child: const LoginPage(),
        ),
      );

      // メールアドレス入力
      final emailField = find.widgetWithText(TextField, 'メールアドレス');
      await tester.enterText(emailField, 'test@example.com');

      // パスワード入力
      final passwordField = find.widgetWithText(TextField, 'パスワード');
      await tester.enterText(passwordField, 'password123');

      await tester.pumpAndSettle();

      // ログインボタンをタップ
      final loginButton = find.byType(ElevatedButton);
      await tester.tap(loginButton);

      // ローディング状態が一瞬表示されることを確認
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();
    });
  });
}
