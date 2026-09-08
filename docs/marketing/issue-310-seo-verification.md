# #310 SEO環境分離の検証結果

検証日: 2026-09-08（JST） / Refs #310, #315 / 修正PR #322 / 公開準備Draft #323

## 対象・証拠の範囲

`codex/issue-315-store-clarity`に追加したSEOとHosting配信準備の検証。作業前HEADは`f6a4e12c36c06e4d54e2380e367805b75e5beb4e`。この文書はローカルで実行した結果を記録し、push後の完全なcommit SHA・CI runはPR #322で別に確認する。

公開中のdev/prod、Store Console、Search Console、DNSには変更を加えていない。既存PRの20条件ブラウザ検証は[先行検証](issue-315-verification.md)の結果であり、今回のSEO変更後に再実行したと扱わない。

## 実行結果

| 検証 | 結果 |
| --- | --- |
| `node --test scripts/test_web_landing.mjs scripts/test_store_marketing.mjs scripts/test_hosting_seo.mjs` | 33 passed / 0 failed（LP18、store5、Hosting/SEO10） |
| `node --check scripts/prepare_hosting.mjs` / `scripts/test_hosting_seo.mjs` | 成功 |
| CLI `prepare_hosting.mjs --target dev` / `--target prod` | 両環境の新規成果物を生成し、config絶対パスのみ出力 |
| Firebase Hosting Emulator dev | 87 assertions成功 / 終了コード0 |
| Firebase Hosting Emulator prod | 90 assertions成功 / 終了コード0 |
| 変更したworkflow 2件のYAML構文 | Ruby Psychでparse成功 |
| Hosting workflowのevent/ref/target条件 | YAMLから条件とvalidation shellを読み、9ケース成功 |
| `fvm flutter analyze --no-pub` | No issues found（2.9秒） |
| `git diff --check` | 成功 |
| SEO変更前後の7 HTMLの`body`比較 | 全件一致。法務本文・表示本文は無変更 |
| CSS、画像、WebView専用削除ページ、Dart/iOS/Android、基礎Firebase設定の今回差分 | 差分なし |

ローカル環境: Node.js v25.9.0、Firebase CLI 15.2.1。CIはNode 20を指定し、公開なしの`ci.yml`に`Landing and SEO Contracts`を追加した。上表のローカルNode結果と、CIでのNode 20結果を混同しない。actionlintは未導入であり、YAML parseと条件確認を完全なGitHub Actions lintの代替とはしない。

TDD: 最初の新仕様テストは24件中10件が期待どおり失敗（旧ドメイン、generator未実装、workflow未対応）。実装後29件成功。その後CLI・symlink rootの回帰テストを追加して32件成功。公開なしCI用の新テストが未実装のjobを理由に失敗したことを確認してjobを追加し、最終33件成功。

## Emulatorで確認したこと

実際のソースから生成した専用configに、ローカル用の`emulators.hosting`だけを追加。`127.0.0.1:8876`で`firebase emulators:exec --only hosting --project demo-lakiite-hosting --config <生成config>`を実行し、終了後は両Emulatorを停止した。Firebaseへの実deploy、Firestoreへの接続・書き込みは行っていない。

- 8 HTML（LP、使い方、サポート、法務・安全、削除通常/WebView）は200で、配信本文がソースと一致。
- CSS、favicon、app-ads.txt、images配下15ファイルは200で、配信バイトがソースと一致。
- 上記の全200レスポンスとrobotsについて、devは`X-Robots-Tag: noindex, nofollow`、prodはそのヘッダーなし。
- dev: robotsは`Allow: /`、Sitemap宣言なし、`/sitemap.xml`は404。
- prod: robotsは正式ドメインのsitemapを案内し、sitemapは200、7 URLすべて`https://lakiite.inoworl.com/`配下。
- 架空URL、`/README.md`、`/.env`、`/firebase.json`は両環境で404。
- 生成configを`--config`で渡したときの相対publicディレクトリ解決を実HTTPで確認。ルートの`web/`を誤って配信するとdevのsitemapが200になるため、この検査で区別できる。

初回の検証用スクリプトには、存在しない`script.js`を200期待に含めた誤りがあり失敗した。実ファイル一覧とHTML参照を照合し、実在するassetsの検査に修正して両環境を再実行した。配信実装はこの失敗を理由に変更していない。

`.well-known`は現在の公開ソースに存在しない。架空の機密情報を含まないfixtureで、Android/iOS関連付けファイルのコピー・内容不変・ignore規則を検証した。**実端末での招待/Universal Links/App Links検証の代替ではない**。

## workflowの条件

| イベント | ref | target | 許可するdeploy job |
| --- | --- | --- | --- |
| push | dev | — | devのみ |
| push | main | — | prodのみ |
| push（条件の単体確認） | feature | — | なし（push triggerもdev/main限定） |
| manual | dev / main / feature（各1ケース） | dev | devのみ |
| manual | dev / feature（各1ケース） | prod | validationで停止、deployなし |
| manual | main | prod | prodのみ |

公開用workflowそのものは実行していない。公開なしCIの`web-contracts`は同じ33件を実行し、Firebase認証情報やdeployを必要としない。

## セルフレビュー

code-reviewerの品質・セキュリティ・保守性の観点で、環境混同、公開ファイル境界、元データの変更、相対パス、既存資産、エラー時の停止を確認した。今回の変更範囲で修正必須の指摘は残っていない。独立した第三者レビュー済みという意味ではない。

注意点として、ルートconfigを使う手動deployは環境分離を迂回するため、READMEに生成config必須の運用を明記した。`noindex`は認証・秘匿ではない。既存ドメインをリダイレクトせず、招待URL等の互換性は維持する設計だが、実環境の関連付けを未確認のまま保証しない。

## 公開前に残すチェックポイント

1. オーナーのレビュー後に#322をdevへ統合し、実dev Hostingの独自ドメインとweb.appでHTTPを再確認。
2. #323の最終dev HEAD全体を検証。既存のネイティブ成長分析変更を含むため、このSEO検証だけでネイティブリリースを承認しない。
3. mainマージ・production公開は明示承認後。公開直後に正式URL、robots、sitemap、OG、導線を再確認。
4. Search Consoleの所有確認・サイトマップ送信・選択canonical/index状態は別途実施。検索順位、リッチリザルト、DL増加、実アプリ動作は本検証の証明対象外。
