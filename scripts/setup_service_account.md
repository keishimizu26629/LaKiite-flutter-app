# サービスアカウントキー設定ガイド

cURL でプッシュ通知を送信するには、サービスアカウントキーが必要です。

## 🔑 サービスアカウントキーの作成手順

### 1. Firebase Console でサービスアカウントを作成

1. [Firebase Console](https://console.firebase.google.com) → lakiite-flutter-app-dev プロジェクト
2. 左上の歯車アイコン → **「プロジェクトの設定」**
3. **「サービス アカウント」** タブをクリック
4. **「新しい秘密鍵の生成」** をクリック
5. JSON ファイルをダウンロード → `service-account-key.json` として保存

### 2. 環境変数の設定

```bash
# サービスアカウントキーのパスを設定
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account-key.json"

# または、プロジェクトルートに配置した場合
export GOOGLE_APPLICATION_CREDENTIALS="./service-account-key.json"
```

### 3. 更新された cURL コマンド

```bash
# アクセストークンを取得
ACCESS_TOKEN=$(gcloud auth application-default print-access-token)

# プッシュ通知送信
curl -X POST \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json; charset=utf-8" \
  https://fcm.googleapis.com/v1/projects/lakiite-flutter-app-dev/messages:send \
  -d '{
    "message": {
      "token": "fF_Zd9PCkk54lgYQuf3RmA:APA91bGoTUfhTCGXyNqFz9kvU72DLBxinu0GXuFeJSEP6U4jQLDtwd75Xdn4tjPqNNkH0YilN8pEwID67gGVjlW2I_f8AbfBthpfU0zAk2K86qSErn7wloI",
      "notification": {
        "title": "🔑 サービスアカウントテスト",
        "body": "サービスアカウントキーを使用したテスト通知です"
      }
    }
  }'
```

## ⚠️ セキュリティ注意事項

- サービスアカウントキーは機密情報です
- `.gitignore` に追加して Git にコミットしないでください
- 本番環境では適切な権限管理を行ってください

```bash
# .gitignore に追加
echo "service-account-key.json" >> .gitignore
```
