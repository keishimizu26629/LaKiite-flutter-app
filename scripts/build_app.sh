#!/bin/bash

# 引数からビルド環境を取得
ENV=${1:-"production"}  # デフォルトは本番環境

# スクリプトのパス
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# プロジェクトのルートディレクトリ
PROJECT_ROOT="$SCRIPT_DIR/.."

cd "$PROJECT_ROOT" || exit 1

echo "Building for environment: $ENV"

# 開発環境の場合
if [ "$ENV" == "development" ]; then
  # 開発環境用アイコンを生成
  fvm flutter pub run scripts/create_dev_icon.dart

  # 開発環境用アイコンを適用
  fvm flutter pub run flutter_launcher_icons:main -f flutter_launcher_icons-development.yaml

  # 開発環境用ビルド
  fvm flutter build apk --debug
  fvm flutter build ios --debug

# 本番環境の場合
else
  # 本番環境用アイコンを適用
  fvm flutter pub run flutter_launcher_icons:main -f flutter_launcher_icons-production.yaml

  # 本番環境用ビルド
  fvm flutter build apk --release
  fvm flutter build ios --release
fi

echo "Build completed for $ENV environment."
