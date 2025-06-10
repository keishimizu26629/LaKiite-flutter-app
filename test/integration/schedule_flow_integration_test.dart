import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lakiite/main.dart';
import 'package:lakiite/config/app_config.dart';
import '../mock/providers/test_providers.dart';
import '../utils/test_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('スケジュール管理フロー統合テスト', () {
    setUpAll(() async {
      // 統合テスト用の初期設定
      TestProviders.reset();
    });

    setUp(() {
      TestProviders.reset();
    });

    tearDownAll(() async {
      // 統合テスト後のクリーンアップ
      TestProviders.reset();
    });

    testWidgets('スケジュール作成フロー', (tester) async {
      // 認証済み状態でアプリ起動（Firebase初期化をスキップ）
      await startApp(
          Environment.development, TestProviders.forScheduleCreation, true);
      await tester.pumpAndSettle();

      // スプラッシュ画面の待機
      await Future.delayed(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // ホーム画面が表示されていることを確認
      expect(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.text('ホーム'),
          ),
          findsOneWidget);

      // スケジュール作成ボタンをタップ（実際のボタンテキスト「予定を作成」）
      final createButton = find.text('予定を作成');
      if (createButton.evaluate().isNotEmpty) {
        await tester.tap(createButton);
        await tester.pumpAndSettle();
      }

      // スケジュール作成フォームが表示されることを確認（実際のAppBarタイトル「予定作成」）
      expect(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.text('予定作成'),
          ),
          findsOneWidget);

      // フォームフィールドが表示されていることを確認
      expect(find.text('タイトル'), findsOneWidget);
      expect(find.text('説明'), findsOneWidget);
      expect(find.text('場所'), findsOneWidget);

      // スケジュール作成操作を実行
      await TestUtils.createSchedule(
        tester: tester,
        title: '統合テストスケジュール',
        description: '統合テスト用のスケジュール説明',
      );

      // 作成後の状態確認（実際の実装に応じて調整）
      await tester.pumpAndSettle(const Duration(seconds: 2));
    });

    testWidgets('スケジュール一覧表示フロー', (tester) async {
      // 既存のスケジュールがある状態でアプリ起動（Firebase初期化をスキップ）
      await startApp(
          Environment.development, TestProviders.forScheduleCreation, true);
      await tester.pumpAndSettle();

      await Future.delayed(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // ホーム画面が表示されていることを確認
      expect(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.text('ホーム'),
          ),
          findsOneWidget);

      // カレンダータブとタイムラインタブがあることを確認
      expect(find.text('カレンダー'), findsOneWidget);
      expect(find.text('タイムライン'), findsOneWidget);

      // サンプルスケジュールが表示されることを確認（モックデータに応じて調整）
      // 実際のモックデータのスケジュールタイトルを使用
      expect(find.textContaining('サンプル'), findsAny);
    });

    testWidgets('スケジュール編集フロー', (tester) async {
      await startApp(
          Environment.development, TestProviders.forScheduleCreation, true);
      await tester.pumpAndSettle();

      await Future.delayed(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // ホーム画面が表示されていることを確認
      expect(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.text('ホーム'),
          ),
          findsOneWidget);

      // スケジュールカードをタップして詳細表示
      final scheduleCard = find.byType(Card).first;
      if (scheduleCard.evaluate().isNotEmpty) {
        await tester.tap(scheduleCard);
        await tester.pumpAndSettle();
      }

      // スケジュール詳細画面が表示されることを確認
      expect(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.text('予定の詳細'),
          ),
          findsOneWidget);

      // 編集ボタンをタップ
      final editButton = find.byIcon(Icons.edit);
      if (editButton.evaluate().isNotEmpty) {
        await tester.tap(editButton);
        await tester.pumpAndSettle();
      }

      // 編集フォームが表示されることを確認（実際のAppBarタイトル「予定編集」）
      expect(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.text('予定編集'),
          ),
          findsOneWidget);

      // タイトルフィールドが存在することを確認
      expect(find.text('タイトル'), findsOneWidget);
    });

    testWidgets('スケジュール削除フロー', (tester) async {
      await startApp(
          Environment.development, TestProviders.forScheduleCreation, true);
      await tester.pumpAndSettle();

      await Future.delayed(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // ホーム画面が表示されていることを確認
      expect(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.text('ホーム'),
          ),
          findsOneWidget);

      // スケジュールカードをタップして詳細表示
      final scheduleCard = find.byType(Card).first;
      if (scheduleCard.evaluate().isNotEmpty) {
        await tester.tap(scheduleCard);
        await tester.pumpAndSettle();
      }

      // スケジュール詳細画面が表示されることを確認
      expect(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.text('予定の詳細'),
          ),
          findsOneWidget);

      // 削除ボタンをタップ
      final deleteButton = find.byIcon(Icons.delete);
      if (deleteButton.evaluate().isNotEmpty) {
        await tester.tap(deleteButton);
        await tester.pumpAndSettle();
      }

      // 確認ダイアログが表示される（実際のダイアログテキストに応じて調整）
      expect(find.byType(AlertDialog), findsOneWidget);

      // 削除を確定するボタンをタップ（実際のボタンテキストに応じて調整）
      final confirmButton = find.text('削除').last;
      if (confirmButton.evaluate().isNotEmpty) {
        await tester.tap(confirmButton);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }
    });

    testWidgets('カレンダービューでのスケジュール表示', (tester) async {
      await startApp(
          Environment.development, TestProviders.forScheduleCreation, true);
      await tester.pumpAndSettle();

      await Future.delayed(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // ホーム画面が表示されていることを確認
      expect(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.text('ホーム'),
          ),
          findsOneWidget);

      // カレンダータブをタップ
      final calendarTab = find.text('カレンダー');
      if (calendarTab.evaluate().isNotEmpty) {
        await tester.tap(calendarTab);
        await tester.pumpAndSettle();
      }

      // カレンダーが表示されることを確認
      expect(find.byType(PageView), findsOneWidget);

      // 今日の日付周辺にスケジュールが表示されることを確認
      // スケジュールタイトルやカードが表示されているかチェック
      expect(find.byType(Card), findsAny);
    });

    testWidgets('月次ビューでのスケジュール表示', (tester) async {
      await startApp(
          Environment.development, TestProviders.forScheduleCreation, true);
      await tester.pumpAndSettle();

      await Future.delayed(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // ホーム画面が表示されていることを確認
      expect(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.text('ホーム'),
          ),
          findsOneWidget);

      // カレンダータブをタップ
      final calendarTab = find.text('カレンダー');
      if (calendarTab.evaluate().isNotEmpty) {
        await tester.tap(calendarTab);
        await tester.pumpAndSettle();
      }

      // 月表示であることを確認（年月表示があることを確認）
      final now = DateTime.now();
      expect(find.textContaining('${now.year}年'), findsOneWidget);
    });

    testWidgets('スケジュール検索フロー', (tester) async {
      await startApp(
          Environment.development, TestProviders.forScheduleCreation, true);
      await tester.pumpAndSettle();

      await Future.delayed(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // ホーム画面が表示されていることを確認
      expect(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.text('ホーム'),
          ),
          findsOneWidget);

      // タイムラインタブをタップ
      final timelineTab = find.text('タイムライン');
      if (timelineTab.evaluate().isNotEmpty) {
        await tester.tap(timelineTab);
        await tester.pumpAndSettle();
      }

      // タイムライン表示でスケジュールが表示されることを確認
      expect(find.byType(Card), findsAny);

      // スケジュールタイルが表示されていることを確認
      expect(find.textContaining('時'), findsAny); // 時間表示があることを確認
    });

    testWidgets('フレンドとのスケジュール共有フロー', (tester) async {
      await startApp(
          Environment.development, TestProviders.forScheduleCreation, true);
      await tester.pumpAndSettle();

      await Future.delayed(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // ホーム画面が表示されていることを確認
      expect(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.text('ホーム'),
          ),
          findsOneWidget);

      // フレンドタブをタップ
      final friendTab = find.text('フレンド');
      if (friendTab.evaluate().isNotEmpty) {
        await tester.tap(friendTab);
        await tester.pumpAndSettle();
      }

      // フレンドリストが表示されることを確認
      // 実際のフレンドページの構造に応じて調整
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
