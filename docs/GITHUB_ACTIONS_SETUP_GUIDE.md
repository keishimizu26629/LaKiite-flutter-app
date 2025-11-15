---
title: "GitHub Actions デプロイメント設定ガイド（2025年版）"
created: 2025-11-13T06:14:45
updated: 2025-11-13T07:00:39
tags:
  - github-actions
  - deployment
  - ci-cd
  - android
  - ios
  - 2025-best-practices
---

# GitHub Actions デプロイメント設定ガイド（2025年版）

## 🎯 概要

このドキュメントでは、LaKiiteアプリのDev/Prod環境でのAndroid・iOSデプロイメントを自動化するGitHub Actionsの設定方法を説明します。

**2025年のベストプラクティス**に基づき、以下の最新技術を採用しています：
- **GitHub Environments** による環境別Secrets管理
- **App Store Connect API Key** による安全なiOS認証
- **Product Flavors** によるAndroid環境分離
- **Firebase設定ファイル** の動的切替
- **Upload Keystore** による適切なAndroid署名

## 📋 作成されたワークフローファイル

以下のワークフローファイルが作成されました：

- `.github/workflows/deploy_dev_android.yml` - Dev環境Android用
- `.github/workflows/deploy_prod_android.yml` - Prod環境Android用
- `.github/workflows/deploy_dev_ios.yml` - Dev環境iOS用
- `.github/workflows/deploy_prod_ios.yml` - Prod環境iOS用
- `.github/actions/setup/action.yml` - 共通セットアップアクション

## 🔧 必要な設定項目

### 1. GitHub Environments の設定（推奨）

**セキュリティ強化のため、GitHub Environments を使用してSecrets を環境別に分離します。**

1. GitHub リポジトリの Settings > Environments に移動
2. `dev` と `prod` 環境を作成
3. `prod` 環境には承認者を設定（本番デプロイ時の人的チェック）

### 2. GitHub Secrets の設定

各環境（dev/prod）のEnvironmentsで以下のSecretsを設定してください：

#### 共通Secrets（両環境で設定）

**Android署名関連**
```bash
ANDROID_UPLOAD_KEYSTORE_JKS_BASE64
# Upload Keystore ファイル（Base64エンコード済み）
# コマンド例: base64 -i upload-keystore.jks > keystore.base64.txt

ANDROID_UPLOAD_KEYSTORE_PASSWORD
# Keystoreのパスワード

ANDROID_UPLOAD_KEY_ALIAS
# キーのエイリアス

ANDROID_UPLOAD_KEY_PASSWORD
# キーのパスワード

GOOGLE_PLAY_CONSOLE_API_SERVICE_ACCOUNT_KEY_JSON_BASE64
# Google Play Console API サービスアカウントキーのJSON（Base64エンコード済み）
```

**iOS認証関連（App Store Connect API Key方式 - 2025年推奨）**
```bash
ASC_KEY_ID
# App Store Connect API Key の Key ID

ASC_ISSUER_ID
# App Store Connect API Key の Issuer ID

ASC_PRIVATE_KEY_P8_BASE64
# App Store Connect API Key の .p8 ファイル（Base64エンコード済み）

IOS_CERTIFICATES_P12_BASE64
# iOS Distribution証明書のP12ファイル（Base64エンコード済み）

IOS_CERTIFICATES_P12_PASSWORD
# P12ファイルのパスワード

APPLE_TEAM_ID
# Apple Developer Team ID
```

#### 環境別Secrets

**Dev環境**
```bash
DEV_DART_DEFINE_JSON_BASE64
# dart_define/dev_dart_define.json の内容（Base64エンコード済み）

DEV_FIREBASE_PROJECT_ID
# Dev Firebase プロジェクトID（例：your-dev-project-id）

DEV_FIREBASE_SERVICE_ACCOUNT_KEY_BASE64
# Dev Firebase プロジェクトのサービスアカウントキー（Base64エンコード済み）

DEV_FIREBASE_ANDROID_APP_ID
# Dev Firebase Android アプリID（例：1:123456789:android:abcdef123456）

DEV_ANDROID_PACKAGE_NAME
# Dev Android パッケージ名（例：com.example.lakiite.dev）

DEV_GOOGLE_SERVICES_JSON_BASE64
# Dev用 google-services.json（Base64エンコード済み）

DEV_GOOGLESERVICE_INFO_PLIST_BASE64
# Dev用 GoogleService-Info.plist（Base64エンコード済み）

DEV_PROVISIONING_PROFILE_BASE64
# Dev用Provisioning Profile（Base64エンコード済み）
```

**Prod環境**
```bash
PROD_DART_DEFINE_JSON_BASE64
# dart_define/prod_dart_define.json の内容（Base64エンコード済み）

PROD_FIREBASE_PROJECT_ID
# Prod Firebase プロジェクトID（例：your-prod-project-id）

PROD_FIREBASE_SERVICE_ACCOUNT_KEY_BASE64
# Prod Firebase プロジェクトのサービスアカウントキー（Base64エンコード済み）

PROD_FIREBASE_ANDROID_APP_ID
# Prod Firebase Android アプリID（例：1:987654321:android:fedcba654321）

PROD_ANDROID_PACKAGE_NAME
# Prod Android パッケージ名（例：com.example.lakiite）

PROD_GOOGLE_SERVICES_JSON_BASE64
# Prod用 google-services.json（Base64エンコード済み）

PROD_GOOGLESERVICE_INFO_PLIST_BASE64
# Prod用 GoogleService-Info.plist（Base64エンコード済み）

PROD_PROVISIONING_PROFILE_BASE64
# Prod用Provisioning Profile（Base64エンコード済み）
```

### 3. Firebase設定

#### Firebase App Distribution
1. Firebase Console > Project Settings > Integrations
2. Google Play Console と連携を設定
3. App Distribution でテスターグループ「internal-testers」を作成

#### Firebase CLI設定
プロジェクトルートに `firebase.json` を作成（既存の場合は確認）：

```json
{
  "projects": {
    "dev": "your-dev-firebase-project-id",
    "prod": "your-prod-firebase-project-id"
  }
}
```

#### Firebase設定ファイルの環境別配置
**Android**
```
android/app/src/dev/google-services.json     # Dev環境用
android/app/src/prod/google-services.json    # Prod環境用
```

**iOS**
```
ios/Runner/GoogleService-Info.plist          # CI時に環境別に動的復元
```

**注意**: iOSの場合、CI実行時に環境別のBase64エンコードされた設定ファイルから `ios/Runner/GoogleService-Info.plist` に動的復元されます。

### 4. Android設定

#### Google Play Console
1. Google Play Console でアプリを作成
2. API アクセス > サービスアカウント を作成
3. 必要な権限を付与（最低「リリース マネージャ」）
4. JSON キーをダウンロードしてBase64エンコード

#### Upload Keystore の作成
```bash
# Upload Keystore を作成
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Base64エンコード
base64 -i upload-keystore.jks > upload-keystore.base64.txt
```

#### Product Flavors の設定
`android/app/build.gradle` を以下のように設定（`build.gradle.example` を参照）：

```gradle
android {
    defaultConfig {
        applicationId "com.example.lakiite"
    }

    // 署名設定
    signingConfigs {
        release {
            storeFile file(System.getenv("ANDROID_UPLOAD_KEYSTORE_PATH") ?: "upload-keystore.jks")
            storePassword System.getenv("ANDROID_UPLOAD_KEYSTORE_PASSWORD")
            keyAlias System.getenv("ANDROID_UPLOAD_KEY_ALIAS")
            keyPassword System.getenv("ANDROID_UPLOAD_KEY_PASSWORD")
        }
    }

    // フレーバー設定
    flavorDimensions "env"
    productFlavors {
        dev {
            dimension "env"
            applicationIdSuffix ".dev"
            versionNameSuffix "-dev"
        }
        prod {
            dimension "env"
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
        }
    }
}
```

### 5. iOS設定

#### App Store Connect API Key の作成（2025年推奨方式）
1. App Store Connect > Users and Access > Integrations > App Store Connect API
2. 「Generate API Key」をクリック
3. Key Name を入力、Access を「App Manager」に設定
4. 生成されたキーをダウンロード（.p8ファイル）
5. Key ID と Issuer ID をメモ

#### Apple Developer設定
1. Apple Developer Portal で App ID を作成（Dev/Prod別々）
2. Distribution証明書を作成
3. Provisioning Profile を作成（Dev/Prod別々）
4. 証明書をP12形式でエクスポート

#### ExportOptions.plist の更新
作成された `ios/DevExportOptions.plist` と `ios/ProdExportOptions.plist` を編集：

```xml
<key>teamID</key>
<string>YOUR_TEAM_ID</string>
<key>provisioningProfiles</key>
<dict>
    <key>com.example.lakiite.dev</key>
    <string>LaKiite Dev Distribution</string>
</dict>
```

#### iOS ターゲット/スキーム分離（推奨）
より安全な運用のため、XcodeでDev/Prod用のターゲットとスキームを分離することを推奨します：

1. Xcodeで `Runner` ターゲットを複製して `RunnerDev` を作成
2. Bundle ID を `com.example.lakiite.dev` に設定
3. 各ターゲット用のスキーム（Dev/Prod）を作成
4. 各スキームで適切なProvisioning Profileを設定

### 6. Dart Define設定

以下のファイルが必要です：
- `dart_define/dev_dart_define.json`
- `dart_define/prod_dart_define.json`

例：
```json
{
  "FLAVOR": "dev",
  "FIREBASE_PROJECT_ID": "your-dev-project-id",
  "API_BASE_URL": "https://dev-api.example.com"
}
```

**重要**: これらのファイルはGitHub Secretsに Base64エンコードして保存し、CI時に動的に復元します。

### 7. FVM設定（オプション）

プロジェクトルートに `.fvmrc` を作成（既存の場合は確認）：

```json
{
  "flutter": "3.24.3"
}
```

**注意**: 現在のプロジェクトでは Flutter 3.24.3 を使用しています。

### 8. Base64エンコード用コマンド

各種ファイルをBase64エンコードする際のコマンド例：

```bash
# ファイルをBase64エンコード
base64 -i input_file > output_file.base64.txt

# 文字列をBase64エンコード
echo "your_string" | base64

# Base64デコード（確認用）
base64 -d input_file.base64.txt > restored_file
```

## 🚀 デプロイメント実行方法

**すべてのワークフローは手動実行（workflow_dispatch）です。**

1. GitHub リポジトリの Actions タブに移動
2. 実行したいワークフローを選択
3. "Run workflow" ボタンをクリック
4. ブランチを選択して実行

### 自動実行への変更（オプション）
自動実行にしたい場合は、各ワークフローファイルの `on:` セクションを以下のように変更してください：

```yaml
# Dev環境: mainブランチへのpush時に自動実行
on:
  push:
    branches: [ main ]
  workflow_dispatch:

# Prod環境: releaseブランチへのpush時に自動実行
on:
  push:
    branches: [ 'release/**' ]
  workflow_dispatch:
```

## 📝 注意事項

### ビルド番号
- `git rev-list --count HEAD` + 10000 をビルド番号として使用
- 必要に応じてオフセット値を調整してください

### タイムアウト
- Dev環境: 30分、Prod環境: 45分でタイムアウト
- iOSのアーカイブ＋アップロードは時間がかかる場合があります

### セキュリティ
- すべての機密情報はGitHub Environments のSecretsに保存
- Prod環境には承認者を設定して人的チェックを必須にする
- Base64エンコードが必要な項目は事前にエンコードしてください

### 2025年の変更点
- **iOS認証**: Apple ID + App用パスワード → App Store Connect API Key
- **Android**: applicationIdSuffix → Product Flavors
- **Secrets管理**: Repository Secrets → GitHub Environments
- **Firebase設定**: 静的ファイル → 動的Base64復元

## 🔗 参考リンク

- [Firebase App Distribution](https://firebase.google.com/docs/app-distribution)
- [Google Play Console API](https://developers.google.com/android-publisher)
- [App Store Connect API](https://developer.apple.com/app-store-connect/api/)
- [GitHub Actions](https://docs.github.com/en/actions)

## 🆘 トラブルシューティング

### よくある問題

1. **ビルドエラー**
   - `flutter pub get` が正常に実行されているか確認
   - `dart_define.json` ファイルの形式が正しいか確認
   - Product Flavors の設定が正しいか確認

2. **署名エラー（iOS）**
   - Provisioning Profile と証明書が一致しているか確認
   - Bundle ID が正しく設定されているか確認
   - App Store Connect API Key の権限が適切か確認

3. **Firebase デプロイエラー**
   - Firebase プロジェクト ID が正しいか確認
   - サービスアカウントの権限が適切か確認
   - `google-services.json` / `GoogleService-Info.plist` が正しく復元されているか確認

4. **Google Play アップロードエラー**
   - パッケージ名が正しいか確認（flavor付きの場合は `.dev` サフィックス確認）
   - API キーの権限が適切か確認（最低「リリース マネージャ」）
   - Upload Keystore の設定が正しいか確認

5. **GitHub Environments エラー**
   - Environment名（dev/prod）が正しく設定されているか確認
   - 各EnvironmentにSecretsが正しく設定されているか確認
   - Prod環境の承認設定が適切か確認

### デバッグ用コマンド

```bash
# Base64エンコードの確認
echo "your_base64_string" | base64 -d | head -c 100

# Firebase設定ファイルの確認
cat android/app/src/dev/google-services.json | jq .project_info.project_id

# Android署名の確認
keytool -list -v -keystore upload-keystore.jks

# iOS証明書の確認
security find-identity -v -p codesigning
```

## 🔄 運用フロー例

### 開発フロー（手動実行）
1. `main` ブランチへマージ
2. GitHub Actions で Dev環境ワークフロー手動実行
3. Firebase App Distribution へ配信
4. 内部テスターによる検証

### リリースフロー（手動実行）
1. `release/*` ブランチ作成
2. GitHub Actions で Prod環境ワークフロー手動実行
3. 承認者による承認（GitHub Environments設定時）
4. Google Play Console / TestFlight へアップロード
5. 段階的ロールアウト

### 自動化フロー（オプション設定後）
上記「自動実行への変更」を適用した場合：
- **Dev**: `main` ブランチへのpush時に自動実行
- **Prod**: `release/*` ブランチへのpush時に自動実行
