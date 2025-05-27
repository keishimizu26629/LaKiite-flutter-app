# 🧪 Firebase Console での通知テスト手順

## 🔧 修正内容

**問題**: FCM トークンが Firestore に正しく保存されていなかった
**解決**:

1. `UserFcmTokenService`で`update`ではなく`set(merge: true)`を使用
2. サインイン・サインアップ時の FCM トークン更新処理を強化
3. 詳細なログを追加して問題を特定しやすくした

## 1. Firebase Console にアクセス

- https://console.firebase.google.com/
- プロジェクト `tarakite-flutter-app-dev` を選択

## 2. Messaging セクションに移動

- 左メニューの「Messaging」をクリック
- 「新しいキャンペーンを作成」→「Firebase Cloud Messaging」

## 3. 通知内容を入力

```
タイトル: テスト通知
本文: プッシュ通知のテストです
```

## 4. テストメッセージを送信

- 「テストメッセージを送信」をクリック
- FCM トークンを入力（ログから取得）:
  ```
  dlfVD9cywEOfkH9gM68OsZ:APA91bF1O_WcH2QKBecKSlkD8_8ru-AEeFxNcv3fSJ62JIn_G4M1yVr3P_SQXAUTuT1lignGqkKhw-0ZOlDl74UPGXof3YBfQiQTm_PdnfkRoMIJyebsKkg
  ```
- 「テスト」をクリック

## 5. 確認事項

- アプリをバックグラウンドにして通知が表示されるか
- 通知をタップしてアプリが開くか
- Xcode コンソールに受信ログが出力されるか

## 6. 修正後の確認手順

### Step 1: アプリを再ビルド・再インストール

```bash
cd /Users/keisukeshimizu/Development/FlutterApps/LaKiite/lakiite-flutter-app
fvm flutter clean
fvm flutter pub get
cd ios && pod install && cd ..
fvm flutter run --debug
```

### Step 2: ログイン・ログアウトを実行

1. アプリでログアウト
2. 再度ログイン
3. Xcode コンソールで以下のログを確認:
   ```
   サインイン成功: ユーザーID=BDi9vUAMQBQqYpEGBuZXnFBm5ot2
   サインイン: FCMトークン更新を開始
   FCMトークン更新: ユーザーID=BDi9vUAMQBQqYpEGBuZXnFBm5ot2, トークン=dlfVD9cywEOfkH9gM68OsZ:...
   FCMトークン更新: 完了
   サインイン: FCMトークン更新完了
   ```

### Step 3: Firestore でトークン保存を確認

1. Firebase Console → Firestore Database
2. `users/{userId}` ドキュメントを確認
3. `fcmToken` フィールドが存在し、最新のトークンが保存されているか確認

### Step 4: 実際のリアクション通知をテスト

1. 別のユーザーアカウントでスケジュールにリアクション
2. Firebase Functions のログを確認:
   ```bash
   cd ../lakiite-firebase-commons
   firebase functions:log
   ```
3. `registration-token-not-registered` エラーが解消されているか確認

## 7. トラブルシューティング

通知が届かない場合：

1. **FCM トークンの保存確認**: Firestore の`users/{userId}`に`fcmToken`フィールドがあるか
2. **ログの確認**: 「FCM トークン更新: 完了」ログが出力されているか
3. **APNs 証明書/キーが Production 環境用か確認**
4. **Bundle ID が一致しているか確認**
5. **プロビジョニングプロファイルを再生成**
6. **TestFlight で新しいビルドをアップロード**

## 8. 期待される結果

- ✅ Firebase Functions ログで`registration-token-not-registered`エラーが解消
- ✅ リアクション・コメント通知が正常に送信される
- ✅ iOS 実機でプッシュ通知バナーが表示される
