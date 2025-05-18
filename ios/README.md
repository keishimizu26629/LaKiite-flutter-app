# iOS 環境設定手順

Flutter のフレーバー（dev/prod）に基づいてアプリアイコンを正しく切り替えるには、以下の手順を実行してください。

## Xcode プロジェクト設定

1. Xcode でプロジェクトを開きます:

   ```bash
   cd ios
   open Runner.xcworkspace
   ```

2. プロジェクトナビゲーターから「Runner」プロジェクトを選択します。

3. 「Build Settings」タブを選択し、「ASSETCATALOG_COMPILER_APPICON_NAME」を検索します。

4. 各 Configuration（Debug/Release/Profile）に対して以下の設定を行います:

   - Debug: `AppIcon-development`
   - Release: `AppIcon-production`
   - Profile: 必要に応じて `AppIcon-development` または `AppIcon-production`

5. 変更を保存します。

## Scheme の設定

各フレーバー(dev/prod)用に Scheme が正しく設定されていることを確認してください:

1. Xcode のツールバーで「Product」>「Scheme」>「Manage Schemes」を選択します。

2. 開発環境用の Scheme が「dev」に、本番環境用の Scheme が「prod」に対応していることを確認します。

3. 各 Scheme に対して、適切な Build Configuration が設定されていることを確認します。
   - 開発環境: Debug Configuration
   - 本番環境: Release Configuration

## 手動でアイコンをビルド

VSCode の launch.json の preLaunchTask が正しく動作しない場合は、手動でアイコンを生成できます:

```bash
fvm flutter pub run scripts/create_dev_icon.dart
fvm flutter pub run flutter_launcher_icons:main -f flutter_launcher_icons-development.yaml
```

## トラブルシューティング

開発環境でアイコンが正しく表示されない場合:

1. iOS ビルドをクリーンします:

   ```bash
   cd ios
   rm -rf build
   pod install
   ```

2. アプリを再インストールします:
   ```bash
   fvm flutter clean
   fvm flutter pub get
   fvm flutter run --flavor dev
   ```
