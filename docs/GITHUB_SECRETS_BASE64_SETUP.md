---
title: "GitHub Secrets Base64設定ガイド"
created: 2025-11-18T05:28:05
updated: 2025-11-18T05:28:05
tags:
  - github-actions
  - ci-cd
  - ios-deployment
  - base64
---

# GitHub Secrets Base64設定ガイド

## 🎯 概要

このドキュメントでは、LaKiiteアプリのGitHub ActionsでiOS自動デプロイを行うために必要なBase64エンコードされた証明書・キー・プロファイルの設定方法を説明します。

## 📋 必要なファイル

### 1. iOS Distribution Certificate (.p12)
- **ファイル名**: `ios_distribution_certificate.p12`
- **場所**: `~/Desktop/` または任意の場所
- **用途**: アプリの署名に使用

### 2. App Store Connect API Key (.p8)
- **ファイル名**: `AuthKey_96BH437MBD.p8`
- **場所**: `~/Downloads/` または任意の場所
- **用途**: App Store Connect APIアクセス

### 3. Provisioning Profile (.mobileprovision)
- **ファイル名**: `LaKiite_Dev_App_Store.mobileprovision`
- **場所**: `~/Library/MobileDevice/Provisioning Profiles/` または任意の場所
- **用途**: アプリのプロビジョニング

## 🔧 Base64エンコード手順

### macOS/Linux環境

```bash
# 1. iOS Distribution Certificate
cat ~/Desktop/ios_distribution_certificate.p12 | base64 | tr -d '\n'

# 2. App Store Connect API Key
cat ~/Downloads/AuthKey_96BH437MBD.p8 | base64 | tr -d '\n'

# 3. Provisioning Profile
cat ~/Library/MobileDevice/Provisioning\ Profiles/LaKiite_Dev_App_Store.mobileprovision | base64 | tr -d '\n'
```

### Windows環境

```cmd
# PowerShellを使用
[Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\path\to\file"))

# または certutil コマンド
certutil -encode input_file output_file
```

## 🔐 GitHub Secrets設定

### 必須のSecrets

GitHub リポジトリの Settings → Secrets and variables → Actions で以下を設定：

#### 証明書関連
```
IOS_CERTIFICATE_BASE64=<Base64エンコードされた.p12ファイル>
CERT_PWD=<.p12ファイルのパスワード>
```

#### App Store Connect API関連
```
ASC_API_KEY_BASE64=<Base64エンコードされた.p8ファイル>
ASC_KEY_ID=96BH437MBD
ASC_ISSUER_ID=fb6d96bf-4445-47cc-9b10-0e917c992edf
```

#### プロビジョニングプロファイル関連
```
DEV_PROVISIONING_PROFILE_BASE64=<Base64エンコードされた.mobileprovisionファイル>
DEV_PROVISIONING_PROFILE_NAME=LaKiite Dev App Store
```

#### アプリ設定
```
DEV_BUNDLE_ID=com.inoworl.lakiite.dev
DEVELOPMENT_TEAM=T6ZYALKC4V
IPA_OUTPUT_NAME=LaKiite-Dev
```

#### Firebase設定
```
DEV_GOOGLESERVICE_INFO_PLIST_BASE64=<Base64エンコードされたGoogleService-Info.plist>
DEV_DART_DEFINE_JSON_BASE64=<Base64エンコードされたdev_dart_define.json>
```

## 🔄 ローカル開発との互換性

### ローカル開発時
- `.env.local`ファイルでローカルファイルパスを指定
- Base64フィールドは空のままでOK

```bash
# .env.local（ローカル開発用）
IOS_CERTIFICATE_PATH=~/Desktop/ios_distribution_certificate.p12
ASC_API_KEY_PATH=~/Downloads/AuthKey_96BH437MBD.p8
PROVISIONING_PROFILE_BASE64=  # 空のまま
```

### GitHub Actions時
- GitHub Secretsでbase64文字列を設定
- ローカルファイルパスは無視される

```yaml
# GitHub Actions環境変数
IOS_CERTIFICATE_BASE64: ${{ secrets.IOS_CERTIFICATE_BASE64 }}
ASC_API_KEY_BASE64: ${{ secrets.ASC_API_KEY_BASE64 }}
PROVISIONING_PROFILE_BASE64: ${{ secrets.DEV_PROVISIONING_PROFILE_BASE64 }}
```

## 🚀 動作フロー

### 1. ローカル開発
```
1. .env.localファイルを読み込み
2. ローカルファイルパス（*_PATH）を優先使用
3. Base64フィールドが空の場合はローカルファイルを使用
```

### 2. GitHub Actions
```
1. GitHub Secretsから環境変数を設定
2. Base64フィールドが設定されている場合はデコードして一時ファイル作成
3. 一時ファイルを使用してビルド・デプロイ実行
```

## 🔍 トラブルシューティング

### Base64エンコードエラー
```bash
# 改行文字を除去
cat file | base64 | tr -d '\n'

# ファイルサイズ確認
ls -la file
```

### GitHub Secrets設定確認
```yaml
# ワークフローでSecrets確認（デバッグ用）
- name: Check secrets
  run: |
    echo "Certificate length: ${#IOS_CERTIFICATE_BASE64}"
    echo "API Key length: ${#ASC_API_KEY_BASE64}"
```

### ファイル権限エラー
```bash
# 証明書ファイルの権限確認
chmod 600 ~/Desktop/ios_distribution_certificate.p12
```

## 📚 関連ファイル

- `env.template` - 環境変数テンプレート
- `ios/fastlane/Fastfile` - Fastlane設定
- `.github/workflows/deploy_dev_ios.yml` - GitHub Actionsワークフロー
- `scripts/deploy_ios_local.sh` - ローカルデプロイスクリプト

## 🔒 セキュリティ注意事項

1. **Base64文字列は機密情報** - GitHub Secretsでのみ管理
2. **ローカルファイルは.gitignore** - 証明書ファイルをコミットしない
3. **定期的な更新** - 証明書の有効期限を確認
4. **アクセス制限** - GitHub Secretsへのアクセス権限を適切に管理

## 📝 更新履歴

- 2025-11-18: 初版作成、Base64対応実装
