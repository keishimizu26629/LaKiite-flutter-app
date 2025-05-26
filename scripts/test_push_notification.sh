#!/bin/bash

echo "📱 プッシュ通知テストガイド"
echo "================================================"

# カラーコードの定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "\n${BLUE}🔧 準備手順${NC}"
echo "----------------------------------------"
echo "1. アプリをTestFlightでインストール"
echo "2. アプリを起動してログイン"
echo "3. プッシュ通知の許可をタップ"
echo "4. アプリをバックグラウンドまたは完全に閉じる"

echo -e "\n${BLUE}📋 Xcodeログで確認すべき項目${NC}"
echo "----------------------------------------"
echo -e "${GREEN}✅ 成功パターン:${NC}"
echo '   ✅ APNsデバイストークン登録成功: [64文字のhex文字列]'
echo '   🔑 FCMトークン受信: [長いトークン文字列]'
echo '   通知許可ステータス: true, エラー: nil'
echo ""
echo -e "${RED}❌ 失敗パターン:${NC}"
echo '   ❌ リモート通知の登録に失敗: [エラーメッセージ]'
echo '   ⚠️  プッシュ通知の許可が拒否されました'
echo '   APNSトークンがnullです。プッシュ通知が機能しない可能性があります。'

echo -e "\n${BLUE}🧪 Firebase Console でのテスト手順${NC}"
echo "----------------------------------------"
echo "1. Firebase Console にアクセス"
echo "2. プロジェクト 'tarakite-flutter-app-dev' を選択"
echo "3. 左メニューの「Messaging」をクリック"
echo "4. 「新しいキャンペーンを作成」→「Firebase Cloud Messaging」"
echo "5. 通知テキストを入力:"
echo "   - タイトル: テスト通知"
echo "   - 本文: プッシュ通知のテストです"
echo "6. 「テストメッセージを送信」をクリック"
echo "7. FCMトークンを入力（Xcodeログから取得）"
echo "8. 「テスト」をクリック"

echo -e "\n${BLUE}🔍 トラブルシューティング${NC}"
echo "----------------------------------------"
echo -e "${YELLOW}トークンが取得できない場合:${NC}"
echo "• Xcodeプロジェクトを開いて Capabilities を確認"
echo "• Push Notifications が追加されているか"
echo "• Background Modes → Remote notifications がONか"
echo "• プロビジョニングプロファイルが最新か"
echo ""
echo -e "${YELLOW}トークンは取得できるが通知が届かない場合:${NC}"
echo "• Firebase Console で APNs 認証キー/証明書を確認"
echo "• Production環境用の設定になっているか"
echo "• Bundle ID が一致しているか"
echo "• デバイスがTestFlightビルドを使用しているか"
echo ""
echo -e "${YELLOW}通知は届くがアプリで処理されない場合:${NC}"
echo "• AppDelegate の UNUserNotificationCenterDelegate メソッドが実装されているか"
echo "• Firebase Messaging の onMessage, onBackgroundMessage ハンドラーが設定されているか"

echo -e "\n${BLUE}📱 実際のテスト実行${NC}"
echo "----------------------------------------"
echo "以下の手順で実際にテストしてください:"
echo ""
echo "1. アプリを TestFlight から起動"
echo "2. ログインして通知許可を与える"
echo "3. Xcode の「Window」→「Devices and Simulators」"
echo "4. テストデバイスを選択して「Open Console」"
echo "5. アプリ名で検索してログを確認"
echo "6. Firebase Console でテスト通知を送信"
echo "7. 通知が届くか確認"
echo ""
echo -e "${GREEN}テスト成功の条件:${NC}"
echo "• アプリがバックグラウンド時に通知バナーが表示される"
echo "• 通知をタップするとアプリが開く"
echo "• アプリがフォアグラウンド時は willPresent メソッドが呼ばれる"
echo ""
echo -e "${RED}注意: 設定変更後は必ず新しいビルドをTestFlightにアップロードしてください${NC}"
