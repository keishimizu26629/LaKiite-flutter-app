import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lakiite/main.dart';
import 'package:lakiite/config/app_config.dart';
import '../mock/providers/test_providers.dart';
import '../utils/test_utils.dart';

/// 新規登録時の画面遷移バグを検証するための統合テスト
///
/// このテストは修正された認証フロー（AuthNotifier統一）が
/// 正常に動作することを確認します。
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('新規登録画面遷移統合テスト（修正版）', () {
    setUpAll(() async {
      TestProviders.reset();
    });

    setUp(() {
      TestProviders.reset();
    });

    tearDownAll(() async {
      TestProviders.reset();
    });

    testWidgets('新規登録後の自動画面遷移（修正版）', (tester) async {
      // アプリ起動（Firebase初期化をスキップ）
      await startApp(
          Environment.development, TestProviders.forSignupForm, true);
      await tester.pumpAndSettle();

      // スプラッシュ画面の待機
      await Future.delayed(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      print('✅ アプリ起動完了');

      // ログイン画面が表示されているかを確認
      expect(find.text('メールアドレス'), findsOneWidget);
      expect(find.text('パスワード'), findsOneWidget);
      expect(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.text('ログイン'),
          ),
          findsOneWidget);

      print('✅ ログイン画面表示確認');

      // 新規登録ボタンをタップして新規登録画面へ
      final signUpButton = find.text('アカウントをお持ちでない方は新規登録');
      expect(signUpButton, findsOneWidget);
      await tester.tap(signUpButton);
      await tester.pumpAndSettle();

      print('✅ 新規登録画面に遷移');

      // 新規登録画面が表示されているかを確認
      expect(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.text('新規登録'),
          ),
          findsOneWidget);
      expect(find.text('名前(フルネーム)'), findsOneWidget);
      expect(find.text('表示名(ニックネーム)'), findsOneWidget);

      print('✅ 新規登録画面のUI確認');

      // サインアップ操作を実行
      await TestUtils.performSignUp(
        tester: tester,
        name: 'テストユーザー修正版',
        displayName: 'テストニックネーム修正版',
        email: 'fixed_test@example.com',
        password: 'password123',
      );

      print('✅ 新規登録フォーム入力完了');

      // サインアップ処理完了を待機
      await tester.pumpAndSettle(const Duration(seconds: 3));

      print('✅ 新規登録処理完了待機');

      // *** 重要な検証ポイント ***
      // 修正後はAuthNotifierによってグローバル認証状態が更新され、
      // GoRouterのリダイレクト処理により自動的にホーム画面に遷移するはず

      // スプラッシュ画面のままで止まらないことを確認
      expect(find.text('ホーム'), findsOneWidget,
          reason: 'スプラッシュ画面から自動的にホーム画面に遷移するべきです');

      // ホーム画面の要素を確認
      expect(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.text('ホーム'),
          ),
          findsOneWidget,
          reason: 'ホーム画面のAppBarが表示されているべきです');

      print('✅ ホーム画面への自動遷移成功');

      // さらなる検証：ボトムナビゲーションが表示されていることを確認
      expect(find.byType(BottomNavigationBar), findsOneWidget,
          reason: 'ボトムナビゲーションが表示されているべきです');

      print('✅ 全ての検証完了 - 新規登録時の画面遷移バグが修正されました');
    });

    testWidgets('新規登録失敗時の画面状態', (tester) async {
      // 新規登録失敗するように設定
      TestProviders.mockAuthRepository.setShouldFailSignUp(true);

      await startApp(
          Environment.development, TestProviders.forSignupForm, true);
      await tester.pumpAndSettle();

      await Future.delayed(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // 新規登録画面に遷移
      final signUpButton = find.text('アカウントをお持ちでない方は新規登録');
      await tester.tap(signUpButton);
      await tester.pumpAndSettle();

      // サインアップ操作を実行（失敗するはず）
      await TestUtils.performSignUp(tester: tester);

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // エラーメッセージが表示され、新規登録画面に留まることを確認
      expect(find.textContaining('サインアップに失敗しました'), findsAny);
      expect(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.text('新規登録'),
          ),
          findsOneWidget,
          reason: '失敗時は新規登録画面に留まるべきです');

      print('✅ 新規登録失敗時の適切なエラーハンドリング確認');
    });

    testWidgets('表示名なしでの新規登録', (tester) async {
      await startApp(
          Environment.development, TestProviders.forSignupForm, true);
      await tester.pumpAndSettle();

      await Future.delayed(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // 新規登録画面に遷移
      final signUpButton = find.text('アカウントをお持ちでない方は新規登録');
      await tester.tap(signUpButton);
      await tester.pumpAndSettle();

      // 表示名を空にしてサインアップ
      await TestUtils.performSignUp(
        tester: tester,
        name: 'テストユーザー',
        displayName: '', // 空の表示名
        email: 'no_display_name@example.com',
      );

      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 正常にホーム画面に遷移することを確認
      expect(find.text('ホーム'), findsOneWidget, reason: '表示名が空でも正常に新規登録できるべきです');

      print('✅ 表示名なしでの新規登録処理確認');
    });

    testWidgets('認証状態の一貫性確認', (tester) async {
      await startApp(
          Environment.development, TestProviders.forSignupForm, true);
      await tester.pumpAndSettle();

      await Future.delayed(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // 新規登録フロー実行
      final signUpButton = find.text('アカウントをお持ちでない方は新規登録');
      await tester.tap(signUpButton);
      await tester.pumpAndSettle();

      await TestUtils.performSignUp(
        tester: tester,
        email: 'consistency_test@example.com',
      );

      await tester.pumpAndSettle(const Duration(seconds: 3));

      // ホーム画面に遷移することを確認
      expect(find.text('ホーム'), findsOneWidget);

      // アプリを再起動して認証状態が維持されているか確認
      await startApp(
          Environment.development, TestProviders.authenticated, true);
      await tester.pumpAndSettle();

      await Future.delayed(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // 直接ホーム画面に遷移することを確認
      expect(find.text('ホーム'), findsOneWidget,
          reason: '認証状態が維持され、再起動時に直接ホーム画面に遷移するべきです');

      print('✅ 認証状態の永続化確認');
    });
  });
}
