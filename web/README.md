# LaKiite Web Assets

このフォルダには、Firebase HostingやGitHub Pagesで公開するWeb用ファイルが含まれています。

## 📄 ファイル一覧

- `index.html` - メインランディングページ
- `privacy-policy.html` - プライバシーポリシー
- `terms-of-service.html` - 利用規約
- `support.html` - サポートページ
- `account-deletion.html` - アカウント削除ページ（一般向け）
- `account-deletion-webview.html` - アカウント削除ページ（WebView用）

## 🌐 GitHub Pages 設定

### 1. GitHub リポジトリ設定

1. GitHub リポジトリの「Settings」タブに移動
2. 左サイドバーの「Pages」をクリック
3. Source で「Deploy from a branch」を選択
4. Branch で「main」を選択
5. Folder で「/web」を選択
6. 「Save」をクリック

### 2. アクセス URL

⚠️ **現在設定中**: GitHub Pagesの設定を`/docs`から`/web`に変更中です。

設定完了後、以下の URL でアクセス可能：

- メインページ: `https://keishimizu26629.github.io/LaKiite-flutter-app/`
- プライバシーポリシー: `https://keishimizu26629.github.io/LaKiite-flutter-app/privacy-policy.html`
- 利用規約: `https://keishimizu26629.github.io/LaKiite-flutter-app/terms-of-service.html`
- サポート: `https://keishimizu26629.github.io/LaKiite-flutter-app/support.html`
- アカウント削除: `https://keishimizu26629.github.io/LaKiite-flutter-app/account-deletion.html`

## 🌐 Firebase Hosting

`firebase.json` では `web/` をHostingの公開ディレクトリに設定しています。

想定URL：

- Dev: `https://lakiite-flutter-app-dev.web.app/support.html`
- Prod: `https://lakiite-flutter-app-prod.web.app/support.html`

### 🔧 設定変更が必要
GitHub Repository Settings → Pages → Source を以下に変更してください：
- **Source**: GitHub Actions (推奨) または Deploy from a branch
- **Branch**: main
- **Path**: /web (Deploy from a branchの場合)

## 📱 アプリストア申請での使用

App Store Connect や Google Play Console でのアプリ申請時に上記URLを使用してください。

### Google Play Console での使用
- **データセーフティー** → **アカウント削除**: `https://keishimizu26629.github.io/LaKiite-flutter-app/account-deletion.html`

### アプリ内WebView での使用
- **WebView削除機能**: `https://keishimizu26629.github.io/LaKiite-flutter-app/account-deletion-webview.html`
- JavaScript連携でアプリ内削除処理と連動

## ⚠️ 注意事項

1. **法的確認**: 実際の公開前に法的専門家による確認を受けることをお勧めします
2. **内容の更新**: 実際のサービス内容に合わせて文書を更新してください
3. **連絡先情報**: サポート用メールアドレスを実際のものに変更してください
