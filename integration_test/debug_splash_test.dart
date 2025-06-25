import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lakiite/main.dart';
import 'package:lakiite/config/app_config.dart';
import '../mock/providers/test_providers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('スプラッシュ画面遷移デバッグ', () {
    setUp(() {
      TestProviders.reset();
    });

    testWidgets('未認証状態でのスプラッシュ画面遷移', (tester) async {
      print('🔍 デバッグテスト開始: 未認証状態');

      // アプリ起動（未認証状態）
      await startApp(Environment.development, TestProviders.forLoginForm);
      await tester.pumpAndSettle();

      print('✅ アプリ起動完了');

      // 初期画面の確認
      print('🔍 初期画面の確認:');
      _printCurrentScreenState(tester);

      // 2秒待機（スプラッシュ画面の表示時間）
      print('⏳ スプラッシュ画面の表示時間（2秒）を待機...');
      await Future.delayed(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      print('🔍 2秒後の画面状態:');
      _printCurrentScreenState(tester);

      // さらに3秒待機
      print('⏳ さらに3秒待機...');
      await Future.delayed(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      print('🔍 5秒後の画面状態:');
      _printCurrentScreenState(tester);

      // 強制的にルートを確認
      print('🔍 現在のルート情報を確認:');
      final context = tester.element(find.byType(MaterialApp).first);
      final router = GoRouter.of(context);
      print('  現在のルート: ${router.routerDelegate.currentConfiguration.fullPath}');
    });

    testWidgets('認証済み状態でのスプラッシュ画面遷移', (tester) async {
      print('🔍 デバッグテスト開始: 認証済み状態');

      // アプリ起動（認証済み状態）
      await startApp(Environment.development, TestProviders.authenticated);
      await tester.pumpAndSettle();

      print('✅ アプリ起動完了');

      // 初期画面の確認
      print('🔍 初期画面の確認:');
      _printCurrentScreenState(tester);

      // 2秒待機（スプラッシュ画面の表示時間）
      print('⏳ スプラッシュ画面の表示時間（2秒）を待機...');
      await Future.delayed(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      print('🔍 2秒後の画面状態:');
      _printCurrentScreenState(tester);

      // さらに3秒待機
      print('⏳ さらに3秒待機...');
      await Future.delayed(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      print('🔍 5秒後の画面状態:');
      _printCurrentScreenState(tester);
    });
  });
}

void _printCurrentScreenState(WidgetTester tester) {
  // 基本的なウィジェットの数をカウント
  final scaffoldCount = find.byType(Scaffold).evaluate().length;
  final appBarCount = find.byType(AppBar).evaluate().length;
  final textFieldCount = find.byType(TextField).evaluate().length;
  final elevatedButtonCount = find.byType(ElevatedButton).evaluate().length;
  final bottomNavCount = find.byType(BottomNavigationBar).evaluate().length;

  print('  Scaffold: ${scaffoldCount}個');
  print('  AppBar: ${appBarCount}個');
  print('  TextField: ${textFieldCount}個');
  print('  ElevatedButton: ${elevatedButtonCount}個');
  print('  BottomNavigationBar: ${bottomNavCount}個');

  // AppBarのタイトルを確認
  if (appBarCount > 0) {
    try {
      final appBar = tester.widget<AppBar>(find.byType(AppBar).first);
      if (appBar.title is Text) {
        final title = (appBar.title as Text).data;
        print('  AppBarタイトル: "$title"');
      }
    } catch (e) {
      print('  AppBarタイトル取得エラー: $e');
    }
  }

  // Scaffoldの背景色を確認（スプラッシュ画面判定用）
  if (scaffoldCount > 0) {
    try {
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      print('  Scaffold背景色: ${scaffold.backgroundColor}');
      if (scaffold.backgroundColor == const Color(0xFFffa600)) {
        print('  → スプラッシュ画面です');
      } else {
        print('  → スプラッシュ画面ではありません');
      }
    } catch (e) {
      print('  Scaffold背景色取得エラー: $e');
    }
  }

  // 主要なテキストを確認
  final textWidgets =
      tester.widgetList<Text>(find.byType(Text)).take(10).toList();
  if (textWidgets.isNotEmpty) {
    print('  表示されているテキスト（上位10個）:');
    for (int i = 0; i < textWidgets.length; i++) {
      final data = textWidgets[i].data;
      if (data != null && data.isNotEmpty) {
        print('    ${i + 1}. "$data"');
      }
    }
  } else {
    print('  表示されているテキスト: なし');
  }

  print('  ウィジェットツリー（上位15個）:');
  final allWidgets = tester.allWidgets.take(15).toList();
  for (int i = 0; i < allWidgets.length; i++) {
    print('    ${i + 1}. ${allWidgets[i].runtimeType}');
  }
}
