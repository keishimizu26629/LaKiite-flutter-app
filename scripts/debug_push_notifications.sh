#!/bin/bash

echo "🔍 iOS プッシュ通知設定の診断スクリプト"
echo "================================================"

# カラーコードの定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "\n${BLUE}1. Info.plist の確認${NC}"
echo "----------------------------------------"
if grep -q "aps-environment" ios/Runner/Info.plist; then
    env=$(grep -A1 "aps-environment" ios/Runner/Info.plist | grep "<string>" | sed 's/.*<string>\(.*\)<\/string>.*/\1/')
    if [ "$env" = "production" ]; then
        echo -e "✅ aps-environment: ${GREEN}$env${NC} (TestFlight/App Store対応)"
    elif [ "$env" = "development" ]; then
        echo -e "⚠️  aps-environment: ${YELLOW}$env${NC} (開発用：TestFlightでは動作しません)"
    else
        echo -e "❌ aps-environment: ${RED}$env${NC} (不正な値)"
    fi
else
    echo -e "❌ ${RED}aps-environment が見つかりません${NC}"
fi

if grep -q "remote-notification" ios/Runner/Info.plist; then
    echo -e "✅ ${GREEN}UIBackgroundModes で remote-notification が設定済み${NC}"
else
    echo -e "❌ ${RED}UIBackgroundModes で remote-notification が未設定${NC}"
fi

echo -e "\n${BLUE}2. Entitlements の確認${NC}"
echo "----------------------------------------"
if [ -f "ios/Runner/Runner.entitlements" ]; then
    env=$(grep -A1 "aps-environment" ios/Runner/Runner.entitlements | grep "<string>" | sed 's/.*<string>\(.*\)<\/string>.*/\1/')
    if [ "$env" = "production" ]; then
        echo -e "✅ aps-environment: ${GREEN}$env${NC} (TestFlight/App Store対応)"
    elif [ "$env" = "development" ]; then
        echo -e "⚠️  aps-environment: ${YELLOW}$env${NC} (開発用：TestFlightでは動作しません)"
    else
        echo -e "❌ aps-environment: ${RED}$env${NC} (不正な値)"
    fi
else
    echo -e "❌ ${RED}Runner.entitlements が見つかりません${NC}"
fi

echo -e "\n${BLUE}3. Firebase設定の確認${NC}"
echo "----------------------------------------"
if [ -f "ios/Runner/GoogleService-Info.plist" ]; then
    echo -e "✅ ${GREEN}GoogleService-Info.plist が存在${NC}"
    bundle_id=$(grep -A1 "BUNDLE_ID" ios/Runner/GoogleService-Info.plist | grep "<string>" | sed 's/.*<string>\(.*\)<\/string>.*/\1/')
    echo "   Bundle ID: $bundle_id"
    project_id=$(grep -A1 "PROJECT_ID" ios/Runner/GoogleService-Info.plist | grep "<string>" | sed 's/.*<string>\(.*\)<\/string>.*/\1/')
    echo "   Project ID: $project_id"
else
    echo -e "❌ ${RED}GoogleService-Info.plist が見つかりません${NC}"
fi

echo -e "\n${BLUE}4. Podfile の確認${NC}"
echo "----------------------------------------"
if grep -q "firebase_messaging" ios/Podfile.lock 2>/dev/null; then
    version=$(grep "firebase_messaging" ios/Podfile.lock | head -1 | sed 's/.*(\(.*\)).*/\1/')
    echo -e "✅ ${GREEN}firebase_messaging が組み込み済み${NC} (バージョン: $version)"
else
    echo -e "❌ ${RED}firebase_messaging が見つかりません${NC}"
fi

echo -e "\n${BLUE}5. 必要な作業${NC}"
echo "----------------------------------------"
echo "1. 以下の設定が production になっていることを確認："
echo "   - Info.plist の aps-environment"
echo "   - Runner.entitlements の aps-environment"
echo ""
echo "2. Xcode で Signing & Capabilities タブを確認："
echo "   - Push Notifications が追加されている"
echo "   - Background Modes → Remote notifications にチェック"
echo ""
echo "3. プロビジョニングプロファイルの確認："
echo "   - Push Notifications が有効になっている"
echo "   - TestFlight 用の Ad Hoc または App Store プロファイル"
echo ""
echo "4. Firebase Console での確認："
echo "   - iOS APNs証明書またはキーが正しく設定されている"
echo "   - Production環境用の証明書/キーであること"
echo ""
echo "5. 動作確認："
echo "   - Xcode コンソールで APNs トークンが取得できているか"
echo "   - Firebase Console の Messaging で直接送信テスト"
echo ""
echo -e "${YELLOW}このスクリプト実行後、TestFlight で再ビルド・アップロードが必要です${NC}"
