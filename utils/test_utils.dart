import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class TestUtils {
  /// 新規登録操作を実行するヘルパーメソッド
  static Future<void> performSignUp({
    required WidgetTester tester,
    String name = 'テストユーザー',
    String displayName = 'テストニックネーム',
    String email = 'test@example.com',
    String password = 'password123',
  }) async {
    // 名前フィールドの入力
    final nameField = find.byType(TextFormField).first;
    await tester.tap(nameField);
    await tester.pumpAndSettle();
    await tester.enterText(nameField, name);
    await tester.pumpAndSettle();

    // 表示名フィールドの入力（もし空でない場合）
    if (displayName.isNotEmpty) {
      final displayNameFields = find.byType(TextFormField);
      if (displayNameFields.evaluate().length > 1) {
        final displayNameField = displayNameFields.at(1);
        await tester.tap(displayNameField);
        await tester.pumpAndSettle();
        await tester.enterText(displayNameField, displayName);
        await tester.pumpAndSettle();
      }
    }

    // メールアドレスフィールドの入力
    final emailFields = find.byType(TextFormField);
    if (emailFields.evaluate().length > 2) {
      final emailField = emailFields.at(2);
      await tester.tap(emailField);
      await tester.pumpAndSettle();
      await tester.enterText(emailField, email);
      await tester.pumpAndSettle();
    }

    // パスワードフィールドの入力
    final passwordFields = find.byType(TextFormField);
    if (passwordFields.evaluate().length > 3) {
      final passwordField = passwordFields.at(3);
      await tester.tap(passwordField);
      await tester.pumpAndSettle();
      await tester.enterText(passwordField, password);
      await tester.pumpAndSettle();
    }

    // 新規登録ボタンをタップ
    final signUpButtons = find.text('新規登録');
    if (signUpButtons.evaluate().isNotEmpty) {
      await tester.tap(signUpButtons.first);
      await tester.pumpAndSettle();
    } else {
      // 代替的に送信ボタンを探す
      final submitButtons = find.byType(ElevatedButton);
      if (submitButtons.evaluate().isNotEmpty) {
        await tester.tap(submitButtons.first);
        await tester.pumpAndSettle();
      }
    }
  }

  /// スケジュール作成操作を実行するヘルパーメソッド
  static Future<void> createSchedule({
    required WidgetTester tester,
    String title = 'テストスケジュール',
    String description = 'テスト用の説明',
    String? location,
  }) async {
    // タイトルフィールドの入力
    final titleField = find.widgetWithText(TextFormField, 'タイトル');
    if (titleField.evaluate().isNotEmpty) {
      await tester.tap(titleField);
      await tester.pumpAndSettle();
      await tester.enterText(titleField, title);
      await tester.pumpAndSettle();
    }

    // 説明フィールドの入力
    final descriptionField = find.widgetWithText(TextFormField, '説明');
    if (descriptionField.evaluate().isNotEmpty) {
      await tester.tap(descriptionField);
      await tester.pumpAndSettle();
      await tester.enterText(descriptionField, description);
      await tester.pumpAndSettle();
    }

    // 場所フィールドの入力（指定されている場合）
    if (location != null) {
      final locationField = find.widgetWithText(TextFormField, '場所');
      if (locationField.evaluate().isNotEmpty) {
        await tester.tap(locationField);
        await tester.pumpAndSettle();
        await tester.enterText(locationField, location);
        await tester.pumpAndSettle();
      }
    }

    // 保存ボタンをタップ
    final saveButtons = find.text('保存');
    if (saveButtons.evaluate().isNotEmpty) {
      await tester.tap(saveButtons.first);
      await tester.pumpAndSettle();
    } else {
      // 代替的に作成ボタンを探す
      final createButtons = find.text('作成');
      if (createButtons.evaluate().isNotEmpty) {
        await tester.tap(createButtons.first);
        await tester.pumpAndSettle();
      } else {
        // 最後の手段として ElevatedButton を探す
        final submitButtons = find.byType(ElevatedButton);
        if (submitButtons.evaluate().isNotEmpty) {
          await tester.tap(submitButtons.last);
          await tester.pumpAndSettle();
        }
      }
    }
  }

  /// ログイン操作を実行するヘルパーメソッド
  static Future<void> performLogin({
    required WidgetTester tester,
    String email = 'test@example.com',
    String password = 'password123',
  }) async {
    // メールアドレスフィールドの入力
    final emailField = find.widgetWithText(TextField, 'メールアドレス');
    if (emailField.evaluate().isNotEmpty) {
      await tester.tap(emailField);
      await tester.pumpAndSettle();
      await tester.enterText(emailField, email);
      await tester.pumpAndSettle();
    }

    // パスワードフィールドの入力
    final passwordField = find.widgetWithText(TextField, 'パスワード');
    if (passwordField.evaluate().isNotEmpty) {
      await tester.tap(passwordField);
      await tester.pumpAndSettle();
      await tester.enterText(passwordField, password);
      await tester.pumpAndSettle();
    }

    // ログインボタンをタップ
    final loginButtons = find.text('ログイン');
    if (loginButtons.evaluate().isNotEmpty) {
      await tester.tap(loginButtons.first);
      await tester.pumpAndSettle();
    }
  }

  /// 画面の要素が表示されるまで待機するヘルパーメソッド
  static Future<void> waitForElement({
    required WidgetTester tester,
    required Finder finder,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final endTime = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(endTime)) {
      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      if (finder.evaluate().isNotEmpty) {
        return;
      }

      await Future.delayed(const Duration(milliseconds: 100));
    }

    throw TimeoutException('Element not found within timeout', timeout);
  }

  /// エラーメッセージが表示されているかチェックするヘルパーメソッド
  static bool hasErrorMessage(WidgetTester tester, String message) {
    final errorFinder = find.textContaining(message);
    return errorFinder.evaluate().isNotEmpty;
  }

  /// スナックバーメッセージが表示されているかチェックするヘルパーメソッド
  static bool hasSnackBarMessage(WidgetTester tester, String message) {
    final snackBarFinder = find.descendant(
      of: find.byType(SnackBar),
      matching: find.textContaining(message),
    );
    return snackBarFinder.evaluate().isNotEmpty;
  }
}

class TimeoutException implements Exception {
  final String message;
  final Duration timeout;

  TimeoutException(this.message, this.timeout);

  @override
  String toString() => 'TimeoutException: $message (timeout: $timeout)';
}
