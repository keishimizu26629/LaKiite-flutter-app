# #310 SEO環境分離とdev→main公開準備

更新日: 2026-09-08 / Refs #310, #315 / 公開準備PR #323

## 目的・範囲

本番の正式URLを `https://lakiite.inoworl.com/` に揃え、開発用Hostingだけを検索対象から除外する。
ユーザーの「dev→mainのPR作成とSEO修正」の承認に基づく。PR #323はDraft、実装は既存の専用worktree / PR #322へ追記する。最新origin/devは `18d3c3a`、作業前HEADは `f6a4e12`、作業前の追跡ファイル差分は空。

前回の公開HTTP/DNS確認では、独自ドメインはdev/prodとも既存Firebase Hostingに接続済み。DNS移転は不要。本番は旧LP、devにはnoindexがなく、canonical等がweb.app側を指していた。

## 設計判断

- 採用: 元の`web/`は本番用の静的HTMLとし、Node標準機能で環境別の独立した配信成果物を生成する。devにだけHTTP `X-Robots-Tag: noindex, nofollow`を付け、devのrobotsからサイトマップ案内を外し、dev用成果物にサイトマップを含めない。
- 不採用: JavaScriptによるnoindex切り替え。初期HTTPレスポンスで環境差を表す。
- 不採用: 独自ドメイン全体への一括リダイレクト。既存招待リンク・アプリ関連付けへの影響が未確認のため、既存URLを維持しcanonicalで正式URLを示す。
- 本番のHTML、OG、JSON-LD、robots、sitemapは同じ独自ドメインを使用。法務文書の本文、Flutter、Firebase設定値、認証、Airbridgeは変更しない。
- 配信成果物は新規一時ディレクトリに生成し、既存ファイルを削除・上書きしない。`web/README.md`、秘密ファイル、symlink、リポジトリ全体は配信しない。既存の`.well-known`があれば内容を改変せず維持し、新規生成はしない。

## タスク

1. `scripts/test_web_landing.mjs`, `scripts/test_hosting_seo.mjs`: 正式ドメイン、公開7ページの固有canonical、dev/prod成果物、robots/sitemap、既存資産・関連付けの維持、異常入力、workflowの環境対応を先にテスト。未実装で失敗を確認する。
2. `web/index.html`, `web/robots.txt`, `web/sitemap.xml`, sitemap掲載HTML6件: URLを統一。説明・法務本文はそのまま。
3. `scripts/prepare_hosting.mjs`: dev/prod明示必須の成果物生成。devだけnoindex、本番にnoindexを混入させない。出力は専用firebase.jsonのパスのみ。
4. `.github/workflows/deploy_firebase_hosting.yml`: Node検証→対象環境の生成→生成configでHosting deploy。prodはmainのみ。push/manualの条件を排他的にし、dev ref + target=prodで両環境が動く経路をなくす。
   `.github/workflows/ci.yml`にも同じNode検証を追加し、Hosting公開なしでPRの最新コミットを確認できるようにする。最終結果集約の依存・成功条件にも含める。
5. `web/README.md`: 新しい配信方法、正式ドメイン、公開境界、Search Consoleの人間確認を記載。古いGitHub Pages手順を現行手順と混同しないよう整理。
6. 静的テスト、Firebase Hosting Emulatorの実HTTP（dev/prodのheader、robots、sitemap、404）、Flutter解析、コードレビュー。ルートの環境設定ファイル・秘密値は表示しない。
7. PR #322に検証結果を追記し、#323には取り込み順を記録。main/devへのマージ、実環境へのdeploy、Search Console変更、Store Console反映は行わない。

## 完了条件と残作業

本番用成果物はindex可能、dev用成果物はnoindex。両方のHTMLが本番独自ドメインをcanonicalとして一貫して示す。既存のCSS/画像/ストア導線/アプリ関連付けファイルは保持。静的な変更前テストの失敗と、変更後の成功、EmulatorのHTTP結果を残す。

公開判断の担当はオーナー。#322をレビューしてdevへ取り込んだ後、dev Hostingを実測し、最終dev HEAD全体を#323で確認する。#323には既存のアプリ分析変更も含まれる。mainマージ時に本番Hostingが公開されるため、明示承認が必要。
Search Consoleでの所有確認・サイトマップ送信・Google選択canonical・検索表示の確認、実際の順位やDLへの効果検証は別のチェックポイントであり、今回のテスト成功から推定しない。

## 実装・ローカル確認の到達点（2026-09-08）

タスク1〜6を実施。34件のNodeテスト、Emulatorのdev/prod実HTTP、workflowの9条件、Flutter解析を確認した。詳細は[SEO検証結果](issue-310-seo-verification.md)。PR更新と最新SHAのCI結果はPR #322に記録する。#323は#322未統合のdevを指すDraftであり、SEOを含むリリース全体の検証完了とは扱わない。
