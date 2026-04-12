import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lakiite/config/admob_config.dart';
import 'package:lakiite/config/app_config.dart';
import 'package:lakiite/main.dart';

import '../../../mock/providers/test_providers.dart';
import '../../utils/test_utils.dart';

void main() {
  setUpAll(() async {
    AppConfig.initialize(Environment.development);
    AdMobConfig.initialize(forceTestMode: true);
    await initializeDateFormatting('ja_JP', null);
  });

  setUp(() {
    TestProviders.reset();
  });

  tearDown(() {
    TestProviders.reset();
  });

  testWidgets('ログイン成功後にカレンダー初期画面へ遷移する', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: TestProviders.forLoginForm,
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('ログイン'),
      ),
      findsOneWidget,
    );

    await TestUtils.performLogin(tester: tester);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 300));

    _expectCalendarInitialScreen();
    await _drainAsyncWork(tester);
  });

  testWidgets('新規登録成功後にカレンダー初期画面へ遷移する', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: TestProviders.forSignupForm,
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    final signupLink = find.text('アカウントをお持ちでない方は新規登録');
    expect(signupLink, findsOneWidget);

    await tester.tap(signupLink);
    await tester.pumpAndSettle();

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
      email: 'widget-signup@example.com',
      password: 'password123',
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 300));

    _expectCalendarInitialScreen();
    await _drainAsyncWork(tester);
  });

  testWidgets('ログアウト後にログイン画面へ戻る', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: TestProviders.authenticated,
        child: const MyApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 300));

    _expectCalendarInitialScreen();

    await tester.tap(find.text('マイページ'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('マイページ'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('設定'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(ListTile, 'ログアウト'));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.widgetWithText(TextButton, 'ログアウト'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('ログイン'),
      ),
      findsOneWidget,
    );
  });
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

Future<void> _drainAsyncWork(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 4));
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}
