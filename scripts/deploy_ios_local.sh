#!/bin/bash
set -e

echo "🚀 LaKiite iOS Local Deployment Script"
echo "======================================"

# 引数の解析
ENVIRONMENT=$1

if [ -z "$ENVIRONMENT" ] || ([ "$ENVIRONMENT" != "dev" ] && [ "$ENVIRONMENT" != "prod" ]); then
    echo "❌ Usage: $0 <dev|prod>"
    echo "📝 Example: $0 dev"
    exit 1
fi

# プロジェクトルートに移動
cd "$(dirname "$0")/.."
PROJECT_ROOT="$(pwd)"

echo "✅ Environment: $ENVIRONMENT"
echo "📁 Working directory: $PROJECT_ROOT"

# 必要なファイルの確認
if [ ! -f "dart_define/${ENVIRONMENT}_dart_define.json" ]; then
    echo "❌ dart_define/${ENVIRONMENT}_dart_define.json not found!"
    echo "📝 Please create the dart-define configuration file"
    exit 1
fi

# Firebase設定ファイルのパスを決定
if [ "$ENVIRONMENT" == "dev" ]; then
    FIREBASE_CONFIG_PATH="ios/Runner/Firebase/Dev/GoogleService-Info.plist"
else
    FIREBASE_CONFIG_PATH="ios/Runner/Firebase/Prod/GoogleService-Info.plist"
fi

if [ ! -f "$FIREBASE_CONFIG_PATH" ]; then
    echo "❌ Firebase configuration not found for $ENVIRONMENT"
    echo "📝 Expected: $FIREBASE_CONFIG_PATH"
    exit 1
fi

# Firebase設定ファイルをコピー
echo "🔥 Setting up Firebase configuration for $ENVIRONMENT..."
cp "$FIREBASE_CONFIG_PATH" "ios/Runner/GoogleService-Info.plist"

# iOS証明書とプロビジョニングプロファイルの確認
echo "🔐 Checking iOS certificates and provisioning profiles..."

# Keychain内の証明書確認
if ! security find-identity -v -p codesigning | grep -q "Apple Distribution"; then
    echo "⚠️  Apple Distribution certificate not found in keychain"
    echo "📝 Please ensure your distribution certificate is installed"
fi

# プロビジョニングプロファイルの確認
PROFILE_DIR="$HOME/Library/MobileDevice/Provisioning Profiles"
if [ "$ENVIRONMENT" == "dev" ]; then
    EXPECTED_PROFILE="LaKiite_Dev_App_Store"
else
    EXPECTED_PROFILE="LaKiite_Prod_App_Store"
fi

echo "📄 Looking for provisioning profile: $EXPECTED_PROFILE"
if [ -d "$PROFILE_DIR" ]; then
    PROFILE_COUNT=$(find "$PROFILE_DIR" -name "*.mobileprovision" | wc -l)
    echo "📊 Found $PROFILE_COUNT provisioning profiles in $PROFILE_DIR"
else
    echo "⚠️  Provisioning profiles directory not found: $PROFILE_DIR"
fi

# App Store Connect API Key の確認
API_KEY_FILE="$HOME/Downloads/AuthKey_96BH437MBD.p8"
if [ ! -f "$API_KEY_FILE" ]; then
    echo "⚠️  App Store Connect API Key not found"
    echo "📝 Expected: $API_KEY_FILE"
    echo "💡 You can download it from App Store Connect → Users and Access → Keys"
else
    echo "✅ App Store Connect API Key found"
    # API Keyをiosディレクトリにコピー
    cp "$API_KEY_FILE" "ios/AuthKey.p8"
fi

# fastlaneの実行
echo "🔨 Starting fastlane deployment for $ENVIRONMENT..."
cd ios

# 環境変数ファイルの読み込み（最初に実行）
ENV_FILE="$PROJECT_ROOT/ios/.env.local"
if [ -f "$ENV_FILE" ]; then
    echo "📄 Loading environment variables from $ENV_FILE"
    export $(grep -v '^#' "$ENV_FILE" | xargs)
else
    echo "⚠️  Environment file not found: $ENV_FILE"
    echo "   Please create .env.local file or set environment variables manually"
fi

# 環境変数の設定
export FASTLANE_DISABLE_PTY=1
export FASTLANE_EXPLICIT_OPEN3=1
export FASTLANE_DISABLE_COLORS=1
export CI=1

# UTF-8エンコーディング設定
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# 必須環境変数のチェック
if [ -z "$CERT_PWD" ]; then
    echo "❌ CERT_PWD environment variable is required"
    echo "   Set it in .env.local or export CERT_PWD=\"your_password\""
    exit 1
fi

# App Store Connect API設定チェック（.env.localから読み込み済み）
if [ -z "$ASC_KEY_ID" ] || [ -z "$ASC_ISSUER_ID" ]; then
    echo "❌ ASC_KEY_ID and ASC_ISSUER_ID environment variables are required"
    echo "   Set them in .env.local or export manually"
    exit 1
fi

# SSL証明書の設定
export SSL_CERT_FILE="/opt/homebrew/etc/ca-certificates/cert.pem"
export SSL_CERT_DIR="/opt/homebrew/etc/openssl@3/certs"

# fastlane実行
if [ "$ENVIRONMENT" == "dev" ]; then
    fastlane dev
else
    fastlane prod
fi

echo ""
echo "🎉 Deployment completed!"
echo "📱 Check TestFlight for the new build"
echo "🔍 Build should appear in App Store Connect within 5-10 minutes"
