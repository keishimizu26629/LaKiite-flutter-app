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
    setUp(() {
      TestProviders.reset();
    });

    testWidgets('スケジュール作成フロー', (tester) async {
      // 認証済み状態でアプリ起動
      await startApp(
          Environment.development, TestProviders.forScheduleCreation);
      await tester.pumpAndSettle();

      // スプラッシュ画面の待機
      await Future.delayed(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // ホーム画面からスケジュール画面に移動
      final scheduleTab = find.text('スケジュール');
      if (scheduleTab.evaluate().isNotEmpty) {
        await tester.tap(scheduleTab);
        await tester.pumpAndSettle();
      }

      // スケジュール作成ボタンをタップ
      final createButton = find.byIcon(Icons.add);
      if (createButton.evaluate().isNotEmpty) {
        await tester.tap(createButton);
        await tester.pumpAndSettle();
      }

      // スケジュール作成フォームが表示されることを確認
      expect(find.text('スケジュール作成'), findsOneWidget);

      // スケジュール作成操作を実行
      await TestUtils.createSchedule(
        tester: tester,
        title: '統合テストスケジュール',
        description: '統合テスト用のスケジュール説明',
      );

      // スケジュールが作成され、リストに表示されることを確認
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.text('統合テストスケジュール'), findsAtLeastNWidgets(1));
    });

    testWidgets('スケジュール一覧表示フロー', (tester) async {
      // 既存のスケジュールがある状態でアプリ起動
      await startApp(
          Environment.development, TestProviders.forScheduleCreation);
      await tester.pumpAndSettle();

      await Future.delayed(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // スケジュール画面に移動
      final scheduleTab = find.text('スケジュール');
      if (scheduleTab.evaluate().isNotEmpty) {
        await tester.tap(scheduleTab);
        await tester.pumpAndSettle();
      }

      // サンプルスケジュールが表示されることを確認
      expect(find.text('既存のサンプルスケジュール'), findsOneWidget);
      expect(find.text('テスト用の既存スケジュール'), findsOneWidget);

      // スケジュールカードをタップして詳細表示
      final scheduleCard = find.text('既存のサンプルスケジュール');
      await tester.tap(scheduleCard);
      await tester.pumpAndSettle();

      // スケジュール詳細画面が表示されることを確認
      expect(find.text('スケジュール詳細'), findsOneWidget);
    });

    testWidgets('スケジュール編集フロー', (tester) async {
      await startApp(
          Environment.development, TestProviders.forScheduleCreation);
      await tester.pumpAndSettle();

      await Future.delayed(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // スケジュール画面に移動
      final scheduleTab = find.text('スケジュール');
      if (scheduleTab.evaluate().isNotEmpty) {
        await tester.tap(scheduleTab);
        await tester.pumpAndSettle();
      }

      // 既存のスケジュールをタップ
      final scheduleCard = find.text('既存のサンプルスケジュール');
      await tester.tap(scheduleCard);
      await tester.pumpAndSettle();

      // 編集ボタンをタップ
      final editButton = find.byIcon(Icons.edit);
      if (editButton.evaluate().isNotEmpty) {
        await tester.tap(editButton);
        await tester.pumpAndSettle();
      }

      // 編集フォームが表示されることを確認
      expect(find.text('スケジュール編集'), findsOneWidget);

      // タイトルを変更
      final titleField = find.widgetWithText(TextField, 'タイトル');
      await tester.enterText(titleField, '更新されたスケジュール');

      // 保存ボタンをタップ
      final saveButton = find.text('保存');
      await tester.tap(saveButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 更新されたタイトルが表示されることを確認
      expect(find.text('更新されたスケジュール'), findsOneWidget);
    });

    testWidgets('スケジュール削除フロー', (tester) async {
      await startApp(
          Environment.development, TestProviders.forScheduleCreation);
      await tester.pumpAndSettle();

      await Future.delayed(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // スケジュール画面に移動
      final scheduleTab = find.text('スケジュール');
      if (scheduleTab.evaluate().isNotEmpty) {
        await tester.tap(scheduleTab);
        await tester.pumpAndSettle();
      }

      // 削除前のスケジュール存在確認
      expect(find.text('既存のサンプルスケジュール'), findsOneWidget);

      // スケジュールをタップして詳細表示
      final scheduleCard = find.text('既存のサンプルスケジュール');
      await tester.tap(scheduleCard);
      await tester.pumpAndSettle();

      // 削除ボタンをタップ
      final deleteButton = find.byIcon(Icons.delete);
      if (deleteButton.evaluate().isNotEmpty) {
        await tester.tap(deleteButton);
        await tester.pumpAndSettle();
      }

      // 確認ダイアログが表示される
      expect(find.text('削除確認'), findsOneWidget);

      // 削除を確定
      final confirmButton = find.text('削除');
      await tester.tap(confirmButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // スケジュールが削除されていることを確認
      expect(find.text('既存のサンプルスケジュール'), findsNothing);
    });

    testWidgets('カレンダービューでのスケジュール表示', (tester) async {
      await startApp(
          Environment.development, TestProviders.forScheduleCreation);
      await tester.pumpAndSettle();

      await Future.delayed(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // カレンダー画面に移動
      final calendarTab = find.text('カレンダー');
      if (calendarTab.evaluate().isNotEmpty) {
        await tester.tap(calendarTab);
        await tester.pumpAndSettle();
      }

      // カレンダーが表示されることを確認
      expect(find.byType(GridView), findsOneWidget);

      // 今日の日付をタップ
      final today = DateTime.now().day.toString();
      final todayCell = find.text(today);
      if (todayCell.evaluate().isNotEmpty) {
        await tester.tap(todayCell);
        await tester.pumpAndSettle();
      }

      // その日のスケジュールが表示されることを確認
      // 実際の実装に応じて調整
    });

    testWidgets('月次ビューでのスケジュール表示', (tester) async {
      await startApp(
          Environment.development, TestProviders.forScheduleCreation);
      await tester.pumpAndSettle();

      await Future.delayed(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // カレンダー画面に移動
      final calendarTab = find.text('カレンダー');
      if (calendarTab.evaluate().isNotEmpty) {
        await tester.tap(calendarTab);
        await tester.pumpAndSettle();
      }

      // 月次ビューボタンをタップ
      final monthViewButton = find.text('月');
      if (monthViewButton.evaluate().isNotEmpty) {
        await tester.tap(monthViewButton);
        await tester.pumpAndSettle();
      }

      // 月次カレンダーが表示されることを確認
      expect(find.byType(GridView), findsOneWidget);

      // 次の月に移動
      final nextMonthButton = find.byIcon(Icons.arrow_forward);
      if (nextMonthButton.evaluate().isNotEmpty) {
        await tester.tap(nextMonthButton);
        await tester.pumpAndSettle();
      }

      // 前の月に戻る
      final prevMonthButton = find.byIcon(Icons.arrow_back);
      if (prevMonthButton.evaluate().isNotEmpty) {
        await tester.tap(prevMonthButton);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('スケジュール検索フロー', (tester) async {
      await startApp(
          Environment.development, TestProviders.forScheduleCreation);
      await tester.pumpAndSettle();

      await Future.delayed(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // スケジュール画面に移動
      final scheduleTab = find.text('スケジュール');
      if (scheduleTab.evaluate().isNotEmpty) {
        await tester.tap(scheduleTab);
        await tester.pumpAndSettle();
      }

      // 検索ボタンをタップ
      final searchButton = find.byIcon(Icons.search);
      if (searchButton.evaluate().isNotEmpty) {
        await tester.tap(searchButton);
        await tester.pumpAndSettle();
      }

      // 検索フィールドに文字を入力
      final searchField = find.widgetWithText(TextField, '検索');
      if (searchField.evaluate().isNotEmpty) {
        await tester.enterText(searchField, 'サンプル');
        await tester.pumpAndSettle();
      }

      // 検索結果が表示されることを確認
      expect(find.text('既存のサンプルスケジュール'), findsOneWidget);

      // 検索をクリア
      final clearButton = find.byIcon(Icons.clear);
      if (clearButton.evaluate().isNotEmpty) {
        await tester.tap(clearButton);
        await tester.pumpAndSettle();
      }

      // 全てのスケジュールが再表示されることを確認
      expect(find.text('既存のサンプルスケジュール'), findsOneWidget);
    });

    testWidgets('スケジュール作成エラーハンドリング', (tester) async {
      // 保存が失敗するように設定
      TestProviders.mockScheduleRepository.setShouldFailSave(true);

      await startApp(
          Environment.development, TestProviders.forScheduleCreation);
      await tester.pumpAndSettle();

      await Future.delayed(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // スケジュール画面に移動
      final scheduleTab = find.text('スケジュール');
      if (scheduleTab.evaluate().isNotEmpty) {
        await tester.tap(scheduleTab);
        await tester.pumpAndSettle();
      }

      // スケジュール作成ボタンをタップ
      final createButton = find.byIcon(Icons.add);
      if (createButton.evaluate().isNotEmpty) {
        await tester.tap(createButton);
        await tester.pumpAndSettle();
      }

      // スケジュール作成を試行
      await TestUtils.createSchedule(
        tester: tester,
        title: 'エラーテストスケジュール',
        description: 'エラーテスト用の説明',
      );

      // エラーメッセージが表示されることを確認
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.textContaining('失敗'), findsAtLeastNWidgets(1));
    });
  });
}
