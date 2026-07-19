#!/usr/bin/env bash
# Point this clone at the shared hooks in .githooks/
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

git config core.hooksPath .githooks
chmod +x .githooks/pre-commit .githooks/pre-push

echo "Git hooks installed (core.hooksPath=.githooks)."
echo "Commits and pushes to main/master are now blocked in this clone."
