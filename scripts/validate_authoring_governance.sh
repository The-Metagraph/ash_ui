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

doc_pattern='AshUI\.DSL\.Builder|AshUI\.Authoring\.(Document|Migrator|LegacyBuilder|Screen|migrate_legacy_dsl|migrate_legacy_screen_attrs)|UnifiedUi\.Dsl|builder-first|builder-authored|legacy builder|upstream-authored|monolithic screen document|screen-document authority|document-first|BasicDashboard\.AuthoredScreen'
example_pattern='AshUI\.DSL\.Builder|AshUI\.Authoring\.(Document|Migrator|LegacyBuilder|Screen|migrate_legacy_dsl|migrate_legacy_screen_attrs)|UnifiedUi\.Dsl|AuthoredScreen|monolithic screen document|screen-document authority|document-first'

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

require_match() {
  local pattern="$1"
  local description="$2"
  shift 2

  if ! rg -q "$pattern" "$@" 2>/dev/null; then
    fail "missing ${description} in expected public surfaces"
  fi
}

echo "Checking resource-first authoring markers..."

require_match \
  'AshUI\.Resource\.DSL\.Screen' \
  'screen resource authoring guidance' \
  README.md \
  guides/user/UG-0001-getting-started.md \
  examples/basic_dashboard/README.md

require_match \
  'AshUI\.Resource\.DSL\.Element' \
  'element resource authoring guidance' \
  README.md \
  guides/user/UG-0001-getting-started.md \
  examples/basic_dashboard/README.md

require_match \
  'AshUI\.Resource\.Authority' \
  'resource authority persistence guidance' \
  README.md \
  guides/user/UG-0001-getting-started.md \
  guides/user/UG-0002-resources.md \
  examples/basic_dashboard/README.md

require_match \
  'ui_relationships' \
  'relationship-driven composition guidance' \
  README.md \
  guides/user/UG-0001-getting-started.md \
  guides/user/UG-0002-resources.md \
  examples/basic_dashboard/lib/basic_dashboard_screen.ex \
  examples/basic_dashboard/README.md

require_match \
  'ui_bindings' \
  'element-local binding guidance' \
  README.md \
  guides/user/UG-0001-getting-started.md \
  guides/user/UG-0002-resources.md \
  guides/user/UG-0003-data-binding.md \
  examples/basic_dashboard/lib/basic_dashboard_screen.ex \
  examples/basic_dashboard/README.md

require_match \
  'ui_actions' \
  'element-local action guidance' \
  README.md \
  guides/user/UG-0001-getting-started.md \
  guides/user/UG-0002-resources.md \
  guides/user/UG-0003-data-binding.md \
  examples/basic_dashboard/lib/basic_dashboard_screen.ex \
  examples/basic_dashboard/README.md

if [[ "$failures" -ne 0 ]]; then
  echo "Authoring governance validation failed."
  exit 1
fi

echo "Authoring governance validation passed."
exit 0
