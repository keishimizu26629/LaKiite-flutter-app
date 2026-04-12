import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lakiite/config/app_config.dart';
import 'package:lakiite/main.dart';

import '../mock/providers/test_providers.dart';
import '../test/utils/test_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('認証フロー統合テスト', () {
    setUp(() {
      TestProviders.reset();
    });

    tearDown(() {
      TestProviders.reset();
    });

    testWidgets('ログイン成功後にカレンダー初期画面へ遷移する', (tester) async {
      await startApp(
        Environment.development,
        TestProviders.forLoginForm,
        true,
      );
      await _pumpUntilFound(
        tester,
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('ログイン'),
        ),
      );

      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('ログイン'),
        ),
        findsOneWidget,
      );

      await TestUtils.performLogin(tester: tester);

      await _pumpUntilCalendarInitialScreen(tester);

      _expectCalendarInitialScreen();
    });

    testWidgets('新規登録成功後にカレンダー初期画面へ遷移する', (tester) async {
      await startApp(
        Environment.development,
        TestProviders.forSignupForm,
        true,
      );
      await _pumpUntilFound(
        tester,
        find.text('アカウントをお持ちでない方は新規登録'),
      );

      final signupLink = find.text('アカウントをお持ちでない方は新規登録');
      expect(signupLink, findsOneWidget);

      await tester.tap(signupLink);
      await _pumpUntilFound(
        tester,
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('新規登録'),
        ),
      );

      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('新規登録'),
        ),
        findsOneWidget,
      );

      await TestUtils.performSignUp(
        tester: tester,
        name: '統合テストユーザー',
        displayName: '統合テスト表示名',
        email: 'integration-signup@example.com',
        password: 'password123',
      );

      await _pumpUntilCalendarInitialScreen(tester);

      _expectCalendarInitialScreen();
    });
  });
}

Future<void> _pumpUntilCalendarInitialScreen(WidgetTester tester) async {
  await _pumpUntil(
    tester,
    () =>
        find.text('カレンダー').evaluate().isNotEmpty &&
        find.text('タイムライン').evaluate().isNotEmpty &&
        find
            .descendant(
              of: find.byType(AppBar),
              matching: find.text('ホーム'),
            )
            .evaluate()
            .isNotEmpty,
  );
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  await _pumpUntil(
    tester,
    () => finder.evaluate().isNotEmpty,
    timeout: timeout,
  );
}

Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() predicate, {
  Duration step = const Duration(milliseconds: 100),
  Duration timeout = const Duration(seconds: 10),
}) async {
  final endAt = DateTime.now().add(timeout);

  while (DateTime.now().isBefore(endAt)) {
    await tester.pump(step);
    if (predicate()) {
      return;
    }
  }

  fail('timeout waiting for expected UI');
}

void _expectCalendarInitialScreen() {
  expect(find.text('カレンダー'), findsOneWidget);
  expect(find.text('タイムライン'), findsOneWidget);
  expect(
    find.descendant(
      of: find.byType(AppBar),
      matching: find.text('ホーム'),
    ),
    findsOneWidget,
  );
}
