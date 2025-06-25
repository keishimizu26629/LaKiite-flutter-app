import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'config/app_config.dart';
import 'config/router/app_router.dart';
import 'infrastructure/admob_service.dart';
import 'infrastructure/firebase/push_notification_service.dart';
import 'presentation/theme/app_theme.dart';
import 'utils/logger.dart';

/// アプリケーションのエントリーポイント
Future<void> main() async {
  // 環境変数からFlavorを取得
  const flavorString = String.fromEnvironment('FLAVOR');
  const environment = flavorString == 'production'
      ? Environment.production
      : Environment.development;

  await startApp(environment);
}

/// アプリケーションの起動処理
///
/// [environment] 起動する環境
/// [overrides] Riverpodプロバイダーのオーバーrides
/// [skipFirebaseInit] Firebase初期化をスキップするかどうか（テスト用）
Future<void> startApp([
  Environment environment = Environment.development,
  List<Override> overrides = const [],
  bool skipFirebaseInit = false,
]) async {
  // Flutterウィジェットバインディングの初期化
  WidgetsFlutterBinding.ensureInitialized();

  // iOS でのプラットフォームビュー問題を予防
  if (Platform.isIOS) {
    await _resetPlatformViews();
  }

  // 環境設定の初期化
  AppConfig.initialize(environment);

  // 日本語ロケールの初期化
  await initializeDateFormatting('ja_JP', null);

  // Firebase関連の初期化（テスト時はスキップ）
  if (!skipFirebaseInit) {
    try {
      // Firebaseの初期化
      await Firebase.initializeApp(options: AppConfig.instance.firebaseOptions);

      // プッシュ通知サービスの初期化
      await PushNotificationService.instance.initialize();

      // FCMトークンの強制更新（registration-token-not-registered エラー対策）
      await PushNotificationService.instance.forceUpdateFCMToken();

      // AdMobの初期化
      await AdMobService.initialize();
    } catch (e) {
      // Firebase初期化エラーをログに記録
      debugPrint('Firebase initialization failed: $e');

      // テスト環境またはCI環境ではエラーを無視
      const isTest = bool.fromEnvironment('FLUTTER_TEST', defaultValue: false);
      if (!isTest && environment != Environment.development) {
        rethrow;
      }
    }
  }

  // アプリケーションの起動
  runApp(ProviderScope(overrides: overrides, child: const MyApp()));
}

/// iOS でのプラットフォームビューリセット処理
/// WebView クラッシュを予防するため
Future<void> _resetPlatformViews() async {
  try {
    // iOS WebView プラットフォームビューのリセット
    const MethodChannel('flutter/platform_views').setMethodCallHandler(null);
    AppLogger.debug('プラットフォームビューをリセットしました');
  } catch (e) {
    AppLogger.warning('プラットフォームビューリセットエラー: $e');
  }
}

/// アプリケーションのルートウィジェット
///
/// 設定:
/// - アプリケーションタイトル
/// - テーマ設定
/// - ルーティング設定
///
/// 依存:
/// - [ProviderScope]の子ウィジェットとして使用
/// - [routerProvider]からルーティング設定を取得
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ルーター設定の取得
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'LaKiite',
      theme: AppTheme.theme,
      routerConfig: router,
      // 環境名をデバッグモードで表示
      debugShowCheckedModeBanner: AppConfig.instance.isDevelopment,
    );
  }
}
