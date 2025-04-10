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

    // 環境変数からFirebaseOptionsクラス名を取得
    const firebaseOptionsClass =
        String.fromEnvironment('FIREBASE_OPTIONS_CLASS');

    // 環境変数からアプリ名を取得
    appName = const String.fromEnvironment('APP_NAME', defaultValue: 'LaKiite');

    // FirebaseOptionsクラス名に基づいて適切なFirebaseOptionsを選択
    if (firebaseOptionsClass == 'ProdFirebaseOptions') {
      options = ProdFirebaseOptions.currentPlatform;
      environment = Environment.production;
    } else {
      options = DevFirebaseOptions.currentPlatform;
      environment = Environment.development;
    }

    _instance = AppConfig._(environment, options, appName);
  }

  /// プライベートコンストラクタ
  AppConfig._(this.environment, this.firebaseOptions, this.appName);

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
