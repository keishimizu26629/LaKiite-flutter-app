import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app/di/providers.dart';
import 'application/force_update/force_update_providers.dart';
import 'config/app_config.dart';
import 'config/admob_config.dart';
import 'config/firebase_emulator_config.dart';
import 'config/router/app_router.dart';
import 'infrastructure/admob_service.dart';
import 'infrastructure/airbridge_deep_link_service.dart';
import 'infrastructure/deep_link_navigation_service.dart';
import 'infrastructure/firebase/push_notification_service.dart';
import 'infrastructure/notification_navigation_service.dart';
import 'presentation/force_update/force_update_gate.dart';
import 'presentation/notification/notification_list_page.dart';
import 'presentation/theme/app_theme.dart';
import 'application/app_lifecycle/app_lifecycle_notifier.dart';
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

  // Android では写真/動画への広範アクセス権限を使わず、ユーザーが選択した画像だけを扱う。
  final imagePickerImplementation = ImagePickerPlatform.instance;
  if (imagePickerImplementation is ImagePickerAndroid) {
    imagePickerImplementation.useAndroidPhotoPicker = true;
  }

  // 環境設定の初期化
  AppConfig.initialize(environment);

  // AdMob設定の初期化（Firebase初期化の前に行う）
  AdMobConfig.initialize(forceTestMode: skipFirebaseInit);

  // 日本語ロケールの初期化
  await initializeDateFormatting('ja_JP', null);

  // Firebase関連の初期化（テスト時はスキップ）
  if (!skipFirebaseInit) {
    try {
      AppLogger.info(
          'Firebase初期化を開始: env=${AppConfig.instance.environmentName}, projectId=${AppConfig.instance.firebaseOptions.projectId}, iosBundleId=${AppConfig.instance.firebaseOptions.iosBundleId}');

      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
            options: AppConfig.instance.firebaseOptions);
        AppLogger.info('Firebase初期化完了: [DEFAULT] を作成しました');
      } else {
        AppLogger.warning(
            'Firebaseは既に初期化済みのため再初期化をスキップします: apps=${Firebase.apps.map((app) => app.name).join(', ')}');
      }

      final defaultApp = Firebase.app();
      AppLogger.info(
          'Firebase使用中アプリ: name=${defaultApp.name}, projectId=${defaultApp.options.projectId}, appId=${defaultApp.options.appId}, senderId=${defaultApp.options.messagingSenderId}, iosBundleId=${defaultApp.options.iosBundleId}');

      await connectFirebaseEmulatorsIfNeeded();

      const skipPushNotificationSetup = bool.fromEnvironment('TEST_MODE',
              defaultValue: false) ||
          bool.fromEnvironment('USE_FIREBASE_EMULATOR', defaultValue: false);

      if (!skipPushNotificationSetup) {
        // プッシュ通知サービスの初期化
        AppLogger.info('🚀 プッシュ通知サービスの初期化を開始...');
        await PushNotificationService.instance.initialize();

        const forceRefreshFcmTokenOnStartup = bool.fromEnvironment(
          'FORCE_REFRESH_FCM_TOKEN_ON_STARTUP',
          defaultValue: false,
        );
        if (forceRefreshFcmTokenOnStartup) {
          AppLogger.info('🔄 FCMトークンの強制更新を実行...');
          await PushNotificationService.instance.forceUpdateFCMToken();
          AppLogger.info('✅ FCMトークンの強制更新が完了');
        }

        // アプリ起動時にバッジカウントをクリア
        AppLogger.info('🧹 アプリ起動時のバッジカウントクリアを実行...');
        await PushNotificationService.instance.clearBadgeCount();
        AppLogger.info('✅ バッジカウントクリアが完了');
      } else {
        AppLogger.info('テスト環境のためプッシュ通知初期化をスキップします');
      }

      // AdMobの初期化
      await AdMobService.initialize();
    } catch (e) {
      // Firebase初期化エラーをログに記録
      AppLogger.error('❌ Firebase初期化に失敗しました: $e');
      AppLogger.info('💡 トラブルシューティング:');
      AppLogger.info('   - ネットワーク接続を確認してください');
      AppLogger.info('   - Firebase設定ファイルが正しく配置されているか確認してください');
      AppLogger.info('   - 実機でテストしてください（シミュレータでは制限があります）');

      // テスト環境またはCI環境ではエラーを無視
      const isTest = bool.fromEnvironment('FLUTTER_TEST', defaultValue: false);
      if (!isTest && environment != Environment.development) {
        rethrow;
      }
    }
  }

  final effectiveOverrides = [
    if (skipFirebaseInit)
      forceUpdateFeatureEnabledProvider.overrideWithValue(false),
    ...overrides,
  ];

  // アプリケーションの起動
  runApp(ProviderScope(overrides: effectiveOverrides, child: const MyApp()));
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

    // アプリライフサイクルの監視を開始
    ref.watch(appLifecycleProvider);

    NotificationNavigationService.instance.configureNotificationListBuilder(
      (_) => const NotificationListPage(),
    );
    DeepLinkNavigationService.instance.configureGrowthAnalytics(
      ref.watch(growthAnalyticsProvider),
    );
    DeepLinkNavigationService.instance.configureFriendSearchNavigator(
      (searchId) => router.push<void>(
        '/friend/search?searchId=${Uri.encodeQueryComponent(searchId)}',
      ),
    );

    const skipAirbridgeRuntime = bool.fromEnvironment(
          'TEST_MODE',
          defaultValue: false,
        ) ||
        bool.fromEnvironment('FLUTTER_TEST', defaultValue: false);
    if (!skipAirbridgeRuntime) {
      AirbridgeDeepLinkService.instance.start();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      const skipPushNotificationRuntime = bool.fromEnvironment(
            'TEST_MODE',
            defaultValue: false,
          ) ||
          bool.fromEnvironment('FLUTTER_TEST', defaultValue: false) ||
          bool.fromEnvironment('USE_FIREBASE_EMULATOR', defaultValue: false);
      if (!skipPushNotificationRuntime &&
          Platform.isAndroid &&
          Firebase.apps.isNotEmpty) {
        PushNotificationService.instance.requestAndroidNotificationPermission();
      }
      NotificationNavigationService.instance.flushPendingNavigation();
      unawaited(DeepLinkNavigationService.instance.flushPendingNavigation());
    });

    return MaterialApp.router(
      title: 'LaKiite',
      theme: AppTheme.theme,
      locale: const Locale('ja', 'JP'),
      routerConfig: router,
      builder: (context, child) => ForceUpdateGate(
        child: child ?? const SizedBox.shrink(),
      ),
      // 環境名をデバッグモードで表示
      debugShowCheckedModeBanner: AppConfig.instance.isDevelopment,
    );
  }
}
