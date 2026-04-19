#!/usr/bin/env bash
set -euo pipefail

ROOT="${CONFORMANCE_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
cd "$ROOT"

REPORT_DIR="${1:-reports/conformance}"
mkdir -p "$REPORT_DIR"

STATUS="${CONFORMANCE_STATUS:-unknown}"
GENERATED_AT="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
SUBJECT_COUNT="$(find .spec/specs -maxdepth 1 -type f -name '*.spec.md' 2>/dev/null | wc -l | tr -d ' ')"
DECISION_COUNT="$(find .spec/decisions -maxdepth 1 -type f -name '*.md' ! -name 'README.md' 2>/dev/null | wc -l | tr -d ' ')"
STATE_PRESENT="false"
if [[ -f ".spec/state.json" ]]; then
  STATE_PRESENT="true"
fi
CONFORMANCE_TEST_FILES="$(rg -l '@(module)?tag.*conformance' test || true)"
if [[ -n "$CONFORMANCE_TEST_FILES" ]]; then
  TEST_FILE_COUNT="$(printf '%s\n' "$CONFORMANCE_TEST_FILES" | sed '/^$/d' | wc -l | tr -d ' ')"
else
  TEST_FILE_COUNT="0"
fi

cat > "$REPORT_DIR/report.md" <<EOF
# Conformance Report

- Generated at: $GENERATED_AT
- Git branch: $(git branch --show-current)
- Git revision: $(git rev-parse --short HEAD)
- Overall status: $STATUS
- Authored .spec subjects: $SUBJECT_COUNT
- Authored .spec decisions: $DECISION_COUNT
- Generated .spec/state.json present: $STATE_PRESENT
- Conformance-tagged test files: $TEST_FILE_COUNT

## Inputs

- [Spec Workspace](../../.spec/README.md)
- [Authored Subjects](../../.spec/specs/)
- [Authored Decisions](../../.spec/decisions/)

## Tagged Test Files

EOF

if [[ -n "$CONFORMANCE_TEST_FILES" ]]; then
  while IFS= read -r file; do
    [[ -z "$file" ]] && continue
    echo "- $file" >> "$REPORT_DIR/report.md"
  done <<<"$CONFORMANCE_TEST_FILES"
else
  echo "- None" >> "$REPORT_DIR/report.md"
fi

cat > "$REPORT_DIR/report.json" <<EOF
{
  "generated_at": "$GENERATED_AT",
  "branch": "$(git branch --show-current)",
  "revision": "$(git rev-parse --short HEAD)",
  "status": "$STATUS",
  "authored_spec_subjects": $SUBJECT_COUNT,
  "authored_spec_decisions": $DECISION_COUNT,
  "state_present": $STATE_PRESENT,
  "conformance_test_files": $TEST_FILE_COUNT
}
EOF

echo "Conformance report written to $REPORT_DIR"
