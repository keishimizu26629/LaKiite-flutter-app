# #310 LP検証記録

検証日: 2026-09-08 JST
担当: Codex / 公開判断: プロダクトオーナー

## 対象

- branch: `codex/issue-310-lp-store-entry`
- base: `0034b9a9ddcb34d7a5b5bd8559bad080050d54d9`（PR #316をマージしたdev）
- ローカルの静的`web/`成果物。Flutterアプリコード・Firebase設定は変更していない。
- PR作成前のローカル検証スナップショット。以後のPR作成・CI・公開状況はIssue #310と関連PRを正とする。
- 検証時点ではFirebase Hosting dev/prod、ストアには未反映。

## 自動テスト

`node --test scripts/test_web_landing.mjs`: **13 passed / 0 failed**。

最初の10件は実装前に9 failed / 1 passed。冒頭／末尾のリンク契約、法務導線、メタ情報、構造化データ、robots/sitemapの不足で失敗を確認してから実装した。
その後、登録方法の文言、見出し順、アクセント文字色の3回帰テストを追加し、それぞれ変更前の失敗と修正後の成功を確認した。

`git diff --check`: 成功。
外部パッケージ追加なし。Node標準機能のみで実行できる。

## ブラウザ確認

Chromiumによるローカル表示・viewportエミュレーション。実機GalaxyやSafariの再検証ではない。

| 条件 | 結果 |
|---|---|
| 320×720 / 390×844 / 1440×1000 | 横のはみ出しなし。通常文字サイズでは冒頭の両ストアリンクが初期viewport内に表示される |
| JavaScript無効（390px） | 冒頭と末尾の両ストアリンクへTabで到達し、hrefが静的に利用可能 |
| 200%文字拡大（root 32px / 390px） | テキストと操作の横はみ出しなし。ストアボタンはスクロール下へ移るが、Tab到達・フォーカス表示が可能 |
| reduced motion | `scroll-behavior: auto`。CSSアニメーション・transitionを無効化 |
| キーボード | 上記条件で両配置のストアリンクに到達。フォーカスのoutline表示と他要素に隠れていないことを確認 |
| 画像・実行エラー | 初期表示で破損画像なし。自動ブラウザ確認中のpageerrorなし |

Lighthouse desktop snapshot: Accessibility **100** / Best Practices **100** / SEO **100**（29項目成功、失敗0）。
修正前はAccessibility 93で文字色・見出し順の指摘を検出。色トークンと見出しレベルを修正して再検査した。
これは検査時点の自動診断であり、WCAG適合認証・検索順位・ストアCVR・DL増を保証するものではない。

当初のブラウザ補助スクリプトは要素の安定待ちでtimeoutした。アプリ障害とは判断せず、待機方式を変更して再実行し、作成した検証用contextは終了した。手動の表示確認も併用している。

## Flutter解析と環境依存ブロッカーの解消

初回の`fvm flutter analyze`: **失敗（4 errors）**。以下は解消前の記録。

- `lib/config/app_config.dart`: `../firebase_options.dart`が存在せず、`DefaultFirebaseOptions`を解決できない。
- `lib/infrastructure/firebase/push_notification_service.dart`: `../../firebase_options.dart`が存在せず、`DefaultFirebaseOptions`を解決できない。

原因はLP作業用worktreeを作る際にCodexがhatcherへ`--no-copy`を指定したこと。メインrepoの既存auto-copy設定には対象が登録済みで、設定不足ではなかった。

2026-09-08にユーザーが今後も自動コピーされるよう修正することを指示。メインrepoから同じrepoのローカルworktreeへの無改変コピーに限定し、`lib/firebase_options.dart`と`.hatcher-auto-copy.json`の不足分を補完した。内容は表示・解析せず、新規生成・設定変更・Git追跡・リモート送信もしていない。

再発防止としてワークスペースの`AGENTS.md`に通常作成で`--no-copy`を使わないこと、同範囲のコピーでは再承認を求めないこと、作成直後に存在・元ファイルとの一致・Gitのignore/未追跡状態を確認することを明記した。コピー元がない場合や既存ファイルと異なる場合は停止し、無断生成・上書きはしない。

検証結果:

- Hatcher v1.3.0で実際のpath-only auto-copy設定とダミーFirebaseファイルを使った隔離repoを作り、メインrepo→worktree→子worktreeの2回の自動コピーを確認。
- 上記2つのworktreeと今回のLP worktreeで、両ファイルの存在・`cmp -s`による一致・ignoredかつ未追跡であることを確認。ファイル本文やhash値は出力していない。
- 補完後の`fvm flutter analyze --no-pub`: **成功（No issues found）**。
- `node --test scripts/test_web_landing.mjs`再実行: **13 passed / 0 failed**。
- `git diff --check`: 成功。commit hookの迂回なし。

なお、基底のPR #316は別途、同日再実行したGitHub CIの4ジョブすべて成功を確認してからdevへマージ済み。本worktreeでの解析失敗を成功扱いする根拠には使わない。

## PR作成直前の最終確認

- 最新`origin/dev`をfetchし、作業ブランチの基底と一致することを確認。
- 変更はLP、静的検査スクリプト、関連ドキュメントに限定。Flutterコード・Firebase設定・依存lockfile・配信workflowの変更なし。
- 自己レビューでPR作成を妨げる指摘なし。ブラウザの検証範囲と未計測・未配信の制約をPRに明記する。
- `node --test scripts/test_web_landing.mjs`: **13 passed / 0 failed**。`node --check scripts/test_web_landing.mjs`: 成功。
- `fvm flutter analyze --no-pub`: **成功（No issues found）**。`git diff --check`: 成功。
- GitHubの`PR Tests`は`workflow_dispatch`のみ。PR作成だけでは自動実行されないため、CI結果は対象HEADのrunで別途確認する。LPの13テストはローカル実行であり、この既存CIには含まれない。

## 検証時点の後続作業と公開条件

- [x] 限定コピーの承認・不足分補完・自動コピー検証・Flutter解析。
- [ ] commit / push / PR。
- [ ] レビュー済み成果物を既存のdev専用Hosting経路で確認。
- [ ] 本番の現行LPとの差分と画像・導線をオーナー確認。
- [ ] 本番公開の明示承認と公開後の確認。
- [ ] 必要時、承認済みtracking linkとprivacyを確認して計測を追加。

現段階はraw store URL。`data-growth-*`だけではクリックやDLを収集していない。実装計画のcampaign名は制作候補で、キャンペーンを実施した記録ではない。
#310は残作業のため開いたままにする。
