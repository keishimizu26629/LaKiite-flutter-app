import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
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

  /// 環境設定マップ
  /// 新しい環境を追加する場合は、ここに設定を追加する
  static final Map<Environment, EnvironmentConfig> _environmentConfigs = {
    Environment.development: EnvironmentConfig(
      firebaseOptionsFactory: () => DevFirebaseOptions.currentPlatform,
      appName: 'LaKiite',
      pushNotificationUrl:
          'https://asia-northeast1-lakiite-flutter-app-dev.cloudfunctions.net/sendNotification',
      firebaseOptionsClassName: 'DevFirebaseOptions',
    ),
    Environment.production: EnvironmentConfig(
      firebaseOptionsFactory: () => ProdFirebaseOptions.currentPlatform,
      appName: 'LaKiite',
      pushNotificationUrl:
          'https://asia-northeast1-lakiite-flutter-app-prod.cloudfunctions.net/sendNotification',
      firebaseOptionsClassName: 'ProdFirebaseOptions',
    ),
  };

  /// 環境設定を初期化
  ///
  /// [environment] 環境の種類
  ///
  /// 既に初期化済みの場合は例外をスローする（再初期化防止）
  static void initialize(Environment environment) {
    // 再初期化防止
    if (_instance != null) {
      throw Exception(
          'AppConfig has already been initialized with environment: ${_instance!.environment.name}. '
          'Re-initialization is not allowed.');
    }

    FirebaseOptions options;
    String appName;
    String pushNotificationUrl;

    // 環境変数からFirebaseOptionsクラス名を取得（検証用）
    const firebaseOptionsClass =
        String.fromEnvironment('FIREBASE_OPTIONS_CLASS');

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
      appName = 'LaKiite (Test)';
      pushNotificationUrl = 'https://test-functions.net/sendNotification';
    } else {
      // 環境設定マップから設定を取得
      final config = _environmentConfigs[environment];
      if (config == null) {
        throw Exception(
            'Environment configuration not found for: ${environment.name}. '
            'Please add configuration to _environmentConfigs map.');
      }

      try {
        // FirebaseOptionsを取得
        options = config.firebaseOptionsFactory();

        // 環境変数からアプリ名を取得（デフォルトは設定マップの値）
        const appNameEnv = String.fromEnvironment('APP_NAME');
        appName = appNameEnv.isEmpty ? config.appName : appNameEnv;

        pushNotificationUrl = config.pushNotificationUrl;

        // 検証: FIREBASE_OPTIONS_CLASSが一致しているか確認
        if (firebaseOptionsClass.isNotEmpty &&
            firebaseOptionsClass != config.firebaseOptionsClassName) {
          throw Exception(
              '環境の不整合: environment=${environment.name} だが FIREBASE_OPTIONS_CLASS=$firebaseOptionsClass '
              '(期待値: ${config.firebaseOptionsClassName})');
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
        appName = 'LaKiite (Fallback)';
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

  /// テスト用: インスタンスをリセット（テスト時のみ使用）
  @visibleForTesting
  static void reset() {
    _instance = null;
  }
}

/// 環境設定データクラス
class EnvironmentConfig {
  /// FirebaseOptionsを生成するファクトリー関数
  final FirebaseOptions Function() firebaseOptionsFactory;

  /// アプリ名
  final String appName;

  /// プッシュ通知用Cloud FunctionのURL
  final String pushNotificationUrl;

  /// FirebaseOptionsクラス名（検証用）
  final String firebaseOptionsClassName;

  const EnvironmentConfig({
    required this.firebaseOptionsFactory,
    required this.appName,
    required this.pushNotificationUrl,
    required this.firebaseOptionsClassName,
  });
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
