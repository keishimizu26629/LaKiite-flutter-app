import 'package:firebase_core/firebase_core.dart';
import '../firebase_options_dev.dart';
import '../firebase_options_prod.dart';

/// アプリケーションの環境設定を管理するクラス
class AppConfig {
  /// 環境の種類
  final Environment environment;

  /// Firebase設定
  final FirebaseOptions firebaseOptions;

  /// アプリ名
  final String appName;

  /// プッシュ通知用Cloud FunctionのURL
  final String pushNotificationUrl;

  /// シングルトンインスタンス
  static AppConfig? _instance;

  /// 現在の環境設定を取得
  static AppConfig get instance {
    if (_instance == null) {
      throw Exception('AppConfig has not been initialized');
    }
    return _instance!;
  }

  /// 環境設定を初期化
  ///
  /// [environment] 環境の種類
  static void initialize(Environment environment) {
    FirebaseOptions options;
    String appName;
    String pushNotificationUrl;

    // 環境変数からFirebaseOptionsクラス名を取得
    const firebaseOptionsClass =
        String.fromEnvironment('FIREBASE_OPTIONS_CLASS');

    // 環境変数からアプリ名を取得
    appName = const String.fromEnvironment('APP_NAME', defaultValue: 'LaKiite');

    // テスト環境の場合はダミーのFirebaseOptionsを使用
    const isTestEnvironment =
        bool.fromEnvironment('FLUTTER_TEST', defaultValue: false);

    if (isTestEnvironment) {
      options = const FirebaseOptions(
        apiKey: 'test-api-key',
        appId: 'test-app-id',
        messagingSenderId: 'test-sender-id',
        projectId: 'test-project-id',
        storageBucket: 'test-bucket',
      );
      environment = Environment.development;
      pushNotificationUrl = 'https://test-functions.net/sendNotification';
    } else {
      // FirebaseOptionsクラス名に基づいて適切なFirebaseOptionsを選択
      try {
        if (firebaseOptionsClass == 'ProdFirebaseOptions') {
          options = ProdFirebaseOptions.currentPlatform;
          environment = Environment.production;
          pushNotificationUrl =
              'https://asia-northeast1-lakiite-flutter-app-prod.cloudfunctions.net/sendNotification';
        } else {
          options = DevFirebaseOptions.currentPlatform;
          environment = Environment.development;
          pushNotificationUrl =
              'https://asia-northeast1-lakiite-flutter-app-dev.cloudfunctions.net/sendNotification';
        }
      } catch (e) {
        // Firebase設定ファイルが見つからない場合のフォールバック
        options = const FirebaseOptions(
          apiKey: 'fallback-api-key',
          appId: 'fallback-app-id',
          messagingSenderId: 'fallback-sender-id',
          projectId: 'fallback-project-id',
          storageBucket: 'fallback-bucket',
        );
        environment = Environment.development;
        pushNotificationUrl = 'https://fallback-functions.net/sendNotification';
      }
    }

    _instance = AppConfig._(environment, options, appName, pushNotificationUrl);
  }

  /// プライベートコンストラクタ
  AppConfig._(this.environment, this.firebaseOptions, this.appName,
      this.pushNotificationUrl);

  /// 開発環境かどうか
  bool get isDevelopment => environment == Environment.development;

  /// 本番環境かどうか
  bool get isProduction => environment == Environment.production;

  /// 環境名を取得
  String get environmentName => environment.name;
}

/// 環境の種類
enum Environment {
  /// 開発環境
  development,

  /// 本番環境
  production,
}

/// WebViewの有効/無効を制御する設定
/// 現在はiOSでのクラッシュ回避のため無効化
class WebViewConfig {
  /// WebViewを有効にするかどうか
  /// 環境変数 ENABLE_WEBVIEW で制御可能（デフォルト: false）
  static bool get isEnabled =>
      const bool.fromEnvironment('ENABLE_WEBVIEW', defaultValue: false);

  /// WebViewが無効な理由を取得
  static String get disabledReason => 'iOS Simulatorでのクラッシュ回避のため無効化されています';
}
