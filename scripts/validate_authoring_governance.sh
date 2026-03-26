#!/usr/bin/env bash
set -euo pipefail

ROOT="${AUTHORING_GOVERNANCE_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
cd "$ROOT"

failures=0

fail() {
  echo "FAIL: $1"
  failures=1
}

is_allowed_reference_file() {
  local file="$1"

  case "$file" in
    CHANGELOG.md) return 0 ;;
    guides/user/UG-0005-migration-v0-to-v1.md) return 0 ;;
    specs/adr/*) return 0 ;;
    *) return 1 ;;
  esac
}

echo "Checking public authoring surfaces..."

doc_pattern='AshUI\.DSL\.Builder|AshUI\.Authoring\.(Document|Migrator|LegacyBuilder|migrate_legacy_dsl|migrate_legacy_screen_attrs)|builder-first|builder-authored|legacy builder'
example_pattern='AshUI\.DSL\.Builder|AshUI\.Authoring\.(Document|Migrator|LegacyBuilder|Screen|migrate_legacy_dsl|migrate_legacy_screen_attrs)'

while IFS=: read -r file line _; do
  [[ -z "$file" ]] && continue

  if ! is_allowed_reference_file "$file"; then
    fail "legacy authoring reference outside approved historical docs: ${file}:${line}"
  fi
done < <(rg -n "$doc_pattern" README.md CHANGELOG.md guides examples specs/adr -g '*.md' -g '*.ex' 2>/dev/null || true)

while IFS=: read -r file line _; do
  [[ -z "$file" ]] && continue
  fail "public example uses legacy authoring helpers: ${file}:${line}"
done < <(rg -n "$example_pattern" examples -g '*.ex' -g '*.md' 2>/dev/null || true)

if [[ "$failures" -ne 0 ]]; then
  echo "Authoring governance validation failed."
  exit 1
fi

echo "Authoring governance validation passed."
exit 0
