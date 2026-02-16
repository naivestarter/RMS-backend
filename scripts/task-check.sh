#!/usr/bin/env bash
set -euo pipefail

BASE_REF="${1:-origin/main}"
LOCKED_DOCS=(
  "docs/CONVENTIONS.md"
  "docs/BACKEND_PACKAGES.md"
  "docs/TENANCY.md"
)

if ! git rev-parse --verify --quiet "$BASE_REF" >/dev/null; then
  echo "ERROR: Base ref '$BASE_REF' was not found. Pass a valid base ref as the first argument."
  exit 1
fi

echo "Base ref: $BASE_REF"
echo ""
echo "Changed files:"
CHANGED_FILES="$(git diff --name-only "$BASE_REF"...HEAD)"
if [[ -z "$CHANGED_FILES" ]]; then
  echo "(none)"
else
  printf '%s\n' "$CHANGED_FILES"
fi

echo ""
echo "Checking locked policy docs..."
LOCKED_CHANGED=0
for doc in "${LOCKED_DOCS[@]}"; do
  if git diff --name-only "$BASE_REF"...HEAD -- "$doc" | grep -q .; then
    echo "FAIL: Locked policy doc changed: $doc"
    LOCKED_CHANGED=1
  fi
done

if [[ "$LOCKED_CHANGED" -ne 0 ]]; then
  exit 1
fi

echo "PASS: Locked policy docs unchanged."

echo ""
if [[ -f "vendor/autoload.php" ]]; then
  echo "vendor/autoload.php found; running test command..."
  php artisan test
else
  echo "SKIP: vendor/autoload.php not found; skipping php artisan test."
fi
