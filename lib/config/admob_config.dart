import 'dart:io';
import '../utils/logger.dart';

/// AdMob設定を管理するクラス
class AdMobConfig {
  /// プライベートコンストラクタ
  AdMobConfig._({
    required this.androidAppId,
    required this.iosAppId,
    required this.androidBannerId,
    required this.iosBannerId,
  });

  /// Android用アプリID
  final String androidAppId;

  /// iOS用アプリID
  final String iosAppId;

  /// Android用バナー広告ユニットID
  final String androidBannerId;

  /// iOS用バナー広告ユニットID
  final String iosBannerId;

  /// シングルトンインスタンス
  static AdMobConfig? _instance;

  /// 現在のAdMob設定を取得
  static AdMobConfig get instance {
    if (_instance == null) {
      throw Exception('AdMobConfig has not been initialized');
    }
    return _instance!;
  }

  /// AdMob設定を初期化
  ///
  /// 環境変数からAdMob IDを読み込み、検証を行います。
  /// 設定値が不正な場合は例外をスローします。
  ///
  /// テスト環境の場合は検証をスキップし、ダミー値を設定します。
  static void initialize() {
    // テスト環境かどうかを確認
    const isTestEnvironment =
        bool.fromEnvironment('FLUTTER_TEST', defaultValue: false);

    if (isTestEnvironment) {
      // テスト環境ではダミー値を設定
      _instance = AdMobConfig._(
        androidAppId: 'ca-app-pub-test-android',
        iosAppId: 'ca-app-pub-test-ios',
        androidBannerId: 'ca-app-pub-test-android-banner',
        iosBannerId: 'ca-app-pub-test-ios-banner',
      );
      AppLogger.info('✅ AdMob設定を初期化しました（テスト環境）');
      return;
    }

    // 環境変数からAdMob IDを取得
    const androidAppId = String.fromEnvironment('ADMOB_ANDROID_APP_ID');
    const iosAppId = String.fromEnvironment('ADMOB_IOS_APP_ID');
    const androidBannerId = String.fromEnvironment('ADMOB_ANDROID_BANNER_ID');
    const iosBannerId = String.fromEnvironment('ADMOB_IOS_BANNER_ID');

    // 設定値の検証
    _validateConfig(
      androidAppId: androidAppId,
      iosAppId: iosAppId,
      androidBannerId: androidBannerId,
      iosBannerId: iosBannerId,
    );

    _instance = AdMobConfig._(
      androidAppId: androidAppId,
      iosAppId: iosAppId,
      androidBannerId: androidBannerId,
      iosBannerId: iosBannerId,
    );

    AppLogger.info('✅ AdMob設定を初期化しました');
    AppLogger.debug('📱 Android App ID: ${_instance!.androidAppId}');
    AppLogger.debug('🍎 iOS App ID: ${_instance!.iosAppId}');
  }

  /// 設定値の検証
  static void _validateConfig({
    required String androidAppId,
    required String iosAppId,
    required String androidBannerId,
    required String iosBannerId,
  }) {
    final errors = <String>[];

    // 必須チェック
    if (androidAppId.isEmpty) {
      errors.add('ADMOB_ANDROID_APP_IDが設定されていません');
    }
    if (iosAppId.isEmpty) {
      errors.add('ADMOB_IOS_APP_IDが設定されていません');
    }
    if (androidBannerId.isEmpty) {
      errors.add('ADMOB_ANDROID_BANNER_IDが設定されていません');
    }
    if (iosBannerId.isEmpty) {
      errors.add('ADMOB_IOS_BANNER_IDが設定されていません');
    }

    // 形式チェック（AdMob IDは通常 "ca-app-pub-" で始まる）
    if (androidAppId.isNotEmpty && !androidAppId.startsWith('ca-app-pub-')) {
      errors.add('ADMOB_ANDROID_APP_IDの形式が不正です: $androidAppId');
    }
    if (iosAppId.isNotEmpty && !iosAppId.startsWith('ca-app-pub-')) {
      errors.add('ADMOB_IOS_APP_IDの形式が不正です: $iosAppId');
    }
    if (androidBannerId.isNotEmpty &&
        !androidBannerId.startsWith('ca-app-pub-')) {
      errors.add('ADMOB_ANDROID_BANNER_IDの形式が不正です: $androidBannerId');
    }
    if (iosBannerId.isNotEmpty && !iosBannerId.startsWith('ca-app-pub-')) {
      errors.add('ADMOB_IOS_BANNER_IDの形式が不正です: $iosBannerId');
    }

    if (errors.isNotEmpty) {
      final errorMessage = errors.join('\n');
      AppLogger.error('❌ AdMob設定エラー:\n$errorMessage');
      throw Exception('AdMob設定が不正です:\n$errorMessage');
    }
  }

  /// 現在のプラットフォームに応じたアプリIDを取得
  String getAppId() {
    if (Platform.isAndroid) {
      return androidAppId;
    } else if (Platform.isIOS) {
      return iosAppId;
    }
    throw UnsupportedError('Unsupported platform');
  }

  /// 現在のプラットフォームに応じたバナー広告ユニットIDを取得
  String getBannerId() {
    if (Platform.isAndroid) {
      return androidBannerId;
    } else if (Platform.isIOS) {
      return iosBannerId;
    }
    throw UnsupportedError('Unsupported platform');
  }
}
