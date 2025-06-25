# 📱 統合テスト実行ガイド

## 🚀 クイックスタート

### 1. 全てのテストを実行

```bash
# 自動セットアップ付きで実行
./scripts/run_integration_tests.sh

# または手動実行
flutter test integration_test --dart-define=TEST_MODE=true
```

### 2. 特定のテストのみ実行

```bash
# 新規登録フローのテスト
./scripts/run_integration_tests.sh -t signup_navigation_integration_test.dart

# スケジュール作成フローのテスト
./scripts/run_integration_tests.sh -t schedule_flow_integration_test.dart
```

### 3. 特定のデバイスで実行

```bash
# iPhone 15 Proで実行
./scripts/run_integration_tests.sh -d "iPhone 15 Pro"

# 利用可能なデバイス一覧を確認
flutter devices
```

## 🔧 手動セットアップ（推奨しません）

もし自動セットアップスクリプトを使わない場合：

```bash
# 1. シミュレーターの起動
open -a Simulator

# 2. 権限の事前付与
./scripts/setup_integration_test.sh

# 3. テスト実行
flutter test integration_test --dart-define=TEST_MODE=true
```

## 🧪 テスト環境の仕組み

### 通知許可ポップアップ対策

このプロジェクトでは 3 つの手法を組み合わせて通知許可ポップアップによるテスト中断を防いでいます：

#### ① simctl による事前権限付与（推奨）

```bash
# Bundle ID: com.inoworl.lakiite に通知許可を事前付与
xcrun simctl privacy $DEVICE_ID grant notifications com.inoworl.lakiite
```

#### ② アプリ側でのテスト時スキップ

```dart
// Dart側
const bool kIsTest = bool.fromEnvironment('TEST_MODE', defaultValue: false);
if (kIsTest) return; // 通知許可をスキップ

// Swift側（iOS）
let isTestMode = ProcessInfo.processInfo.environment["TEST_MODE"] == "true"
if isTestMode { /* 通知許可をスキップ */ }
```

#### ③ XCTest での自動タップ（バックアップ）

```swift
// ios/RunnerTests/IntegrationTestHelper.swift
addUIInterruptionMonitor(withDescription: "Push Notifications") { alert in
    let allowButton = alert.buttons["許可"] // または "Allow"
    if allowButton.exists {
        allowButton.tap()
        return true
    }
    return false
}
```

## 🐛 トラブルシューティング

### 一般的な問題

#### 1. シミュレーターが見つからない

```bash
❌ 起動中のシミュレーターが見つかりません
```

**解決方法:**

- Xcode を開いてシミュレーターを起動
- または `open -a Simulator` でシミュレーターを起動

#### 2. 権限付与に失敗

```bash
⚠️ 通知許可の付与に失敗しました
```

**解決方法:**

- アプリを一度起動してからスクリプトを再実行
- シミュレーターをリセット: Device → Erase All Content and Settings

#### 3. Firebase 初期化エラー

```bash
Firebase initialization failed
```

**解決方法:**

- Firebase 設定ファイルが正しく配置されているか確認
- `ios/Runner/GoogleService-Info.plist` の存在確認
- `android/app/google-services.json` の存在確認

#### 4. ビルドエラー

```bash
❌ テストが失敗しました (終了コード: 1)
```

**解決方法:**

```bash
# 1. クリーンビルド
flutter clean
flutter pub get

# 2. iOS依存関係の再インストール
cd ios && pod install && cd ..

# 3. 再ビルド
flutter build ios --debug
```

### デバッグ用コマンド

```bash
# 詳細ログ付きでテスト実行
flutter test integration_test/signup_navigation_integration_test.dart --dart-define=TEST_MODE=true -v

# 特定のデバイスで詳細ログ
flutter test integration_test --dart-define=TEST_MODE=true -d "iPhone 15 Pro" -v

# 現在の権限状態確認
xcrun simctl privacy booted list notifications
```

## 📁 ファイル構成

```
integration_test/
├── README.md                                  # このファイル
├── signup_navigation_integration_test.dart    # 新規登録フローテスト
├── schedule_flow_integration_test.dart        # スケジュール作成フローテスト
├── mock/                                      # モックオブジェクト
│   ├── providers/
│   │   └── test_providers.dart
│   └── repositories/
│       ├── mock_auth_repository.dart
│       ├── mock_schedule_repository.dart
│       └── mock_user_repository.dart
└── utils/
    └── test_utils.dart                        # テスト用ユーティリティ

scripts/
├── setup_integration_test.sh                 # 環境セットアップスクリプト
└── run_integration_tests.sh                  # テスト実行スクリプト

ios/RunnerTests/
└── IntegrationTestHelper.swift               # iOS側自動ダイアログ処理
```

## 🎯 ベストプラクティス

### 1. テスト実行前の準備

- シミュレーターを事前に起動
- アプリを一度手動で起動して初期設定を完了
- 不要なアプリを閉じてリソースを確保

### 2. テスト中の注意点

- テスト実行中はシミュレーターを操作しない
- 他のアプリケーションによる通知を無効化
- バッテリー残量を十分に確保

### 3. CI/CD での実行

```bash
# GitHub Actions などでの実行例
- name: Run Integration Tests
  run: |
    # シミュレーターの起動
    xcrun simctl boot "iPhone 15 Pro"

    # 権限の事前付与
    ./scripts/setup_integration_test.sh

    # テスト実行
    flutter test integration_test --dart-define=TEST_MODE=true
```

## 📞 サポート

問題が解決しない場合は、以下の情報を含めて報告してください：

1. 実行したコマンド
2. エラーメッセージの全文
3. Flutter バージョン（`flutter --version`）
4. Xcode バージョン
5. 使用しているシミュレーター
6. macOS バージョン

## 🔄 アップデート履歴

- **v1.0.0** - 初期リリース
  - 通知許可ポップアップ対策の実装
  - 自動セットアップスクリプトの追加
  - XCTest 自動ダイアログ処理の実装
