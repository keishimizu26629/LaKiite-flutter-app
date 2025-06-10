import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lakiite/main.dart';
import 'package:lakiite/config/app_config.dart';

class TestUtils {
  /// 標準的なテストウィジェットのセットアップ
  static Widget createTestApp({
    required Widget child,
    List<Override> overrides = const [],
  }) {
    // テスト用のGoRouterを作成
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => child,
        ),
        GoRoute(
          path: '/signup',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('サインアップページ')),
          ),
        ),
        GoRoute(
          path: '/main',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('メインページ')),
          ),
        ),
      ],
    );

    return ProviderScope(
      overrides: overrides,
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  /// 統合テスト用のアプリセットアップ
  static Future<void> setupIntegrationTestApp({
    required WidgetTester tester,
    List<Override> overrides = const [],
  }) async {
    await startApp(Environment.development, overrides);
    await tester.pumpAndSettle();

    // スプラッシュ画面の待機
    await Future.delayed(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  }

  /// ログイン操作のヘルパー
  static Future<void> performLogin({
    required WidgetTester tester,
    String email = 'test@example.com',
    String password = 'password123',
  }) async {
    // メールアドレス入力
    final emailField = find.widgetWithText(TextField, 'メールアドレス');
    if (emailField.evaluate().isNotEmpty) {
      await tester.enterText(emailField, email);
    } else {
      // 別の方法でメールフィールドを探す
      final emailFieldByKey = find.byKey(const Key('email_field'));
      if (emailFieldByKey.evaluate().isNotEmpty) {
        await tester.enterText(emailFieldByKey, email);
      }
    }

    // パスワード入力
    final passwordField = find.widgetWithText(TextField, 'パスワード');
    if (passwordField.evaluate().isNotEmpty) {
      await tester.enterText(passwordField, password);
    } else {
      final passwordFieldByKey = find.byKey(const Key('password_field'));
      if (passwordFieldByKey.evaluate().isNotEmpty) {
        await tester.enterText(passwordFieldByKey, password);
      }
    }

    await tester.pumpAndSettle();

    // ログインボタンをタップ
    final loginButton = find.text('ログイン');
    if (loginButton.evaluate().isNotEmpty) {
      await tester.tap(loginButton);
    } else {
      final loginButtonByKey = find.byKey(const Key('login_button'));
      if (loginButtonByKey.evaluate().isNotEmpty) {
        await tester.tap(loginButtonByKey);
      }
    }

    await tester.pumpAndSettle();
  }

  /// サインアップ操作のヘルパー
  static Future<void> performSignUp({
    required WidgetTester tester,
    String name = 'テストユーザー',
    String email = 'test@example.com',
    String password = 'password123',
  }) async {
    // 名前入力
    final nameField = find.widgetWithText(TextField, '名前');
    if (nameField.evaluate().isNotEmpty) {
      await tester.enterText(nameField, name);
    } else {
      final nameFieldByKey = find.byKey(const Key('name_field'));
      if (nameFieldByKey.evaluate().isNotEmpty) {
        await tester.enterText(nameFieldByKey, name);
      }
    }

    // メールアドレス入力
    final emailField = find.widgetWithText(TextField, 'メールアドレス');
    if (emailField.evaluate().isNotEmpty) {
      await tester.enterText(emailField, email);
    } else {
      final emailFieldByKey = find.byKey(const Key('email_field'));
      if (emailFieldByKey.evaluate().isNotEmpty) {
        await tester.enterText(emailFieldByKey, email);
      }
    }

    // パスワード入力
    final passwordField = find.widgetWithText(TextField, 'パスワード');
    if (passwordField.evaluate().isNotEmpty) {
      await tester.enterText(passwordField, password);
    } else {
      final passwordFieldByKey = find.byKey(const Key('password_field'));
      if (passwordFieldByKey.evaluate().isNotEmpty) {
        await tester.enterText(passwordFieldByKey, password);
      }
    }

    await tester.pumpAndSettle();

    // サインアップボタンをタップ
    final signUpButton = find.text('登録');
    if (signUpButton.evaluate().isNotEmpty) {
      await tester.tap(signUpButton);
    } else {
      final signUpButtonByKey = find.byKey(const Key('signup_button'));
      if (signUpButtonByKey.evaluate().isNotEmpty) {
        await tester.tap(signUpButtonByKey);
      }
    }

    await tester.pumpAndSettle();
  }

  /// スケジュール作成操作のヘルパー
  static Future<void> createSchedule({
    required WidgetTester tester,
    String title = 'テストスケジュール',
    String description = 'テスト用の説明',
  }) async {
    // スケジュール作成ボタンをタップ
    final createButton = find.byIcon(Icons.add);
    if (createButton.evaluate().isNotEmpty) {
      await tester.tap(createButton);
      await tester.pumpAndSettle();
    }

    // タイトル入力
    final titleField = find.widgetWithText(TextField, 'タイトル');
    if (titleField.evaluate().isNotEmpty) {
      await tester.enterText(titleField, title);
    }

    // 説明入力
    final descriptionField = find.widgetWithText(TextField, '説明');
    if (descriptionField.evaluate().isNotEmpty) {
      await tester.enterText(descriptionField, description);
    }

    await tester.pumpAndSettle();

    // 保存ボタンをタップ
    final saveButton = find.text('保存');
    if (saveButton.evaluate().isNotEmpty) {
      await tester.tap(saveButton);
      await tester.pumpAndSettle();
    }
  }

  /// リスト作成操作のヘルパー
  static Future<void> createList({
    required WidgetTester tester,
    String listName = 'テストリスト',
    String description = 'テスト用のリスト',
  }) async {
    // リスト作成ボタンをタップ
    final createButton = find.text('新しいリスト');
    if (createButton.evaluate().isNotEmpty) {
      await tester.tap(createButton);
      await tester.pumpAndSettle();
    }

    // リスト名入力
    final nameField = find.widgetWithText(TextField, 'リスト名');
    if (nameField.evaluate().isNotEmpty) {
      await tester.enterText(nameField, listName);
    }

    // 説明入力
    final descriptionField = find.widgetWithText(TextField, '説明');
    if (descriptionField.evaluate().isNotEmpty) {
      await tester.enterText(descriptionField, description);
    }

    await tester.pumpAndSettle();

    // 作成ボタンをタップ
    final submitButton = find.text('作成');
    if (submitButton.evaluate().isNotEmpty) {
      await tester.tap(submitButton);
      await tester.pumpAndSettle();
    }
  }

  /// エラーメッセージの確認
  static void expectErrorMessage(String message) {
    expect(find.text(message), findsOneWidget);
  }

  /// 成功メッセージの確認
  static void expectSuccessMessage(String message) {
    expect(find.text(message), findsOneWidget);
  }

  /// ローディング状態の確認
  static void expectLoading() {
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  }

  /// ローディング状態の終了確認
  static void expectNotLoading() {
    expect(find.byType(CircularProgressIndicator), findsNothing);
  }

  /// 特定のテキストが表示されているかを確認
  static void expectText(String text) {
    expect(find.text(text), findsOneWidget);
  }

  /// 特定のウィジェットが表示されているかを確認
  static void expectWidget<T extends Widget>() {
    expect(find.byType(T), findsOneWidget);
  }
}
