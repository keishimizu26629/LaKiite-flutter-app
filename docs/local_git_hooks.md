# Local Git Hooks

このリポジトリでは、PR更新ごとのGitHub Actions自動テストを止め、ローカルGit hooksで検証する運用に寄せています。

## セットアップ

```bash
./scripts/install_git_hooks.sh
```

このコマンドは `git config core.hooksPath .githooks` を設定します。設定はローカルリポジトリごとに保存されます。

## 実行される検証

`pre-commit`:

- `git diff --cached --check`
- staged Dart files の `fvm dart format --output=none --set-exit-if-changed`
- `fvm flutter analyze`
- `lib` / `test/domain` / `test/utils` / `test/application` / `test/infrastructure` などに変更がある場合の単体・infrastructureテスト

`pre-push`:

- `lib` / `test/presentation` などに変更がある場合の presentation/widget テスト

## GitHub Actions

`.github/workflows/ci.yml` は `workflow_dispatch` の手動実行専用です。PRの `opened` / `synchronize` では自動実行されません。

必要なときだけGitHub UIまたは次のコマンドで実行します。

```bash
gh workflow run ci.yml --ref <branch-name>
```

AIエージェント運用では、原則として `--no-verify` でhooksを回避しないでください。
