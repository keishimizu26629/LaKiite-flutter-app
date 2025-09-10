#!/bin/bash

echo "🧪 統合テストの実行を開始します"
echo "=========================================="

# カラーコードの定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 引数の処理
SPECIFIC_TEST=""
DEVICE=""
HELP=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--test)
            SPECIFIC_TEST="$2"
            shift 2
            ;;
        -d|--device)
            DEVICE="$2"
            shift 2
            ;;
        -h|--help)
            HELP=true
            shift
            ;;
        *)
            echo "不明なオプション: $1"
            exit 1
            ;;
    esac
done

if [ "$HELP" = true ]; then
    echo "使用法: $0 [オプション]"
    echo ""
    echo "オプション:"
    echo "  -t, --test FILE     特定のテストファイルを実行"
    echo "  -d, --device ID     特定のデバイスIDを指定"
    echo "  -h, --help          このヘルプを表示"
    echo ""
    echo "例:"
    echo "  $0                                                    # 全ての統合テストを実行"
    echo "  $0 -t signup_navigation_integration_test.dart        # 特定のテストを実行"
    echo "  $0 -d 'iPhone 15 Pro'                               # 特定のデバイスで実行"
    exit 0
fi

# ステップ1: 環境セットアップ
echo -e "\n${BLUE}📋 Step 1: 環境セットアップ${NC}"
echo "----------------------------------------"

if [ ! -f "./scripts/setup_integration_test.sh" ]; then
    echo -e "${RED}❌ セットアップスクリプトが見つかりません${NC}"
    exit 1
fi

echo "🔧 シミュレーター権限の設定中..."
./scripts/setup_integration_test.sh

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ 環境セットアップに失敗しました${NC}"
    exit 1
fi

# ステップ2: テスト実行
echo -e "\n${BLUE}📋 Step 2: テスト実行${NC}"
echo "----------------------------------------"

# デバイス指定の処理
DEVICE_FLAG=""
if [ -n "$DEVICE" ]; then
    DEVICE_FLAG="-d \"$DEVICE\""
    echo "📱 指定デバイス: $DEVICE"
fi

# テストファイルの指定
if [ -n "$SPECIFIC_TEST" ]; then
    if [ ! -f "integration_test/$SPECIFIC_TEST" ]; then
        echo -e "${RED}❌ テストファイルが見つかりません: integration_test/$SPECIFIC_TEST${NC}"
        exit 1
    fi

    echo "🧪 特定のテストを実行: $SPECIFIC_TEST"
    TEST_TARGET="integration_test/$SPECIFIC_TEST"
else
    echo "🧪 全ての統合テストを実行"
    TEST_TARGET="integration_test"
fi

# テスト実行
echo -e "\n${YELLOW}🚀 テスト実行中...${NC}"
echo "コマンド: flutter test $TEST_TARGET --dart-define=TEST_MODE=true $DEVICE_FLAG"

eval "flutter test $TEST_TARGET --dart-define=TEST_MODE=true $DEVICE_FLAG"
TEST_RESULT=$?

# 結果表示
echo -e "\n${BLUE}📋 テスト結果${NC}"
echo "=========================================="

if [ $TEST_RESULT -eq 0 ]; then
    echo -e "${GREEN}✅ 全てのテストが成功しました！${NC}"
else
    echo -e "${RED}❌ テストが失敗しました (終了コード: $TEST_RESULT)${NC}"
    echo ""
    echo -e "${YELLOW}🔍 トラブルシューティング:${NC}"
    echo "1. シミュレーターが起動していることを確認"
    echo "2. アプリが正しくビルドされていることを確認"
    echo "3. Firebase設定が正しいことを確認"
    echo "4. 個別のテストファイルで詳細を確認:"
    echo "   flutter test integration_test/signup_navigation_integration_test.dart --dart-define=TEST_MODE=true -v"
fi

echo ""
echo -e "${BLUE}📋 その他の有用なコマンド:${NC}"
echo "- ログ詳細表示: flutter test [テストファイル] --dart-define=TEST_MODE=true -v"
echo "- 特定デバイス指定: flutter test [テストファイル] --dart-define=TEST_MODE=true -d 'iPhone 15 Pro'"
echo "- デバイス一覧表示: flutter devices"

exit $TEST_RESULT
