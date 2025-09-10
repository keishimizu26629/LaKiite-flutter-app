# ユーザー作業必須リスト

## 🔴 最優先作業（今すぐ必要）

### 1. iOS Firebase Bundle ID修正（30分）
**Firebase Consoleでの作業**:
1. https://console.firebase.google.com にアクセス
2. `lakiite-flutter-app-prod`プロジェクトを選択
3. プロジェクト設定 → 全般 → iOSアプリ
4. Bundle IDを`com.example.tarakite`から`com.inoworl.lakiite`に変更
5. 新しい`GoogleService-Info.plist`をダウンロード
6. ダウンロードしたファイルを`ios/Runner/Firebase/Prod/GoogleService-Info.plist`に置き換え

### 2. Android Release Keystore作成（15分）
**ターミナルでの作業**:
```bash
# Keystoreファイル生成
keytool -genkey -v -keystore ~/lakiite-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias lakiite

# 以下の情報を入力:
# - キーストアのパスワード（2回）
# - 名前、組織単位、組織、都市、州、国コード（JP）
# - キーのパスワード（キーストアと同じでOK）
```

**key.propertiesファイル作成**:
1. `android/key.properties.template`を`android/key.properties`にコピー
2. 実際の値に置き換え:
   - storeFile=/Users/[あなたのユーザー名]/lakiite-release-key.jks
   - storePassword=[設定したパスワード]
   - keyPassword=[設定したパスワード]
   - keyAlias=lakiite

**重要**: 
- パスワードを安全に保管
- keystoreファイルのバックアップを取る
- key.propertiesはGitにコミットしない

### 3. AdMob本番アカウント設定（1時間）
**AdMob Consoleでの作業**:
1. https://apps.admob.com にアクセス（Googleアカウントでログイン）
2. アカウントがない場合は作成
3. 「アプリを追加」をクリック
4. 以下を2回実行（iOS用とAndroid用）:
   - プラットフォーム選択
   - アプリ名: LaKiite
   - アプリストアに公開済み？: いいえ
5. 各プラットフォームで「広告ユニットを追加」:
   - 広告フォーマット: バナー
   - 広告ユニット名: LaKiite Banner
6. 取得したIDをメモ:
   - Android App ID: ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX
   - Android Banner Unit ID: ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX
   - iOS App ID: ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX
   - iOS Banner Unit ID: ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX

**コード更新作業**（私が対応可能）:
取得したIDを教えていただければ、以下のファイルを更新します:
- `android/app/src/main/AndroidManifest.xml`
- `ios/Runner/Info.plist`
- `lib/infrastructure/admob_service.dart`

### 4. 法的文書の確認・公開（2-3時間）
**必要な作業**:
1. `PRIVACY_POLICY_TEMPLATE.md`を確認・編集:
   - [日付を入力] → 実際の日付
   - [メールアドレスを入力] → サポート用メールアドレス
   - [連絡先を入力] → 連絡先情報
2. `TERMS_OF_SERVICE_TEMPLATE.md`を確認・編集:
   - [日付を入力] → 実際の日付
   - [管轄裁判所を入力] → 東京地方裁判所など
   - [メールアドレスを入力] → サポート用メールアドレス
   - [連絡先を入力] → 連絡先情報
3. **Webサイトで公開**（GitHub Pages推奨）:
   - プライバシーポリシーURL
   - 利用規約URL

---

## 🟡 ストア登録作業（1週間以内）

### 5. Apple Developer Program登録（未登録の場合）
- https://developer.apple.com/programs/
- 年間$99（約15,000円）
- 法人の場合はD-U-N-S番号が必要

### 6. Google Play Developer登録（未登録の場合）
- https://play.google.com/console/
- 初回登録料$25（約3,750円）

### 7. iOS証明書・プロファイル作成
**Apple Developer Consoleでの作業**:
1. Certificates → Production → App Store and Ad Hoc
2. Profiles → Distribution → App Store
3. 作成した証明書・プロファイルをXcodeに設定

### 8. ストアコンソールでアプリ登録
- App Store Connect: アプリ情報、価格、配信地域設定
- Google Play Console: アプリ情報、コンテンツレーティング設定

---

## 📋 作業チェックリスト

### 今すぐ必要:
- [ ] Firebase Bundle ID修正（iOS本番環境）
- [ ] Android Keystore作成とkey.properties設定
- [ ] AdMob本番アカウント作成とID取得
- [ ] プライバシーポリシー・利用規約の編集と公開

### 取得後に私に共有してください:
- [ ] AdMob Android App ID
- [ ] AdMob Android Banner Unit ID
- [ ] AdMob iOS App ID
- [ ] AdMob iOS Banner Unit ID
- [ ] プライバシーポリシーURL
- [ ] 利用規約URL

### ストア申請前:
- [ ] Apple Developer Program登録
- [ ] Google Play Developer登録
- [ ] iOS証明書・プロファイル作成
- [ ] スクリーンショット準備
- [ ] アプリ説明文作成

---

## 🆘 サポート

作業中に不明な点があれば、具体的なエラーメッセージや画面のスクリーンショットと共にお知らせください。