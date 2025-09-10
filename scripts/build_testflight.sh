#!/bin/bash

# LaKiite TestFlight ビルドスクリプト
# 使用方法: ./scripts/build_testflight.sh [dev|prod]

set -e

# 環境の設定（デフォルトは開発環境）
ENVIRONMENT=${1:-"dev"}

echo "🚀 LaKiite TestFlight ビルド（${ENVIRONMENT}環境）を開始します..."

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

# 前提条件のチェック
check_prerequisites() {
    log_info "前提条件をチェックしています..."

    # Flutterがインストールされているかチェック
    if ! command -v flutter &> /dev/null; then
        log_error "Flutter がインストールされていません"
        exit 1
    fi

    # Xcodeがインストールされているかチェック (macOS)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if ! command -v xcodebuild &> /dev/null; then
            log_error "Xcode がインストールされていません"
            exit 1
        fi
    fi

    log_success "前提条件チェック完了"
}

# Firebase設定の確認
check_firebase_config() {
    log_info "Firebase設定（${ENVIRONMENT}環境）を確認しています..."

    # 環境に応じたFirebase設定ファイルのパスを決定
    if [ "$ENVIRONMENT" == "prod" ]; then
        FIREBASE_CONFIG_PATH="ios/Runner/Firebase/Prod/GoogleService-Info.plist"
        EXPECTED_BUNDLE_ID="com.inoworl.lakiite"
    else
        FIREBASE_CONFIG_PATH="ios/Runner/Firebase/Dev/GoogleService-Info.plist"
        EXPECTED_BUNDLE_ID="com.inoworl.lakiite"
    fi

    # iOS Firebase設定の確認
    if [ ! -f "$FIREBASE_CONFIG_PATH" ]; then
        log_error "iOS ${ENVIRONMENT}環境用GoogleService-Info.plistが見つかりません"
        log_error "パス: $FIREBASE_CONFIG_PATH"
        log_warning "Firebase Consoleで設定を確認し、ファイルをダウンロードしてください"
        exit 1
    fi

    # Bundle IDの確認
    local bundle_id=$(grep -A 1 "BUNDLE_ID" "$FIREBASE_CONFIG_PATH" | grep "<string>" | sed 's/<[^>]*>//g' | xargs)
    if [ "$bundle_id" != "$EXPECTED_BUNDLE_ID" ]; then
        log_error "iOS ${ENVIRONMENT}環境用Firebase設定のBundle IDが正しくありません"
        log_error "現在の値: $bundle_id"
        log_error "正しい値: $EXPECTED_BUNDLE_ID"
        log_warning "Firebase Consoleで Bundle ID を修正してください"
        exit 1
    fi

    log_success "Firebase設定（${ENVIRONMENT}環境）確認完了"
}

# Android署名設定の確認（本番環境のみ）
check_android_signing() {
    if [ "$ENVIRONMENT" == "prod" ]; then
        log_info "Android署名設定を確認しています..."

        if [ ! -f "android/key.properties" ]; then
            log_error "android/key.properties が見つかりません"
            log_warning "以下の手順で作成してください:"
            log_warning "1. keytool -genkey -v -keystore ~/lakiite-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias lakiite"
            log_warning "2. android/key.properties.template をコピーして android/key.properties を作成"
            log_warning "3. 実際の値を設定"
            exit 1
        fi

        log_success "Android署名設定確認完了"
    else
        log_info "開発環境のため、Android署名設定チェックをスキップします"
    fi
}

# 依存関係の更新
update_dependencies() {
    log_info "依存関係を更新しています..."

    fvm flutter clean
    fvm flutter pub get

    # iOS CocoaPodsの更新
    if [[ "$OSTYPE" == "darwin"* ]]; then
        cd ios
        pod install --repo-update
        cd ..
    fi

    log_success "依存関係更新完了"
}

# コード生成の実行
generate_code() {
    log_info "コード生成を実行しています..."

    fvm flutter packages pub run build_runner build --delete-conflicting-outputs

    log_success "コード生成完了"
}

# アイコンの生成
generate_icons() {
    log_info "${ENVIRONMENT}環境用アイコンを生成しています..."

    if [ "$ENVIRONMENT" == "dev" ]; then
        # 開発環境用アイコンの生成
        fvm dart run scripts/create_dev_icon.dart
        fvm dart run flutter_launcher_icons:main -f flutter_launcher_icons-development.yaml
    else
        # 本番環境用アイコンの生成
        fvm dart run flutter_launcher_icons:main -f flutter_launcher_icons-production.yaml
    fi

    log_success "アイコン生成完了"
}

# Android APK/AABのビルド
build_android() {
    log_info "Android APK/AAB（${ENVIRONMENT}環境）をビルドしています..."

    if [ "$ENVIRONMENT" == "dev" ]; then
        # 開発環境用ビルド
        fvm flutter build apk --release --flavor dev --dart-define-from-file=dart_define/dev_dart_define.json
        fvm flutter build appbundle --release --flavor dev --dart-define-from-file=dart_define/dev_dart_define.json

        log_success "Android ビルド完了"
        log_info "APK: build/app/outputs/flutter-apk/app-dev-release.apk"
        log_info "AAB: build/app/outputs/bundle/devRelease/app-dev-release.aab"
    else
        # 本番環境用ビルド
        fvm flutter build apk --release --flavor prod --dart-define-from-file=dart_define/prod_dart_define.json
        fvm flutter build appbundle --release --flavor prod --dart-define-from-file=dart_define/prod_dart_define.json

        log_success "Android ビルド完了"
        log_info "APK: build/app/outputs/flutter-apk/app-prod-release.apk"
        log_info "AAB: build/app/outputs/bundle/prodRelease/app-prod-release.aab"
    fi
}

# iOS IPAのビルド
build_ios() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        log_warning "iOS ビルドは macOS でのみ実行可能です"
        return
    fi

    log_info "iOS IPA（${ENVIRONMENT}環境）をビルドしています..."

    if [ "$ENVIRONMENT" == "dev" ]; then
        # 開発環境用ビルド
        fvm flutter build ios --release --flavor dev --dart-define-from-file=dart_define/dev_dart_define.json
    else
        # 本番環境用ビルド
        fvm flutter build ios --release --flavor prod --dart-define-from-file=dart_define/prod_dart_define.json
    fi

    log_success "iOS ビルド完了"
    log_info "次のステップ: Xcodeで Archive を作成してTestFlightにアップロードしてください"
    log_info "Xcode Scheme: ${ENVIRONMENT} を選択してください"
}

# メイン実行
main() {
    echo "🎯 LaKiite TestFlight ビルドスクリプト（${ENVIRONMENT}環境）"
    echo "=============================================="

    check_prerequisites
    check_firebase_config
    check_android_signing
    update_dependencies
    generate_code
    generate_icons

    # プラットフォーム別ビルド
    if [[ "$2" == "android" ]]; then
        build_android
    elif [[ "$2" == "ios" ]]; then
        build_ios
    else
        log_info "両方のプラットフォームをビルドします..."
        build_android
        build_ios
    fi

    log_success "🎉 ビルド完了!"
    echo ""
    echo "📋 次のステップ:"
    if [ "$ENVIRONMENT" == "dev" ]; then
        echo "1. 開発環境でのテスト配信準備完了"
        echo "2. iOS: Xcode で 'dev' Scheme を選択してArchive作成"
        echo "3. Android: 開発用APK/AABでテスト実施"
    else
        echo "1. Android: Google Play Console で内部テストを設定"
        echo "2. iOS: Xcode で 'prod' Scheme を選択してArchive作成"
        echo "3. 各プラットフォームでテストを実施"
    fi
    echo "4. TestFlight/内部テストでの動作確認"
}

# 使用方法の表示
show_usage() {
    echo "使用方法: $0 [dev|prod] [android|ios]"
    echo ""
    echo "環境:"
    echo "  dev   - 開発環境（デフォルト）"
    echo "  prod  - 本番環境"
    echo ""
    echo "プラットフォーム:"
    echo "  android - Androidのみビルド"
    echo "  ios     - iOSのみビルド"
    echo "  (未指定) - 両方のプラットフォームをビルド"
    echo ""
    echo "例:"
    echo "  $0 dev          # 開発環境で両方のプラットフォームをビルド"
    echo "  $0 prod ios     # 本番環境でiOSのみビルド"
    echo "  $0 dev android  # 開発環境でAndroidのみビルド"
}

# ヘルプオプションの処理
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_usage
    exit 0
fi

# 不正な環境指定のチェック
if [[ "$1" != "dev" && "$1" != "prod" && "$1" != "" ]]; then
    log_error "無効な環境指定: $1"
    show_usage
    exit 1
fi

# スクリプト実行
main "$@"
