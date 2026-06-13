#!/usr/bin/env bash

set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

if [ ! -d ".githooks" ]; then
  echo ".githooks directory was not found."
  exit 1
fi

chmod +x .githooks/pre-commit .githooks/pre-push
git config core.hooksPath .githooks

echo "Git hooks installed."
echo "pre-commit: whitespace, format, analyze, unit/infrastructure tests when relevant"
echo "pre-push: presentation/widget tests when relevant"
