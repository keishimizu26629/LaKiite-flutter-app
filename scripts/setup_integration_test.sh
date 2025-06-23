#!/bin/bash

echo "🧪 統合テスト環境のセットアップを開始します"

# Bundle ID
BUNDLE_ID="com.inoworl.lakiite"

# 現在起動中のシミュレーターのDevice IDを取得
DEVICE_ID=$(xcrun simctl list devices | grep "Booted" | head -1 | sed 's/.*(\([^)]*\)).*/\1/')

if [ -z "$DEVICE_ID" ]; then
    echo "❌ 起動中のシミュレーターが見つかりません"
    echo "💡 Xcodeでシミュレーターを起動してから再実行してください"
    exit 1
fi

echo "📱 シミュレーター Device ID: $DEVICE_ID"
echo "📦 Bundle ID: $BUNDLE_ID"

# 通知許可を事前に付与
echo "🔔 通知許可を事前に付与中..."
xcrun simctl privacy "$DEVICE_ID" grant notifications "$BUNDLE_ID"

if [ $? -eq 0 ]; then
    echo "✅ 通知許可の付与が完了しました"
else
    echo "⚠️ 通知許可の付与に失敗しました（アプリがインストールされていない可能性があります）"
    echo "💡 アプリを一度起動してから再実行してください"
fi

# その他の権限も事前に付与
echo "📸 カメラ権限を事前に付与中..."
xcrun simctl privacy "$DEVICE_ID" grant camera "$BUNDLE_ID"

echo "🖼️ 写真権限を事前に付与中..."
xcrun simctl privacy "$DEVICE_ID" grant photos "$BUNDLE_ID"

echo "📍 位置情報権限を事前に付与中..."
xcrun simctl privacy "$DEVICE_ID" grant location "$BUNDLE_ID"

echo ""
echo "🎉 統合テスト環境のセットアップが完了しました"
echo ""
echo "📋 次の手順:"
echo "1. 以下のコマンドでテストを実行:"
echo "   flutter test integration_test --dart-define=TEST_MODE=true"
echo ""
echo "2. または、個別のテストファイルを実行:"
echo "   flutter test integration_test/signup_navigation_integration_test.dart --dart-define=TEST_MODE=true"
echo "   flutter test integration_test/schedule_flow_integration_test.dart --dart-define=TEST_MODE=true"
echo ""
