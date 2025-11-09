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
  /// [environment] 環境の種類（main.dartから渡される環境変数FLAVORに基づく）
  /// このパラメータが優先され、FIREBASE_OPTIONS_CLASSは補助的な情報として使用される
  static void initialize(Environment environment) {
    FirebaseOptions options;
    String appName;
    String pushNotificationUrl;

    // 環境変数からFirebaseOptionsクラス名を取得（検証用）
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
      // 渡されたenvironmentパラメータに基づいて適切なFirebaseOptionsを選択
      // FIREBASE_OPTIONS_CLASSは検証用として使用
      try {
        if (environment == Environment.production) {
          // 本番環境
          options = ProdFirebaseOptions.currentPlatform;
          pushNotificationUrl =
              'https://asia-northeast1-lakiite-flutter-app-prod.cloudfunctions.net/sendNotification';

          // 検証: FIREBASE_OPTIONS_CLASSが一致しているか確認
          if (firebaseOptionsClass.isNotEmpty &&
              firebaseOptionsClass != 'ProdFirebaseOptions') {
            throw Exception(
                '環境の不整合: environment=production だが FIREBASE_OPTIONS_CLASS=$firebaseOptionsClass');
          }
        } else {
          // 開発環境
          options = DevFirebaseOptions.currentPlatform;
          pushNotificationUrl =
              'https://asia-northeast1-lakiite-flutter-app-dev.cloudfunctions.net/sendNotification';

          // 検証: FIREBASE_OPTIONS_CLASSが一致しているか確認
          if (firebaseOptionsClass.isNotEmpty &&
              firebaseOptionsClass != 'DevFirebaseOptions') {
            throw Exception(
                '環境の不整合: environment=development だが FIREBASE_OPTIONS_CLASS=$firebaseOptionsClass');
          }
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
