# LaKiite Web Assets

このフォルダには、Firebase HostingやGitHub Pagesで公開するWeb用ファイルが含まれています。

## LP導線の検証・計測・公開境界（2026-09-08 / #310）

対象読者: LPを変更する開発者と公開判断を行うプロダクトオーナー。

- 冒頭と末尾に両ストアの静的リンクを配置。端末判定による自動転送は行わず、iPhone / Android / PCで選択できる。同じタブで通常遷移し、JavaScriptが無効でも使える。
- 承認済みのLP用Airbridge tracking linkは未提供のため、raw store URLを採用。新しい計測SDK、cookie、クエリ転送、外部設定変更は追加していない。
- `data-growth-*` は将来の計測配線用の固定された制作メタデータで、**この属性だけでクリックやインストールを計測できるわけではない**。
- channel: `owned_web` / campaign案: `jp_install_casual_friends_202609` / content: `hero_oinamiman_a`, `footer_oinamiman_a` / platform: `ios`, `android`。実施日が変わる場合は承認時にcampaignを見直す。
- 本番URLをcanonical・OG・sitemapで統一し、共有画像は既存の1024px正方形ロゴを再利用。Twitter Cardは`summary`。評価数・ランキング・効果を構造化データに捏造しない。検索サービスでのリッチリザルト表示を保証するものではない。
- プライバシー、利用規約、サポート、子どもの安全基準、アカウント削除への導線を維持。文書本文・招待用`.well-known`設定・Firebase設定は変更しない。

リポジトリ直下で実行する（Node.js 20以降、外部依存なし）:

```bash
node --test scripts/test_web_landing.mjs
python3 -m http.server 8765 --bind 127.0.0.1 --directory web
```

自動テストは静的HTMLの契約とローカル資産の存在を検査する。ブラウザでの描画や実際の配信状態を代替しない。ローカル表示では、320 / 390 / 1440px、キーボードのフォーカスとストアリンク、200%文字拡大、JS無効、reduced motionを別途確認する。

公開経路の正は`.github/workflows/deploy_firebase_hosting.yml`。`dev`への対象ファイルのpushはdev Hostingへ、`main`はprodへ反映される。既存workflowの手動実行では対象refと`target=dev`を確認する。**productionの実行・mainへの統合は別途明示承認が必要**。以下のGitHub Pages設定メモは過去の記録であり、今回の移行・設定変更手順ではない。

本番公開前のチェックポイント:

- [ ] レビュー済みコミットと同じ成果物をFirebase Hosting devで確認する。
- [ ] 画像・法務導線・store URL・モバイル/PCの見え方を確認する。
- [ ] 既存公開LPとの差分（既にdevへ統合されたデザインを含む）をオーナーが確認する。
- [ ] 本番反映を明示承認してから公開し、公開物のリンクとOG画像を再確認する。
- [ ] 計測を追加する場合は別途privacyとtracking linkを確認する。未計測値を0や効果検証済みと扱わない。

実装計画: `docs/marketing/issue-310-lp-plan.md`。Issue #310は本番公開等の未完了項目が残る間は閉じない。

## 📄 ファイル一覧

- `index.html` - メインランディングページ
- `privacy-policy.html` - プライバシーポリシー
- `terms-of-service.html` - 利用規約
- `how-to-use.html` - アプリの使い方
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

- メインページ: `https://lakiite-flutter-app-prod.web.app/`
- プライバシーポリシー: `https://lakiite-flutter-app-prod.web.app/privacy-policy.html`
- 利用規約: `https://lakiite-flutter-app-prod.web.app/terms-of-service.html`
- 使い方: `https://lakiite-flutter-app-prod.web.app/how-to-use.html`
- サポート: `https://lakiite-flutter-app-prod.web.app/support.html`
- アカウント削除: `https://lakiite-flutter-app-prod.web.app/account-deletion.html`

## 🌐 Firebase Hosting

`firebase.json` では `web/` をHostingの公開ディレクトリに設定しています。

想定URL：

- Dev: `https://lakiite-flutter-app-dev.web.app/support.html`
- Prod: `https://lakiite-flutter-app-prod.web.app/support.html`
- 使い方 Dev: `https://lakiite-flutter-app-dev.web.app/how-to-use.html`
- 使い方 Prod: `https://lakiite-flutter-app-prod.web.app/how-to-use.html`

### 🔧 設定変更が必要
GitHub Repository Settings → Pages → Source を以下に変更してください：
- **Source**: GitHub Actions (推奨) または Deploy from a branch
- **Branch**: main
- **Path**: /web (Deploy from a branchの場合)

## 📱 アプリストア申請での使用

App Store Connect や Google Play Console でのアプリ申請時に上記URLを使用してください。

### Google Play Console での使用
- **データセーフティー** → **アカウント削除**: `https://lakiite-flutter-app-prod.web.app/account-deletion.html`

### アプリ内WebView での使用
- **使い方**: `https://lakiite-flutter-app-dev.web.app/how-to-use.html` / `https://lakiite-flutter-app-prod.web.app/how-to-use.html`
- **WebView削除機能**: `https://lakiite-flutter-app-prod.web.app/account-deletion-webview.html`
- JavaScript連携でアプリ内削除処理と連動

## ⚠️ 注意事項

1. **法的確認**: 実際の公開前に法的専門家による確認を受けることをお勧めします
2. **内容の更新**: 実際のサービス内容に合わせて文書を更新してください
3. **連絡先情報**: サポート用メールアドレスを実際のものに変更してください
