# Firebase 設定修正が必要な項目

## 🚨 緊急対応が必要

### iOS 本番用 Bundle ID 不整合

**現在の問題:**

- ファイル: `ios/Runner/Firebase/Prod/GoogleService-Info.plist`
- 現在の Bundle ID: `com.example.tarakite` ← **間違い**
- 正しい Bundle ID: `com.inoworl.lakiite`

**対応方法:**

1. Firebase Console → lakiite-flutter-app-prod プロジェクト
2. iOS アプリ設定 → Bundle ID を `com.inoworl.lakiite` に修正
3. 新しい `GoogleService-Info.plist` をダウンロード
4. `ios/Runner/Firebase/Prod/GoogleService-Info.plist` を置き換え

**影響:**

- プッシュ通知が正常に動作しない
- Firebase Analytics/Crashlytics が正常に動作しない
- TestFlight でのテストに影響

## ✅ 確認済み項目

### 開発環境設定

- Dev Bundle ID: `com.inoworl.lakiite` ✅ 正常
- プロジェクト設定: 適切に分離されている

### Android 設定

- Application ID: `com.inoworl.lakiite` ✅ 正常
- Firebase 設定: 適切に設定されている

**この修正完了後、AI エージェントが残りの設定を自動化します。**
