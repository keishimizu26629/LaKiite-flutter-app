#!/bin/bash

# LaKiite iOS Base64 Secrets Generator
# このスクリプトは証明書・キー・プロファイルをBase64エンコードしてGitHub Secretsで使用できる形式に変換します

set -e

echo "🔐 LaKiite iOS Base64 Secrets Generator"
echo "======================================"

# 色付きログ用の関数
log_info() {
    echo "ℹ️  $1"
}

log_success() {
    echo "✅ $1"
}

log_error() {
    echo "❌ $1"
}

log_warning() {
    echo "⚠️  $1"
}

# .env.localファイルから設定を読み込み
ENV_FILE="../ios/.env.local"
if [ -f "$ENV_FILE" ]; then
    log_info ".env.localファイルから設定を読み込んでいます..."
    source "$ENV_FILE"
else
    log_error ".env.localファイルが見つかりません: $ENV_FILE"
    log_warning "まず .env.local ファイルを作成してください"
    exit 1
fi

echo ""
echo "📋 Base64エンコード結果"
echo "======================"

# 1. iOS Distribution Certificate
if [ -n "$IOS_CERTIFICATE_PATH" ] && [ -f "$IOS_CERTIFICATE_PATH" ]; then
    log_info "iOS Distribution Certificate をエンコードしています..."
    CERT_BASE64=$(cat "$IOS_CERTIFICATE_PATH" | base64 | tr -d '\n')
    echo ""
    echo "🔑 IOS_CERTIFICATE_BASE64:"
    echo "$CERT_BASE64"
    echo ""
    log_success "iOS Distribution Certificate エンコード完了"
else
    log_error "iOS Distribution Certificate が見つかりません: $IOS_CERTIFICATE_PATH"
fi

# 2. App Store Connect API Key
if [ -n "$ASC_API_KEY_PATH" ] && [ -f "$ASC_API_KEY_PATH" ]; then
    log_info "App Store Connect API Key をエンコードしています..."
    API_KEY_BASE64=$(cat "$ASC_API_KEY_PATH" | base64 | tr -d '\n')
    echo ""
    echo "🔑 ASC_API_KEY_BASE64:"
    echo "$API_KEY_BASE64"
    echo ""
    log_success "App Store Connect API Key エンコード完了"
else
    log_error "App Store Connect API Key が見つかりません: $ASC_API_KEY_PATH"
fi

# 3. Provisioning Profile（複数の場所を確認）
PROFILE_PATHS=(
    "$HOME/Library/MobileDevice/Provisioning Profiles/LaKiite_Dev_App_Store.mobileprovision"
    "$HOME/Library/MobileDevice/Provisioning Profiles/"*.mobileprovision
    "./profile.mobileprovision"
    "../profile.mobileprovision"
)

PROFILE_FOUND=false
for PROFILE_PATH in "${PROFILE_PATHS[@]}"; do
    if [ -f "$PROFILE_PATH" ]; then
        log_info "Provisioning Profile をエンコードしています: $PROFILE_PATH"
        PROFILE_BASE64=$(cat "$PROFILE_PATH" | base64 | tr -d '\n')
        echo ""
        echo "🔑 PROVISIONING_PROFILE_BASE64:"
        echo "$PROFILE_BASE64"
        echo ""
        log_success "Provisioning Profile エンコード完了"
        PROFILE_FOUND=true
        break
    fi
done

if [ "$PROFILE_FOUND" = false ]; then
    log_warning "Provisioning Profile が見つかりません"
    log_info "以下の場所を確認してください:"
    for PROFILE_PATH in "${PROFILE_PATHS[@]}"; do
        echo "  - $PROFILE_PATH"
    done
fi

echo ""
echo "📝 GitHub Secrets設定用コマンド"
echo "=============================="
echo ""
echo "以下のコマンドをGitHub CLIで実行するか、GitHub WebUIで手動設定してください："
echo ""

if [ -n "$CERT_BASE64" ]; then
    echo "# iOS Distribution Certificate"
    echo "gh secret set IOS_CERTIFICATE_BASE64 --body=\"$CERT_BASE64\""
    echo "gh secret set CERT_PWD --body=\"$CERT_PWD\""
    echo ""
fi

if [ -n "$API_KEY_BASE64" ]; then
    echo "# App Store Connect API Key"
    echo "gh secret set ASC_API_KEY_BASE64 --body=\"$API_KEY_BASE64\""
    echo "gh secret set ASC_KEY_ID --body=\"$ASC_KEY_ID\""
    echo "gh secret set ASC_ISSUER_ID --body=\"$ASC_ISSUER_ID\""
    echo ""
fi

if [ -n "$PROFILE_BASE64" ]; then
    echo "# Provisioning Profile"
    echo "gh secret set DEV_PROVISIONING_PROFILE_BASE64 --body=\"$PROFILE_BASE64\""
    echo "gh secret set DEV_PROVISIONING_PROFILE_NAME --body=\"$DEV_PROVISIONING_PROFILE_NAME\""
    echo ""
fi

echo "# App Configuration"
echo "gh secret set DEV_BUNDLE_ID --body=\"$DEV_BUNDLE_ID\""
echo "gh secret set DEVELOPMENT_TEAM --body=\"$DEVELOPMENT_TEAM\""
echo "gh secret set IPA_OUTPUT_NAME --body=\"$IPA_OUTPUT_NAME\""

echo ""
log_success "🎉 Base64エンコード完了！"
echo ""
echo "📋 次のステップ:"
echo "1. 上記のコマンドを実行してGitHub Secretsを設定"
echo "2. Firebase設定ファイルも同様にBase64エンコードして設定"
echo "3. GitHub Actionsワークフローをテスト実行"
echo ""
echo "📚 詳細なドキュメント: docs/GITHUB_SECRETS_BASE64_SETUP.md"
