/// テスト環境での設定を管理するクラス
class TestConfig {
  static const bool isCI = bool.fromEnvironment('CI', defaultValue: false);
  static const bool isFlutterTest =
      bool.fromEnvironment('FLUTTER_TEST', defaultValue: false);

  /// テスト実行時のタイムアウト設定（秒）
  static const int testTimeoutSeconds = isCI ? 120 : 60;

  /// Widget テストでのpumpAndSettle最大実行時間（ミリ秒）
  static const Duration maxPumpDuration =
      Duration(milliseconds: isCI ? 10000 : 5000);

  /// Integration テストでのタイムアウト設定
  static const Duration integrationTestTimeout =
      Duration(minutes: isCI ? 5 : 3);

  /// Firebase エミュレータの設定
  static const String firestoreEmulatorHost = '127.0.0.1';
  static const int firestoreEmulatorPort = 8080;
  static const String authEmulatorHost = '127.0.0.1';
  static const int authEmulatorPort = 9099;

  /// CI環境でのテスト動作設定
  static const bool shouldRunIntegrationTests = !isCI; // CI環境では統合テストをスキップ
  static const bool shouldConnectToFirebase = !isCI; // CI環境ではFirebase接続をスキップ

  /// テストデータの設定
  static const String testUserId = 'test-user-id';
  static const String testUserEmail = 'test@example.com';
  static const String testUserPassword = 'password123';

  /// モック設定
  static const bool useMockAuth = true;
  static const bool useMockFirestore = true;
  static const bool useMockStorage = true;
}
