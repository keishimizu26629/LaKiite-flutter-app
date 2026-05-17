#!/bin/bash

set -euo pipefail

echo "AdMob設定を確認しています..."

log_success() {
    echo "OK: $1"
}

log_error() {
    echo "NG: $1"
}

json_value() {
    local file="$1"
    local key="$2"
    sed -n "s/.*\"$key\":\"\\([^\"]*\\)\".*/\\1/p" "$file"
}

require_contains() {
    local file="$1"
    local pattern="$2"
    local message="$3"

    if grep -Fq "$pattern" "$file"; then
        log_success "$message"
    else
        log_error "$message"
        echo "  file: $file"
        echo "  missing: $pattern"
        exit 1
    fi
}

DEV_IOS_APP_ID=$(json_value "dart_define/dev_dart_define.json" "ADMOB_IOS_APP_ID")
PROD_IOS_APP_ID=$(json_value "dart_define/prod_dart_define.json" "ADMOB_IOS_APP_ID")
DEV_ANDROID_APP_ID=$(json_value "dart_define/dev_dart_define.json" "ADMOB_ANDROID_APP_ID")
PROD_ANDROID_APP_ID=$(json_value "dart_define/prod_dart_define.json" "ADMOB_ANDROID_APP_ID")

require_contains \
    "lib/config/admob_config.dart" \
    "String.fromEnvironment('ADMOB_IOS_APP_ID')" \
    "Dart側のiOS AdMob App IDはdart-defineから読み込まれる"

require_contains \
    "lib/config/admob_config.dart" \
    "String.fromEnvironment('ADMOB_ANDROID_APP_ID')" \
    "Dart側のAndroid AdMob App IDはdart-defineから読み込まれる"

require_contains \
    "ios/Runner/Info.plist" \
    '<string>$(GAD_APPLICATION_IDENTIFIER)</string>' \
    "iOS Info.plistはBuild SettingsのAdMob App IDを参照する"

require_contains \
    "ios/Runner.xcodeproj/project.pbxproj" \
    "GAD_APPLICATION_IDENTIFIER = \"$DEV_IOS_APP_ID\";" \
    "iOS dev Build SettingsにAdMob App IDが設定されている"

require_contains \
    "ios/Runner.xcodeproj/project.pbxproj" \
    "GAD_APPLICATION_IDENTIFIER = \"$PROD_IOS_APP_ID\";" \
    "iOS prod Build SettingsにAdMob App IDが設定されている"

require_contains \
    "android/app/src/main/AndroidManifest.xml" \
    'android:value="${adMobApplicationId}"' \
    "AndroidManifestはflavor placeholderのAdMob App IDを参照する"

require_contains \
    "android/app/build.gradle" \
    "adMobApplicationId: \"$DEV_ANDROID_APP_ID\"" \
    "Android dev flavorにAdMob App IDが設定されている"

require_contains \
    "android/app/build.gradle" \
    "adMobApplicationId: \"$PROD_ANDROID_APP_ID\"" \
    "Android prod flavorにAdMob App IDが設定されている"

echo "AdMob設定確認完了"
