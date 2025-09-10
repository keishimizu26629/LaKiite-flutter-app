#!/bin/bash

# LaKiite AdMob設定確認スクリプト
# 使用方法: ./scripts/check_admob_config.sh

echo "🔍 AdMob設定を確認しています..."

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

# テスト用IDの定義
TEST_IOS_APP_ID="ca-app-pub-3940256099942544~1458002511"
TEST_ANDROID_APP_ID="ca-app-pub-3940256099942544~3347511713"
TEST_IOS_BANNER_ID="ca-app-pub-3940256099942544/2934735716"
TEST_ANDROID_BANNER_ID="ca-app-pub-3940256099942544/6300978111"

# AdMobServiceの確認
check_admob_service() {
    log_info "AdMobService設定を確認しています..."

    local service_file="lib/infrastructure/admob_service.dart"

    if [ ! -f "$service_file" ]; then
        log_error "AdMobServiceファイルが見つかりません: $service_file"
        return 1
    fi

    # iOS Banner IDの確認
    local ios_banner_id=$(grep -o "ca-app-pub-[0-9]*/[0-9]*" "$service_file" | grep -v "Android" | head -1)
    if [ "$ios_banner_id" == "$TEST_IOS_BANNER_ID" ]; then
        log_warning "iOS Banner ID がテスト用IDのままです: $ios_banner_id"
        echo "          本番用IDに変更してください"
    else
        log_success "iOS Banner ID: $ios_banner_id"
    fi

    # Android Banner IDの確認
    local android_banner_id=$(grep -o "ca-app-pub-[0-9]*/[0-9]*" "$service_file" | grep -v "iOS" | tail -1)
    if [ "$android_banner_id" == "$TEST_ANDROID_BANNER_ID" ]; then
        log_warning "Android Banner ID がテスト用IDのままです: $android_banner_id"
        echo "          本番用IDに変更してください"
    else
        log_success "Android Banner ID: $android_banner_id"
    fi
}

# iOS Info.plistの確認
check_ios_info_plist() {
    log_info "iOS Info.plist の AdMob設定を確認しています..."

    local info_plist="ios/Runner/Info.plist"

    if [ ! -f "$info_plist" ]; then
        log_error "Info.plistファイルが見つかりません: $info_plist"
        return 1
    fi

    # GADApplicationIdentifierの確認
    local app_id=$(grep -A 1 "GADApplicationIdentifier" "$info_plist" | grep "<string>" | sed 's/<[^>]*>//g' | xargs)

    if [ "$app_id" == "$TEST_IOS_APP_ID" ]; then
        log_warning "iOS App ID がテスト用IDのままです: $app_id"
        echo "          本番用IDに変更してください"
    else
        log_success "iOS App ID: $app_id"
    fi
}

# Android AndroidManifest.xmlの確認
check_android_manifest() {
    log_info "Android AndroidManifest.xml の AdMob設定を確認しています..."

    local manifest="android/app/src/main/AndroidManifest.xml"

    if [ ! -f "$manifest" ]; then
        log_error "AndroidManifest.xmlファイルが見つかりません: $manifest"
        return 1
    fi

    # com.google.android.gms.ads.APPLICATION_IDの確認
    local app_id=$(grep -A 1 "com.google.android.gms.ads.APPLICATION_ID" "$manifest" | grep "android:value" | sed 's/.*android:value="//g' | sed 's/".*//g')

    if [ "$app_id" == "$TEST_ANDROID_APP_ID" ]; then
        log_warning "Android App ID がテスト用IDのままです: $app_id"
        echo "          本番用IDに変更してください"
    else
        log_success "Android App ID: $app_id"
    fi
}

# 本番用ID設定の手順を表示
show_production_setup_guide() {
    echo ""
    echo "📋 本番用AdMob ID設定手順:"
    echo "=================================="
    echo "1. AdMob Console (https://admob.google.com) にログイン"
    echo "2. 新しいアプリを追加:"
    echo "   - iOS: com.inoworl.lakiite"
    echo "   - Android: com.inoworl.lakiite"
    echo "3. 各アプリでバナー広告ユニットを作成"
    echo "4. 取得したIDを以下のファイルに設定:"
    echo "   - lib/infrastructure/admob_service.dart"
    echo "   - ios/Runner/Info.plist"
    echo "   - android/app/src/main/AndroidManifest.xml"
    echo ""
    echo "⚠️  注意: 本番用IDは実際のアプリ公開後に収益が発生します"
    echo "   テスト段階では現在のテスト用IDを使用してください"
}

# メイン実行
main() {
    echo "🎯 LaKiite AdMob設定確認"
    echo "======================="

    check_admob_service
    check_ios_info_plist
    check_android_manifest

    echo ""
    log_info "AdMob設定確認完了"

    # テスト用IDが使用されている場合は手順を表示
    if grep -q "$TEST_IOS_APP_ID\|$TEST_ANDROID_APP_ID\|$TEST_IOS_BANNER_ID\|$TEST_ANDROID_BANNER_ID" lib/infrastructure/admob_service.dart ios/Runner/Info.plist android/app/src/main/AndroidManifest.xml 2>/dev/null; then
        show_production_setup_guide
    else
        log_success "🎉 すべて本番用IDが設定されています"
    fi
}

# スクリプト実行
main "$@"
