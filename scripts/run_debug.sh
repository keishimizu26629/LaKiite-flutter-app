#!/bin/bash

# スクリプトのパス
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# プロジェクトのルートディレクトリ
PROJECT_ROOT="$SCRIPT_DIR/.."

cd "$PROJECT_ROOT" || exit 1

echo "Preparing development environment..."

# 開発環境用アイコンを生成
fvm flutter pub run scripts/create_dev_icon.dart

# 開発環境用アイコンを適用
fvm flutter pub run flutter_launcher_icons:main -f flutter_launcher_icons-development.yaml

echo "Running app in debug mode..."
fvm flutter run --debug
