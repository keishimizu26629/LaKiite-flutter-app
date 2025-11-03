#!/bin/bash

# Git Hooks自動削除機能のセットアップスクリプト

set -e

echo "🔧 Git Hooks自動削除機能のセットアップを開始..."

# 1. 必要なツールのチェック
echo "📋 必要なツールをチェック中..."

if ! command -v gh >/dev/null 2>&1; then
    echo "❌ GitHub CLI (gh) が見つかりません"
    echo "💡 インストール方法: brew install gh"
    exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
    echo "❌ jq が見つかりません"
    echo "💡 インストール方法: brew install jq"
    exit 1
fi

echo "✅ 必要なツールが揃っています"

# 2. GitHub CLI認証チェック
echo "🔐 GitHub CLI認証をチェック中..."
if ! gh auth status >/dev/null 2>&1; then
    echo "❌ GitHub CLIが認証されていません"
    echo "💡 認証方法: gh auth login"
    exit 1
fi

echo "✅ GitHub CLI認証済み"

# 3. 設定ファイルの確認
config_file=".git/hooks/auto-delete-config"
if [ ! -f "$config_file" ]; then
    echo "📝 設定ファイルを作成中..."
    # 設定ファイルは既に作成済み
else
    echo "✅ 設定ファイル確認済み"
fi

# 4. Hookファイルの確認
hook_file=".git/hooks/post-checkout"
if [ ! -f "$hook_file" ]; then
    echo "❌ post-checkout hookが見つかりません"
    echo "💡 先にhookファイルを作成してください"
    exit 1
fi

if [ ! -x "$hook_file" ]; then
    echo "🔧 hookファイルに実行権限を付与中..."
    chmod +x "$hook_file"
fi

echo "✅ post-checkout hook確認済み"

# 5. テスト実行
echo "🧪 動作テストを実行中..."

# テスト用ブランチを作成
test_branch="test/hook-setup-$(date +%s)"
git checkout -b "$test_branch" >/dev/null 2>&1

# テストファイルを作成
echo "# Hook test" > hook-test.txt
git add hook-test.txt
git commit -m "test: hook setup test" >/dev/null 2>&1

# mainに戻る（hookがトリガーされる）
echo "🔄 hookテスト実行中..."
git checkout main >/dev/null 2>&1

# テストブランチを削除
git branch -D "$test_branch" >/dev/null 2>&1
rm -f hook-test.txt

echo "✅ 動作テスト完了"

# 6. 使用方法の説明
echo ""
echo "🎉 セットアップ完了！"
echo ""
echo "📖 使用方法:"
echo "  1. 通常通りブランチで作業"
echo "  2. PRを作成・マージ"
echo "  3. mainブランチに切り替え → 自動削除実行"
echo ""
echo "⚙️ 設定変更:"
echo "  設定ファイル: .git/hooks/auto-delete-config"
echo ""
echo "📊 削除ログ:"
echo "  ログファイル: .git/auto-delete.log"
echo ""
echo "🔧 手動実行:"
echo "  ./scripts/smart_branch_cleanup.sh"
echo ""
echo "✨ 自動削除機能が有効になりました！"
