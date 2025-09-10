#!/bin/bash

# プッシュ通知テスト用スクリプト
# 使用方法: ./scripts/test_push_notification.sh

set -e

# 設定
PROJECT_ID="lakiite-flutter-app-dev"
FCM_TOKEN="fF_Zd9PCkk54lgYQuf3RmA:APA91bGoTUfhTCGXyNqFz9kvU72DLBxinu0GXuFeJSEP6U4jQLDtwd75Xdn4tjPqNNkH0YilN8pEwID67gGVjlW2I_f8AbfBthpfU0zAk2K86qSErn7wloI"

echo "🚀 プッシュ通知テストを開始します..."
echo "📱 プロジェクトID: $PROJECT_ID"
echo "🔑 FCMトークン: ${FCM_TOKEN:0:50}..."

# Google Cloud認証の確認
echo "🔐 Google Cloud認証を確認中..."
if ! gcloud auth print-access-token > /dev/null 2>&1; then
    echo "❌ Google Cloud認証が必要です。以下を実行してください:"
    echo "   gcloud auth login"
    echo "   gcloud config set project $PROJECT_ID"
    exit 1
fi

# アクセストークンを取得
echo "🔑 アクセストークンを取得中..."
ACCESS_TOKEN=$(gcloud auth print-access-token)
echo "✅ アクセストークン取得完了"

# テスト1: 基本的な通知
echo ""
echo "📢 テスト1: 基本的な通知を送信中..."
RESPONSE1=$(curl -s -X POST \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json; charset=utf-8" \
  https://fcm.googleapis.com/v1/projects/$PROJECT_ID/messages:send \
  -d '{
    "message": {
      "token": "'$FCM_TOKEN'",
      "notification": {
        "title": "🧪 cURLテスト通知",
        "body": "cURLスクリプトから送信されたプッシュ通知です"
      }
    }
  }')

if echo "$RESPONSE1" | grep -q '"name"'; then
    echo "✅ テスト1成功: 基本的な通知送信完了"
    echo "📋 レスポンス: $RESPONSE1"
else
    echo "❌ テスト1失敗: $RESPONSE1"
fi

# 3秒待機
sleep 3

# テスト2: データペイロード付き通知
echo ""
echo "📢 テスト2: データペイロード付き通知を送信中..."
RESPONSE2=$(curl -s -X POST \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json; charset=utf-8" \
  https://fcm.googleapis.com/v1/projects/$PROJECT_ID/messages:send \
  -d '{
    "message": {
      "token": "'$FCM_TOKEN'",
      "notification": {
        "title": "👥 友達申請テスト",
        "body": "cURLテストユーザーから友達申請が届いています"
      },
      "data": {
        "type": "friend_request",
        "fromUserId": "curl-test-user-123",
        "fromUserName": "cURLテストユーザー",
        "timestamp": "'$(date +%s)000'"
      }
    }
  }')

if echo "$RESPONSE2" | grep -q '"name"'; then
    echo "✅ テスト2成功: データペイロード付き通知送信完了"
    echo "📋 レスポンス: $RESPONSE2"
else
    echo "❌ テスト2失敗: $RESPONSE2"
fi

# 3秒待機
sleep 3

# テスト3: データ専用メッセージ
echo ""
echo "📢 テスト3: データ専用メッセージを送信中..."
RESPONSE3=$(curl -s -X POST \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json; charset=utf-8" \
  https://fcm.googleapis.com/v1/projects/$PROJECT_ID/messages:send \
  -d '{
    "message": {
      "token": "'$FCM_TOKEN'",
      "data": {
        "type": "reaction",
        "fromUserId": "curl-test-user-456",
        "scheduleId": "curl-schedule-789",
        "reactionType": "like",
        "timestamp": "'$(date +%s)000'"
      }
    }
  }')

if echo "$RESPONSE3" | grep -q '"name"'; then
    echo "✅ テスト3成功: データ専用メッセージ送信完了"
    echo "📋 レスポンス: $RESPONSE3"
else
    echo "❌ テスト3失敗: $RESPONSE3"
fi

echo ""
echo "🎉 プッシュ通知テスト完了！"
echo "📱 アプリのデバッグコンソールで通知受信ログを確認してください。"
echo ""
echo "期待されるログ例:"
echo "📱 フォアグラウンドで通知を受信: [messageId]"
echo "📱 通知タイトル: 🧪 cURLテスト通知"
echo "📱 通知本文: cURLスクリプトから送信されたプッシュ通知です"
echo "🔄 通知メッセージの処理を開始"
