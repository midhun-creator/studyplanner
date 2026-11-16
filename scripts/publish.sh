#!/usr/bin/env bash
# One-command publish: checks, commit, push.
#   First time:  bash scripts/publish.sh "feat: initial release" https://github.com/<you>/studyplanner.git
#   Afterwards:  bash scripts/publish.sh "fix: your message"
set -euo pipefail

MSG="${1:-chore: update}"
REMOTE_URL="${2:-}"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git init -q -b main
  echo "OK Initialised git repo"
fi

if ! git remote get-url origin >/dev/null 2>&1; then
  if [ -z "$REMOTE_URL" ]; then
    echo "x No remote yet. Run: bash scripts/publish.sh \"msg\" https://github.com/<you>/<repo>.git"
    exit 1
  fi
  git remote add origin "$REMOTE_URL"
  echo "OK Added remote $REMOTE_URL"
fi

if [ -f package.json ]; then
  echo "-> Checks"
  npm run --silent check
  npm test --silent
fi

git add -A

# Never commit env files (except .env.example)
LEAKS="$(git diff --cached --name-only | grep -E '(^|/)\.env(\..*)?$' | grep -v '\.env\.example$' || true)"
if [ -n "$LEAKS" ]; then
  echo "x Refusing to commit env files:"; echo "$LEAKS"
  git reset -q
  exit 1
fi

if git diff --cached --quiet; then
  echo "Nothing to commit."
else
  git commit -q -m "$MSG"
  echo "OK Committed: $MSG"
fi

BRANCH="$(git branch --show-current)"
git push -u origin "$BRANCH"
echo "OK Pushed to origin/$BRANCH"
