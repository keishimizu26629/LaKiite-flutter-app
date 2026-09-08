# リリース番号・更新説明の整合

対象読者: LaKiiteのリリース担当。対象: PR #323由来の番号不整合と再発防止。

更新: 2026-09-09 JST（2026-09-08 UTC）。番号の決定・ストア提出・過去履歴の訂正を別々に管理する。

## 採用方針

- 配布済み2.3.0のソースは `75579cec858526e10d7d27a8b02a885a76d7ee57`。
- v2.2.0の既存タグは変更しない。v2.3.0を同じソースで記録し、v2.2.0に訂正を追記する。
- Release Drafterの親runでversion / tag / source SHA / run ID / release ID / 日本語更新説明を一度だけ確定し、上書きしないartifactに保存する。
- 子runは親runを検証して、そのartifactだけを利用する。latest release、ラベル、pubspecへのフォールバックは禁止。
- 手動再配布も元のRelease Drafter run IDを明示する。過去のartifactがなければ停止し、勝手に次の版を採番しない。
- ストア説明はASO案を維持。更新説明はアプリ差分だけを記載し、LP/SEOをアプリ新機能として掲載しない。
- ストア掲載変更とアプリ本体の製品版公開は区別する。後者は今回実行しない。

## 実装・検証順

1. `scripts/test_release_pipeline.mjs`: 発行前後のlatest変化、SHA/run不一致、無効な版、ビルド番号不一致を失敗テストで記録。
2. `scripts/release_manifest.mjs`, `release-notes/ja-JP.json`: 純粋な検証関数と生成・読込CLI、OS別文言の単一ソースを実装。
3. `.github/workflows/release-drafter.yml`: snapshot生成・保存、再実行時の既存snapshot再利用、GitHub文面への利用者向け更新説明追加。
4. `.github/actions/resolve-release-version/action.yml`, prod両workflow: run指定読込へ置換。実IPA/AAB/APKの版と番号をアップロード前に検査。
5. CIに公開を伴わないrelease契約テストを追加。Nodeテスト、workflow lint、Flutter解析、commit hookを実行してPRを作成。
6. 訂正Releaseを記録し、Consoleへ同じ日本語更新説明を反映。Apple認証や公開時の確認が必要なら、その段階で停止して報告。

## 完了条件

- 同じ親runの両OS・再実行が同じversion / source SHA / notesを使う。
- snapshot不在・改変・別run・ビルド内メタデータ不一致はアップロード前に失敗する。
- FirebaseとPlayへの更新説明が共通ファイル由来。Apple用は審査版の「このバージョンの最新情報」に同内容を入力する。
- GitHub Release公開はストア製品版の公開完了と表現しない。

## 今後の運用

1. dev → main PRで `release-notes/ja-JP.json` をアプリ実差分と照合する。ストア掲載説明は `docs/marketing/store/ja-JP/copy.json`、利用者向け更新説明はこのJSONに分ける。
2. mainへのpushでRelease Drafterが確定したタグと説明を `release-manifest` artifactへ保存する。子workflowは成功した親runのID・repository・event・branch・workflow pathを検証して、そのSHAをcheckoutする。
3. 子workflowはartifactに記録された版だけをビルドに使う。アップロード前にIPAのInfo.plist、bundletoolでAABのbase manifest、SDK apkanalyzerでAPK manifestを読み取り、版とビルド番号を比較する。
4. AndroidのPlay内部テスト／Firebase App Distributionは同じ `play/ja-JP.txt` を送る。iOSのaltoolは「このバージョンの最新情報」を設定しないため、`verified-ios-release-<attempt>` artifactの `apple.txt` をApp Store Connectで対象版へ入力する。TestFlightの「テスト内容」も必要なら別途設定する。
5. GitHub Releaseを公開するときも、artifactのversion / sourceSha / notesと照合する。可変のmain先端ではなく、固定したsourceShaにタグを作る。自動の開発者向けChangesにはWeb/CIや既出PRが含まれ得るので、ストアの更新説明としてコピーしない。

各OSの `verified-*-release-<attempt>` artifactには、比較に使用したmetadata JSONと固定manifest・文面を残す。digestは内容の整合チェックであり、署名や改ざん不能の証明ではない。信頼元は検証した親runと、そのrunに結び付いたartifact。

### 再実行と制限

- 手動のprod workflowは任意のversionではなく `release_run_id` が必須。元の成功したmain-push Release Drafter run IDを指定する。手動実行もTestFlight／Play内部テストへの配布操作なので承認が必要。
- 親runの再実行は既存snapshotを再利用する。保存前に失敗したrun、削除・期限切れ・重複artifactは自動復旧せず停止する。latest releaseから再採番したり、別runのartifactへ差し替えたりしない。
- artifact保持は90日。長期再現が必要なら期限前にmanifestを対象Releaseの記録へ保管する。今回以前のrunにはsnapshotがないため、この新しい手動経路では再配布できない。
- iOSの既存ビルド番号方式（commit数+10000）は維持した。同じソースの再アップロードは既存buildとの重複で拒否され得る。バージョンの二重加算修正は、重複uploadの自動成功を保証するものではない。
- 次のmainリリースから有効になる。devに修正をマージするだけでは、既に動いた過去のworkflowやストア配布物は変更されない。

## ローカル検証

```bash
node --test scripts/test_release_pipeline.mjs scripts/test_release_workflows.mjs scripts/test_store_marketing.mjs scripts/test_web_landing.mjs scripts/test_hosting_seo.mjs
python3 -m unittest discover -s scripts -p test_release_artifact.py
actionlint -shellcheck= -pyflakes= .github/workflows/release-drafter.yml .github/workflows/deploy_prod_android.yml .github/workflows/deploy_prod_ios.yml .github/workflows/release-contracts.yml
fvm flutter analyze
```

Pythonテストは生成したbinary plistのIPA fixtureと、Androidツール応答のstubで検証する。Nodeテストは一時git repoでCLI生成→読込→版不一致時の失敗まで実行する。新しい署名付きAAB/IPAのビルドとアップロードは別工程であり、これらのテストだけで完了としない。

## 配布済み2.3.0の照合記録

- source: `75579cec858526e10d7d27a8b02a885a76d7ee57`（既存v2.2.0と同じ）。旧public 2.1.1相当sourceは `383eeeba2821a8b05e7fad4631d47e1a389a1cef`。
- [Android run 34235005680](https://github.com/Inoworl/LaKiite-flutter-app/actions/runs/34235005680): 2.3.0 / 1788875932。Play Console内部テストでも番号を確認。一般公開ではない。
- [iOS run 34235005495](https://github.com/Inoworl/LaKiite-flutter-app/actions/runs/34235005495): 2.3.0 / 10665。IPA検証とTestFlight upload成功ログ。App Store Connectの目視照合はログイン待ち。
- `v2.2.0` 公開時刻 `2026-09-08T13:55:57Z` の後、旧子workflowがlatest=2.2.0にsemver:minorを再適用した。ソースが別になった問題ではなく、番号決定を繰り返した問題。
- 歴史的な2.3.0には新しいsnapshotを後付けしてCI生成物と偽装しない。GitHub訂正履歴は上記runとソースを参照する手動の記録とする。
- 履歴訂正済み: [v2.3.0](https://github.com/Inoworl/LaKiite-flutter-app/releases/tag/v2.3.0) を `2026-09-08T21:14:53Z` に追加。v2.2.0本文に訂正を追記し、両タグが上記sourceを指すことを再取得して確認。タグ移動・削除、アプリ再配布は行っていない。

保守メモ: 掲載・審査・一般公開の状態はConsoleで別々に再確認する。ストアのAIアセット申告は既存画像の来歴を確認してから選択し、Apple認証を自動で推測しない。
