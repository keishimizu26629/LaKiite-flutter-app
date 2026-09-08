# LaKiite Web Assets

Firebase Hostingで公開する静的HTML・CSS・画像のソースです。Flutter Webのビルド成果物ではありません。GitHub Pagesの設定は使用しません。

## LP導線の検証・計測・公開境界（2026-09-08 / #310）

対象読者: LPを変更する開発者と公開判断を行うプロダクトオーナー。

- 冒頭と末尾に両ストアの静的リンクを配置。端末判定による自動転送は行わず、iPhone / Android / PCで選択できる。同じタブで通常遷移し、JavaScriptが無効でも使える。
- 承認済みのLP用Airbridge tracking linkは未提供のため、raw store URLを採用。新しい計測SDK、cookie、クエリ転送、外部設定変更は追加していない。
- `data-growth-*` は将来の計測配線用の固定された制作メタデータで、**この属性だけでクリックやインストールを計測できるわけではない**。
- channel: `owned_web` / campaign案: `jp_install_casual_friends_202609` / content: `hero_oinamiman_a`, `footer_oinamiman_a` / platform: `ios`, `android`。実施日が変わる場合は承認時にcampaignを見直す。
- 本番URLをcanonical・OG・sitemapで統一し、共有画像は既存の1024px正方形ロゴを再利用。Twitter Cardは`summary`。評価数・ランキング・効果を構造化データに捏造しない。検索サービスでのリッチリザルト表示を保証するものではない。
- プライバシー、利用規約、サポート、子どもの安全基準、アカウント削除への導線を維持。文書本文・招待用`.well-known`の内容・アプリのFirebase接続設定は変更しない。Hosting配信設定だけを環境別に生成する。

リポジトリ直下で実行する（Node.js 20以降、外部依存なし）:

```bash
node --test scripts/test_web_landing.mjs scripts/test_store_marketing.mjs scripts/test_hosting_seo.mjs
python3 -m http.server 8765 --bind 127.0.0.1 --directory web
```

自動テストは静的HTMLの契約とローカル資産の存在を検査する。ブラウザでの描画や実際の配信状態を代替しない。ローカル表示では、320 / 390 / 1440px、キーボードのフォーカスとストアリンク、200%文字拡大、JS無効、reduced motionを別途確認する。

PR #321のレビュー対応で、ナビの通常／ホバー時の文字コントラスト、暗いフッター上のフォーカス枠、スマホ内外でのリンクの折り返しを静的回帰テストに追加（全17件）。CSSの検査はこのstylesheetの単純な宣言を対象とし、ブラウザのcascadeを再現するものではない。実ブラウザではマウスhover、Tab移動、320 / 390 / 769 / 1440pxでの通常文字・200%文字を確認し、横スクロールの有無だけでなく各リンクの文字が細い列に潰れていないかを見る。

公開経路の正は`.github/workflows/deploy_firebase_hosting.yml`。`dev`への対象ファイルのpushはdev Hostingへ、`main`はprodへ反映される。手動実行は対象refと`target`を必ず確認し、prodはmainだけに限定する。**productionの実行・mainへの統合は別途明示承認が必要**。featureブランチへのpushはHostingを公開しない。

本番公開前のチェックポイント:

- [ ] レビュー済みコミットと同じ成果物をFirebase Hosting devで確認する。
- [ ] 画像・法務導線・store URL・モバイル/PCの見え方を確認する。
- [ ] 既存公開LPとの差分（既にdevへ統合されたデザインを含む）をオーナーが確認する。
- [ ] 本番反映を明示承認してから公開し、公開物のリンクとOG画像を再確認する。
- [ ] 計測を追加する場合は別途privacyとtracking linkを確認する。未計測値を0や効果検証済みと扱わない。

実装計画: `docs/marketing/issue-310-lp-plan.md`。Issue #310は本番公開等の未完了項目が残る間は閉じない。

## 読み仮名と用途の統一（#315）

LPのtitle・OG・Twitterを `LaKiite（ラキーテ）｜友だちと予定を共有するカレンダー` に統一。最初の画面に読み仮名を追加し、h1で用途を説明してから「お誘い未満」の価値を伝える。構造化データは正式名を維持し、`alternateName: ラキーテ` を追加した。ストアURL、法務導線、計測境界は変更しない。

ストアの名前・説明2案と7枚の画像構成案は [日本語ストア素材](../docs/marketing/store/ja-JP/README.md) にある。構成案はHosting対象外で、両OSの再撮影・掲載承認が必要。LPの修正がストア側へ自動反映されるわけではない。

```bash
node --test scripts/test_web_landing.mjs scripts/test_store_marketing.mjs
```

上記は合計23件（LP18件、ストア案5件）。ブラウザ描画、公開済みアプリの動作、ダウンロード増加の証明とは区別する。

## 📄 ファイル一覧

- `index.html` - メインランディングページ
- `privacy-policy.html` - プライバシーポリシー
- `terms-of-service.html` - 利用規約
- `how-to-use.html` - アプリの使い方
- `support.html` - サポートページ
- `account-deletion.html` - アカウント削除ページ（一般向け）
- `account-deletion-webview.html` - アカウント削除ページ（WebView用）

## Firebase HostingとSEO環境分離（2026-09-08 / #310）

| 環境 | 独自ドメイン | 配信用成果物 |
| --- | --- | --- |
| prod | `https://lakiite.inoworl.com/` | index可能。robots/sitemapは正式URLを使用 |
| dev | `https://lakiite-dev.inoworl.com/` | HTTP `X-Robots-Tag: noindex, nofollow`。sitemapは含めない |

両方の独自ドメインは既存Hostingに接続済み（2026-09-08の公開DNS/HTTP観測）。**修正PRだけでは公開中のレスポンスは変わらない**。配信後に独自ドメインと`web.app`の両方を確認する。

`web/`のHTML・OG・JSON-LD・robots・sitemapはprodの正式URLで統一する。sitemap掲載7ページはそれぞれ固有のcanonicalを持つ。既存の`lakiite-flutter-app-dev.web.app` / `lakiite-flutter-app-prod.web.app`は維持し、全URLの一括リダイレクトは追加しない。canonicalは検索側への指定であり、重複URLのアクセスを禁止するものではない。

### 成果物の生成（公開しない）

リポジトリ直下で環境を明示する（Node.js 20以降、外部依存なし）。

```bash
node scripts/prepare_hosting.mjs --target dev
node scripts/prepare_hosting.mjs --target prod
```

各コマンドは`build/hosting-<環境>-<ランダム値>/`に配信用の`web/`と専用`firebase.json`を生成し、configの絶対パスだけを標準出力する。繰り返しても過去の成果物や元の`web/`を上書きしない。README・隠しファイル・node_modulesを除外し、symlinkは拒否する。既存の`.well-known`は内容を維持し、新規の関連付けファイルは生成しない。

devはHTTPヘッダーでnoindexを返す。robots.txtではクロールを許可し、検索エンジンがnoindexを読めるようにする。**noindexはアクセス制御ではない**。開発用サイトへ秘密情報を置いてよいという意味ではなく、検索結果からの即時削除も保証しない。

### 検証と公開経路

```bash
node --test scripts/test_web_landing.mjs scripts/test_store_marketing.mjs scripts/test_hosting_seo.mjs
hosting_config=$(node scripts/prepare_hosting.mjs --target dev)
firebase emulators:start --only hosting --project demo-lakiite-hosting --config "$hosting_config"
```

Emulatorはローカル検証のみ。Hostingの既定ポート5000が使用中なら、生成したconfigだけに`emulators.hosting.host=127.0.0.1`と空き`port`を追加する。prodの確認も`--target prod`で別の成果物を生成する。起動後は、root/各HTMLの200、devだけのnoindex、robots、dev sitemapの404/prod sitemapの200、架空URLの404、画像・既存導線を確認する。

公開workflowは静的テスト→対象環境の成果物生成→**生成configを`--config`で指定したHosting deploy**の順に実行する。ルートの`firebase.json`は生成時の基礎設定であり、これだけを使う手動deployはdev用noindexを反映しないため使用しない。認証情報・project値は既存のGitHub環境設定を使用し、READMEや成果物に埋め込まない。

本番公開後はオーナーがSearch Consoleで正式ドメインの所有確認、`https://lakiite.inoworl.com/sitemap.xml`の送信、URL検査でGoogle選択canonicalとindex状態を確認する。これは別途承認・確認が必要な作業であり、今回のローカルテストから検索順位やDL増加を判定しない。

計画・検証証跡: [SEO公開準備](../docs/marketing/issue-310-seo-release-plan.md)、[SEO検証結果](../docs/marketing/issue-310-seo-verification.md)。過去のGitHub Pages設定変更案は現行手順と矛盾するため、このREADMEから削除した。

## 📱 アプリストア申請での使用

今後の申請では公開確認後の独自ドメインURLを推奨する。既存のStore Console設定やアプリ内URLはこのPRでは変更していない。LPを公開してもストアの表示内容は自動更新されない。

### Google Play Console での使用
- **データセーフティー** → **アカウント削除**の推奨URL: `https://lakiite.inoworl.com/account-deletion.html`（Consoleへの変更・公開は別途承認）

### アプリ内WebView での使用
- **使い方**: `https://lakiite-flutter-app-dev.web.app/how-to-use.html` / `https://lakiite-flutter-app-prod.web.app/how-to-use.html`
- **WebView削除機能**: `https://lakiite-flutter-app-prod.web.app/account-deletion-webview.html`
- JavaScript連携でアプリ内削除処理と連動

## ⚠️ 注意事項

1. **法的確認**: 実際の公開前に法的専門家による確認を受けることをお勧めします
2. **内容の更新**: 実際のサービス内容に合わせて文書を更新してください
3. **連絡先情報**: サポート用メールアドレスを実際のものに変更してください
