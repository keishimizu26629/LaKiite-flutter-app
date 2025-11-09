# AdMob設定ガイド

## 概要

LaKiiteアプリでは、開発環境と本番環境で異なるAdMob IDを使用するよう設定されています。

**重要**: AdMob IDはコードに直接記載されていません。すべてのIDは`dart_define`ファイルから環境変数として読み込まれ、`AdMobConfig`クラスで一元管理されています。これにより、セキュリティと保守性が向上しています。

## 環境別AdMob設定

### 開発環境 (Development)
- **iOS App ID**: `ca-app-pub-3940256099942544~1458002511` (テスト用)
- **iOS Banner ID**: `ca-app-pub-3940256099942544/2934735716` (テスト用)
- **Android App ID**: `ca-app-pub-3940256099942544~3347511713` (テスト用)
- **Android Banner ID**: `ca-app-pub-3940256099942544/6300978111` (テスト用)

### 本番環境 (Production)
- **iOS App ID**: `ca-app-pub-6315199114988889~8448676824`
- **iOS Banner ID**: `ca-app-pub-6315199114988889/6149762649`
- **Android App ID**: `ca-app-pub-6315199114988889~9761758494`
- **Android Banner ID**: `ca-app-pub-6315199114988889/4836680971`

## 設定ファイル

### dart_define設定

#### 開発環境 (`dart_define/dev_dart_define.json`)
```json
{
  "ADMOB_IOS_APP_ID": "ca-app-pub-3940256099942544~1458002511",
  "ADMOB_ANDROID_APP_ID": "ca-app-pub-3940256099942544~3347511713",
  "ADMOB_IOS_BANNER_ID": "ca-app-pub-3940256099942544/2934735716",
  "ADMOB_ANDROID_BANNER_ID": "ca-app-pub-3940256099942544/6300978111"
}
```

#### 本番環境 (`dart_define/prod_dart_define.json`)
```json
{
  "ADMOB_IOS_APP_ID": "ca-app-pub-6315199114988889~8448676824",
  "ADMOB_ANDROID_APP_ID": "ca-app-pub-6315199114988889~9761758494",
  "ADMOB_IOS_BANNER_ID": "ca-app-pub-6315199114988889/6149762649",
  "ADMOB_ANDROID_BANNER_ID": "ca-app-pub-6315199114988889/4836680971"
}
```

## ビルドコマンド

### 開発環境でのビルド（テスト用AdMob ID）
```bash
# 実行
fvm flutter run --dart-define-from-file=dart_define/dev_dart_define.json

# ビルド
fvm flutter build ios --dart-define-from-file=dart_define/dev_dart_define.json
fvm flutter build apk --dart-define-from-file=dart_define/dev_dart_define.json
```

### 本番環境でのビルド（本番用AdMob ID）
```bash
# 1. 本番用AdMob IDに切り替え
./scripts/switch_to_production_admob.sh

# 2. ビルド
fvm flutter build ios --dart-define-from-file=dart_define/prod_dart_define.json
fvm flutter build apk --dart-define-from-file=dart_define/prod_dart_define.json

# 3. テスト用IDに戻す（重要！）
./scripts/switch_to_test_admob.sh
```

## アーキテクチャ

### AdMobConfigクラス

AdMob設定は`lib/config/admob_config.dart`の`AdMobConfig`クラスで一元管理されています。

**主な機能:**
- 環境変数からの設定値読み込み
- 設定値の検証（必須チェック、形式チェック）
- テスト環境での自動フォールバック
- シングルトンパターンによる安全なアクセス

**設定値の検証:**
- すべてのAdMob IDが設定されているか確認
- AdMob IDの形式（`ca-app-pub-`で始まる）を検証
- 設定値が不正な場合は起動時にエラーをスロー

### AdMobService使用方法

```dart
import 'package:your_app/infrastructure/admob_service.dart';

// AdMobの初期化（main.dartで自動的に実行されます）
await AdMobService.initialize();

// バナー広告の作成
final bannerAd = AdMobService.createBannerAd();
```

**注意**: `AdMobConfig.initialize()`は`main.dart`の`startApp()`関数内で自動的に呼び出されます。手動で呼び出す必要はありません。

## 設定確認方法

アプリ起動時のログで使用中のAdMob IDを確認できます：

```
🎯 AdMob初期化開始...
📱 使用中のApp ID: ca-app-pub-6315199114988889~8448676824
🎪 使用中のBanner ID: ca-app-pub-6315199114988889/6149762649
✅ AdMob初期化完了
```

## AdMob審査について

### 現在の状態
- **iOS**: 要審査（App Store へのリンク未追加）
- **Android**: 要審査（Google Play へのリンク未追加）

### 審査完了のために必要な作業
1. **App Store Connect**でアプリを公開
2. **Google Play Console**でアプリを公開
3. **AdMob Console**で各アプリにストアリンクを追加
4. AdMobの審査完了を待つ

### 審査中の注意事項
- テスト用IDでの開発は問題なし
- 本番用IDは審査完了後に収益が発生
- 審査中でも広告は表示される（収益は保留）

## トラブルシューティング

### 広告が表示されない場合
1. **AdMob ID確認**: ログで正しいIDが使用されているか確認
2. **ネットワーク確認**: インターネット接続を確認
3. **審査状況確認**: AdMob Consoleで審査状況を確認

### ビルドエラーの場合
1. **dart_define.json確認**: ファイルの形式が正しいか確認
2. **環境変数確認**: ビルドコマンドが正しいか確認
3. **キャッシュクリア**: `flutter clean` を実行

### 設定値エラーの場合

アプリ起動時に以下のようなエラーが表示される場合：

```
❌ AdMob設定エラー:
ADMOB_ANDROID_APP_IDが設定されていません
ADMOB_IOS_APP_IDが設定されていません
```

**対処方法:**
1. `dart_define/dev_dart_define.json`または`dart_define/prod_dart_define.json`に必要な環境変数が含まれているか確認
2. ビルドコマンドに`--dart-define-from-file`オプションが正しく指定されているか確認
3. JSONファイルの形式が正しいか確認（カンマ、引用符など）

## 改善点

### 以前の実装との違い

**以前:**
- AdMob IDがコードに直接記載されていた（`admob_service.dart`）
- デフォルト値としてテスト用IDがハードコードされていた
- 設定値の検証がなかった

**現在:**
- AdMob IDはすべて環境変数から読み込まれる
- コードにIDが直接記載されていない
- 起動時に設定値の検証が実行される
- `AdMobConfig`クラスで一元管理
- テスト環境では自動的にダミー値を使用

**メリット:**
- ✅ セキュリティ向上（コードに機密情報が含まれない）
- ✅ 保守性向上（設定変更が容易）
- ✅ エラー検出の早期化（起動時に設定値の検証）
- ✅ テスト環境での動作保証

## 参考リンク

- [AdMob Console](https://admob.google.com)
- [Google AdMob ヘルプ](https://support.google.com/admob)
- [Flutter AdMob プラグイン](https://pub.dev/packages/google_mobile_ads)
