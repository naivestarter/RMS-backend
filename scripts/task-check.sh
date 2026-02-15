#!/usr/bin/env bash
set -euo pipefail

BASE_BRANCH="${1:-main}"

echo "== Alpine RMS Task Check =="
echo "Base branch: $BASE_BRANCH"
echo

echo "1) Locked docs must NOT change..."
LOCKED=("docs/CONVENTIONS.md" "docs/BACKEND_PACKAGES.md" "docs/TENANCY.md")
CHANGED_LOCKED=$(git diff --name-only "$BASE_BRANCH"...HEAD -- "${LOCKED[@]}" || true)

if [[ -n "$CHANGED_LOCKED" ]]; then
  echo "FAIL: Locked policy docs changed:"
  echo "$CHANGED_LOCKED"
  exit 1
fi
echo "OK"

echo
echo "2) Show changed files (quick view)..."
git diff --name-only "$BASE_BRANCH"...HEAD | sed 's/^/ - /'

echo
echo "3) Quick sanity: No accidental .env or secrets..."
SECRETS=$(git diff --name-only "$BASE_BRANCH"...HEAD | egrep -i '(^\.env$|\.pem$|\.key$|secrets|credentials)' || true)
if [[ -n "$SECRETS" ]]; then
  echo "FAIL: Potential secrets files changed:"
  echo "$SECRETS"
  exit 1
fi
echo "OK"

echo
echo "4) Local tests (optional; comment out if slow)..."
# Uncomment once you have stable CI; keep enabled early.
php artisan test

echo
echo "PASS: Task are compliant."
