# Codex 作業メモ

このメモは、LaKiite Flutter app で調査・実装・検証を始める前に確認するプロジェクト固有の運用情報です。Issue 固有の仕様ではなく、毎回の作業で使う基本手順だけを置きます。

## 起動とデバッグ

- VS Code/Cursor のデバッグは `.vscode/launch.json` を優先して確認する。
- dev 環境での通常デバッグは `Development (Dev Flavor)` を使う。
- CLI で同じ条件を再現する場合は、原則として次の形に合わせる。

```bash
fvm flutter run --debug --flavor dev --dart-define-from-file=dart_define/dev_dart_define.json
```

- prod 相当を確認する場合は `Production (Prod Flavor)` を使う。安易に prod 設定で実データ操作をしない。
- `dart_define/*.json` は環境値を含むため、内容確認が必要な場合だけユーザーに確認してから読む。通常は `launch.json` の参照先として扱えばよい。

## Firebase 環境確認

- dev debug では dev Firebase に接続される前提だが、調査時は起動ログで `env` と `projectId` を確認する。
- dev の Firebase project は `lakiite-flutter-app-dev`。
- Firebase 接続や Push/Functions/Rules の挙動を調べるときは、アプリログだけで断定せず、必要に応じて Firebase Console、`gcloud logging read`、Functions の実行ログも確認する。
- Firebase Console をブラウザで確認する必要がある場合は、Playwright/Chrome DevTools MCP を使ってよい。

## Android 実機調査

- 実機確認が必要なときは、まず接続端末を確認する。

```bash
adb devices
```

- dev アプリを停止する場合は、dev package を対象にする。

```bash
adb shell am force-stop com.inoworl.lakiite.dev
```

- 実機ログは `flutter run` の出力、`adb logcat`、アプリ内の debug log を合わせて見る。
- 実機で再現確認した場合は、使用端末、ビルド flavor、接続先 Firebase project、操作したテストアカウントを最終報告に残す。

## 関連リポジトリ

- Flutter app だけで完結しない挙動は、隣接 repo の `../lakiite-firebase-commons` も確認する。
- `lakiite-firebase-commons` には Firestore Rules、Storage Rules、Cloud Functions、関連テストが含まれる。
- クライアント側の失敗に見えても、Rules や Functions の責務で動く処理があるため、境界を確認してから修正する。
- 2 repo にまたがる変更は、原則として repo ごとにブランチ・コミット・PR を分ける。

## ローカル検証

- Flutter 側の基本検証は FVM 経由で実行する。

```bash
fvm dart format <changed dart files>
fvm flutter test <relevant tests>
fvm flutter analyze
```

- `lakiite-firebase-commons` 側の Rules/Functions テストは、その repo の `package.json` scripts と GitHub Actions を確認してから実行する。
- ローカル依存が壊れている場合は、失敗ログを残し、PR 本文や報告に未検証理由を明記する。

## PR 作成

- Issue を解決する PR の本文には、対象 Issue を自動クローズするために `Closes #<issue番号>` を必ず記載する。
- 複数 Issue を解決する場合は、対象 Issue ごとに `Closes #<issue番号>` を記載する。
- Issue を解決せず参照だけする場合は、`Refs #<issue番号>` を使う。
- PR 作成前に、本文内の Issue 番号が今回の変更範囲と一致しているか確認する。

## セキュリティと機密情報

- `.env`、鍵ファイル、secret/config、API key を含む可能性があるファイルは読まない。
- Firebase token、service account、private key、署名鍵が必要になった場合は、ユーザーに確認してから扱う。
- ログや PR 本文には token、メール以外の認証情報、秘密値を出さない。
