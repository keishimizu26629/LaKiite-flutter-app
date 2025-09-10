# LaKiite TestFlight リリース準備 - 完了サマリー

## ✅ 完了した作業 (AI 対応済み)

### 1. iOS Push Notification 設定修正

- **ファイル**: `ios/Runner/Runner.entitlements`
- **変更**: `aps-environment` を `production` に変更
- **効果**: TestFlight でのプッシュ通知テストが可能

### 2. 権限説明文の改善

- **ファイル**: `ios/Runner/Info.plist`
- **変更**: カメラ、写真ライブラリ、広告トラッキングの説明文を改善
- **効果**: 審査通過率の向上、ユーザー理解の促進

### 3. Android 署名設定の実装

- **ファイル**: `android/app/build.gradle`
- **追加**: Release 用署名設定
- **作成**: `android/key.properties.template`
- **効果**: 本番用 APK/AAB のビルドが可能

### 4. バージョン情報の更新

- **ファイル**: `pubspec.yaml`
- **変更**: `version: 1.0.0+1` (リリース用バージョン)
- **効果**: 正式リリース準備完了

### 5. 法的文書テンプレート作成

- **作成**: `PRIVACY_POLICY_TEMPLATE.md`
- **作成**: `TERMS_OF_SERVICE_TEMPLATE.md`
- **効果**: 審査必須文書の準備完了

### 6. コードの整理

- **削除**: 空の TODO ファイル (`lib/infrastructure/repository/schedule_repository.dart`)
- **修正**: TODO コメントを実装予定コメントに変更
- **効果**: コード品質の向上

### 7. ビルド・確認スクリプト作成

- **作成**: `scripts/build_testflight.sh` (実行可能)
- **作成**: `scripts/check_admob_config.sh` (実行可能)
- **効果**: 自動化されたビルドプロセス

### 8. Firebase 設定問題の文書化

- **作成**: `FIREBASE_CONFIG_FIX_NEEDED.md`
- **効果**: 修正すべき項目の明確化

## 🚨 あなたが対応すべき緊急項目

### 1. Firebase 設定修正 (最優先)

```bash
# 現在の問題
ios/Runner/Firebase/Prod/GoogleService-Info.plist
Bundle ID: com.example.tarakite ← 間違い
正しい値: com.inoworl.lakiite

# 対応方法
1. Firebase Console → lakiite-flutter-app-prod プロジェクト
2. iOS アプリ設定 → Bundle ID を com.inoworl.lakiite に修正
3. 新しい GoogleService-Info.plist をダウンロード
4. ios/Runner/Firebase/Prod/GoogleService-Info.plist を置き換え
```

### 2. Android 署名用 Keystore 作成

```bash
# 手順
1. keytool -genkey -v -keystore ~/lakiite-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias lakiite
2. android/key.properties.template をコピーして android/key.properties を作成
3. 実際のパスワードとパスを設定
```

### 3. 法的文書の内容確定・公開

- プライバシーポリシーの内容確定
- 利用規約の内容確定
- 公開用 URL の設定

## 📱 TestFlight 用ビルドの実行

Firebase 設定修正と Android 署名設定完了後、以下のコマンドでビルドできます：

```bash
# 全体チェック付きビルド
./scripts/build_testflight.sh

# iOS のみ
./scripts/build_testflight.sh ios

# Android のみ
./scripts/build_testflight.sh android
```

## 🎯 現在の状況

### 技術的準備状況

- **iOS**: 80% 完了 (Firebase 設定修正のみ残り)
- **Android**: 90% 完了 (Keystore 作成のみ残り)
- **共通**: 95% 完了 (法的文書公開のみ残り)

### AdMob 設定

- **現在**: テスト用 ID 使用中 ✅ (TestFlight 段階では適切)
- **本番リリース時**: 本番用 ID に変更が必要

### 推定作業時間

- **Firebase 設定修正**: 30 分
- **Android Keystore 作成**: 15 分
- **法的文書確定**: 2-3 時間

## 🚀 次のステップ

### 1. 緊急対応 (今日中)

1. Firebase Bundle ID 修正
2. Android Keystore 作成
3. TestFlight ビルド実行

### 2. 短期対応 (1 週間以内)

1. 法的文書の内容確定・公開
2. Apple Developer Console 設定
3. TestFlight 内部テスト開始

### 3. 中期対応 (2 週間以内)

1. 本番用 AdMob ID 取得・設定
2. Google Play Console 設定
3. Android 内部テスト開始

**TestFlight リリースまで残り作業: 約 1-2 時間**
