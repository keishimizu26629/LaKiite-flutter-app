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
    EXPECTED_PROFILE="LaKiite Dev App Store"
else
    EXPECTED_PROFILE="LaKiite Prod App Store"
fi

echo "📄 Looking for provisioning profile: $EXPECTED_PROFILE"
if [ -d "$PROFILE_DIR" ]; then
    PROFILE_COUNT=$(find "$PROFILE_DIR" -name "*.mobileprovision" | wc -l)
    echo "📊 Found $PROFILE_COUNT provisioning profiles in $PROFILE_DIR"
else
    echo "⚠️  Provisioning profiles directory not found: $PROFILE_DIR"
fi

# 環境変数ファイルの読み込み
ENV_FILE="$PROJECT_ROOT/ios/.env.local"
if [ -f "$ENV_FILE" ]; then
    echo "📄 Loading environment variables from $ENV_FILE"
    set -a
    source "$ENV_FILE"
    set +a
else
    echo "⚠️  Environment file not found: $ENV_FILE"
    echo "   Please create .env.local file or set environment variables manually"
fi

# UTF-8エンコーディング設定
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# App Store Connect API設定チェック（.env.localから読み込み済み）
if [ -z "$ASC_KEY_ID" ] || [ -z "$ASC_ISSUER_ID" ]; then
    echo "❌ ASC_KEY_ID and ASC_ISSUER_ID environment variables are required"
    echo "   Set them in .env.local or export manually"
    exit 1
fi

# App Store Connect API Key の確認
API_KEY_FILE="${ASC_API_KEY_PATH:-$HOME/Downloads/AuthKey_${ASC_KEY_ID}.p8}"
if [ ! -f "$API_KEY_FILE" ]; then
    echo "❌ App Store Connect API Key not found"
    echo "📝 Expected: $API_KEY_FILE"
    echo "💡 You can download it from App Store Connect → Users and Access → Keys"
    exit 1
fi

mkdir -p private_keys
cp "$API_KEY_FILE" "private_keys/AuthKey_${ASC_KEY_ID}.p8"
chmod 600 "private_keys/AuthKey_${ASC_KEY_ID}.p8"
echo "✅ App Store Connect API Key prepared"

if [ "$ENVIRONMENT" == "dev" ]; then
    EXPORT_OPTIONS_PLIST="ios/DevExportOptions.plist"
    XCODE_SCHEME="dev"
    XCODE_CONFIGURATION="Release-dev"
else
    EXPORT_OPTIONS_PLIST="ios/ProdExportOptions.plist"
    XCODE_SCHEME="prod"
    XCODE_CONFIGURATION="Release-prod"
fi

cp "$EXPORT_OPTIONS_PLIST" "ios/ExportOptions.plist"

echo "🔎 Checking Xcode signing settings..."
xcodebuild -project ios/Runner.xcodeproj \
    -scheme "$XCODE_SCHEME" \
    -configuration "$XCODE_CONFIGURATION" \
    -showBuildSettings | grep -E "PRODUCT_BUNDLE_IDENTIFIER|DEVELOPMENT_TEAM|CODE_SIGN_STYLE|CODE_SIGN_IDENTITY|PROVISIONING_PROFILE_SPECIFIER"

FLUTTER_CMD=(flutter)
if command -v fvm >/dev/null 2>&1; then
    FLUTTER_CMD=(fvm flutter)
fi

BUILD_NUMBER="${BUILD_NUMBER:-$(date +%s)}"
echo "🔢 Build number: $BUILD_NUMBER"

echo "🔨 Building IPA for $ENVIRONMENT..."
"${FLUTTER_CMD[@]}" build ipa --release \
    --flavor "$ENVIRONMENT" \
    --export-options-plist="ios/ExportOptions.plist" \
    --dart-define-from-file="dart_define/${ENVIRONMENT}_dart_define.json" \
    -t "lib/main.dart" \
    --build-number "$BUILD_NUMBER"

echo "📤 Uploading IPA to TestFlight..."
IPA_FILE=$(ls ./build/ios/ipa/*.ipa | head -n 1)
xcrun altool --upload-app \
    -t ios \
    -f "$IPA_FILE" \
    --apiKey "$ASC_KEY_ID" \
    --apiIssuer "$ASC_ISSUER_ID"

echo ""
echo "🎉 Deployment completed!"
echo "📱 Check TestFlight for the new build"
echo "🔍 Build should appear in App Store Connect within 5-10 minutes"
