#!/usr/bin/env bash
set -euo pipefail

ROOT="${GOVERNANCE_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
cd "$ROOT"

failures=0

fail() {
  echo "FAIL: $1"
  failures=1
}

run_spec_validate() {
  if command -v erl >/dev/null 2>&1 && command -v mix >/dev/null 2>&1; then
    mix spec.validate --strict
    return
  fi

  if command -v cmd.exe >/dev/null 2>&1 && command -v wslpath >/dev/null 2>&1; then
    local win_root
    win_root="$(wslpath -w "$ROOT")"
    cmd.exe /c "cd /d ${win_root} && mix.bat spec.validate --strict"
    return
  fi

  return 127
}

echo "Checking .spec workspace files..."
required_files=(
  ".spec/README.md"
  ".spec/AGENTS.md"
  ".spec/decisions/README.md"
  ".spec/specs/spec_system.spec.md"
  ".spec/specs/package.spec.md"
)

for file in "${required_files[@]}"; do
  if [[ ! -f "$file" ]]; then
    fail "missing required .spec file: $file"
  fi
done

if [[ ! -d ".spec/specs" ]]; then
  fail "missing .spec/specs directory"
fi

if [[ ! -d ".spec/decisions" ]]; then
  fail "missing .spec/decisions directory"
fi

subject_count="$(find .spec/specs -maxdepth 1 -type f -name '*.spec.md' | wc -l | tr -d ' ')"
decision_count="$(find .spec/decisions -maxdepth 1 -type f -name '*.md' ! -name 'README.md' | wc -l | tr -d ' ')"

if [[ "$subject_count" -lt 5 ]]; then
  fail "expected at least 5 authored subject specs in .spec/specs"
fi

if [[ "$decision_count" -lt 4 ]]; then
  fail "expected at least 4 authored decisions in .spec/decisions"
fi

echo "Checking Spec Led validation..."
if ! run_spec_validate; then
  fail "mix spec.validate --strict failed"
fi

if [[ ! -f ".spec/state.json" ]]; then
  fail "missing generated state file: .spec/state.json"
fi

if [[ "$failures" -ne 0 ]]; then
  echo "Specs governance validation failed."
  exit 1
fi

echo "Specs governance validation passed."
exit 0
