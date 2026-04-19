#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  ./scripts/gen_specs_from_rfc.sh --rfc <rfcs/RFC-XXXX-title.md> [--dry-run] [--overwrite]

Options:
  --rfc <path>   Path to RFC markdown file.
  --dry-run      Print planned file writes without creating files.
  --overwrite    Overwrite existing target files for create rows.

Notes:
  - This generator writes Spec Led subject stubs under `.spec/specs/`.
  - It expects Spec Creation Plan rows whose target path already uses the
    `.spec/specs/<subject>.spec.md` form.
USAGE
}

trim() {
  echo "$1" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//'
}

titleize() {
  echo "$1" \
    | tr '_' ' ' \
    | tr '-' ' ' \
    | awk '{for(i=1;i<=NF;i++){$i=toupper(substr($i,1,1)) tolower(substr($i,2))}; print}'
}

to_subject_id() {
  local spec_path="$1"
  local slug

  slug="${spec_path#.spec/specs/}"
  slug="${slug%.spec.md}"
  slug="$(echo "$slug" | tr '/-' '._' | tr '[:upper:]' '[:lower:]')"

  echo "ashui.${slug}"
}

render_list_or_none() {
  local lines="$1"

  if [[ -n "$lines" ]]; then
    printf '%s' "$lines"
  else
    echo "- None recorded in the RFC plan"
  fi
}

ROOT="${RFC_GOVERNANCE_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
cd "$ROOT"

RFC_PATH=""
DRY_RUN=0
OVERWRITE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --rfc)
      RFC_PATH="${2:-}"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --overwrite)
      OVERWRITE=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: unknown argument: $1"
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$RFC_PATH" ]]; then
  echo "ERROR: --rfc is required"
  usage
  exit 1
fi

if [[ ! -f "$RFC_PATH" ]]; then
  echo "ERROR: RFC file not found: $RFC_PATH"
  exit 1
fi

if ! rg -q '^## Spec Creation Plan$' "$RFC_PATH"; then
  echo "ERROR: RFC is missing '## Spec Creation Plan' section: $RFC_PATH"
  exit 1
fi

RFC_ID="$(rg -o '^- RFC ID: `RFC-[0-9]{4}`$' "$RFC_PATH" | head -n1 | sed -E 's/.*`(RFC-[0-9]{4})`.*/\1/' || true)"
if [[ -z "$RFC_ID" ]]; then
  RFC_ID="$(basename "$RFC_PATH" | sed -E 's/^(RFC-[0-9]{4})-.+$/\1/')"
fi

RFC_PATH_REL="$RFC_PATH"
if [[ "$RFC_PATH" == "$ROOT"/* ]]; then
  RFC_PATH_REL="${RFC_PATH#$ROOT/}"
fi

CURRENT_TRUTH_REFS="$(rg -o '\.spec/(specs|decisions)/[A-Za-z0-9._/-]+\.md' "$RFC_PATH" | sort -u || true)"

PLAN_BLOCK="$(awk '/^## Spec Creation Plan/{flag=1;next}/^## /{if(flag)exit}flag' "$RFC_PATH")"
if [[ -z "$PLAN_BLOCK" ]]; then
  echo "ERROR: empty Spec Creation Plan in $RFC_PATH"
  exit 1
fi

rows_seen=0
create_rows=0
created=0
skipped=0
errors=0

while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  [[ "$line" == \|* ]] || continue

  if echo "$line" | rg -q '^\|[[:space:]]*(Action|Spec)[[:space:]]*\|'; then
    continue
  fi

  if echo "$line" | rg -q '^\|[[:space:]-]+\|'; then
    continue
  fi

  if ! echo "$line" | rg -q '[A-Za-z0-9]'; then
    continue
  fi

  rows_seen=$((rows_seen + 1))

  IFS='|' read -r _ col1 col2 col3 col4 col5 col6 col7 col8 _ <<< "$line"

  col1="$(trim "$col1")"
  col2="$(trim "$col2")"
  col3="$(trim "$col3")"
  col4="$(trim "$col4")"
  col5="$(trim "$col5")"
  col6="$(trim "$col6")"
  col7="$(trim "$col7")"
  col8="$(trim "$col8")"

  action="create"
  spec_path="$col1"
  component_title="$col2"
  control_plane="$col3"
  req_cell="$col4"
  scn_cell="$col5"
  ac_cell="$col6"

  if [[ "$col1" =~ ^(create|update|skip)$ ]]; then
    action="$(echo "$col1" | tr '[:upper:]' '[:lower:]')"
    spec_path="$col2"
    component_title="$col3"
    control_plane="$col4"
    req_cell="$col5"
    scn_cell="$col6"
    ac_cell="$col7"
  fi

  if [[ "$action" != "create" ]]; then
    echo "INFO: skipping non-create action '$action' for $spec_path"
    continue
  fi

  create_rows=$((create_rows + 1))

  if ! echo "$spec_path" | rg -q '^\.spec/specs/.+\.spec\.md$'; then
    echo "ERROR: invalid spec path '$spec_path' (must match .spec/specs/*.spec.md)"
    errors=$((errors + 1))
    continue
  fi

  if [[ -z "$component_title" ]]; then
    component_title="$(titleize "$(basename "$spec_path" .spec.md)")"
  fi

  if [[ -f "$spec_path" && "$OVERWRITE" -eq 0 ]]; then
    echo "SKIP: $spec_path already exists (use --overwrite to replace)"
    skipped=$((skipped + 1))
    continue
  fi

  subject_id="$(to_subject_id "$spec_path")"

  req_tokens="$(echo "$req_cell" | rg -o 'REQ-[A-Z]+(?:-[0-9]{3}|-\*)?' | awk '!seen[$0]++' || true)"
  scn_tokens="$(echo "$scn_cell" | rg -o 'SCN-[0-9A-Z]+' | awk '!seen[$0]++' || true)"
  ac_tokens="$(echo "$ac_cell" | rg -o 'AC-[0-9]{2}' | awk '!seen[$0]++' || true)"

  req_lines=""
  while IFS= read -r req; do
    [[ -z "$req" ]] && continue
    req_lines+="- \`$req\`"$'\n'
  done <<< "$req_tokens"

  scn_lines=""
  while IFS= read -r scn; do
    [[ -z "$scn" ]] && continue
    scn_lines+="- \`$scn\`"$'\n'
  done <<< "$scn_tokens"

  ac_lines=""
  while IFS= read -r ac; do
    [[ -z "$ac" ]] && continue
    ac_lines+="- \`$ac\`: TODO translate this acceptance criterion into a subject requirement and proof."$'\n'
  done <<< "$ac_tokens"

  truth_lines=""
  while IFS= read -r truth_ref; do
    [[ -z "$truth_ref" ]] && continue
    truth_lines+="- \`$truth_ref\`"$'\n'
  done <<< "$CURRENT_TRUTH_REFS"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "DRY RUN: would write $spec_path"
    continue
  fi

  mkdir -p "$(dirname "$spec_path")"

  cat > "$spec_path" <<EOF_SPEC
# $component_title

## Intent

\`$component_title\` is introduced by \`$RFC_ID\` and should capture the
current-truth contract for this surface in Spec Led form.

## RFC Context

- RFC source: \`$RFC_PATH_REL\`
- Control plane: \`${control_plane:-TODO}\`

## RFC Mapping

### Imported Requirement Tokens

$(render_list_or_none "$req_lines")
### Imported Scenario Tokens

$(render_list_or_none "$scn_lines")
### Imported Acceptance Criteria

$(render_list_or_none "$ac_lines")
### Related Current Truth Refs Mentioned In The RFC

$(render_list_or_none "$truth_lines")
```spec-meta
id: $subject_id
kind: module
status: active
summary: TODO: summarize the behavior this subject governs.
surface:
  - TODO
```

## Requirements

```spec-requirements
- id: ${subject_id}.todo_requirement
  statement: TODO: translate the RFC intent for $component_title into a normative requirement.
  priority: must
  stability: evolving
```

## Verification

```spec-verification
- kind: command
  target: TODO
  covers:
    - ${subject_id}.todo_requirement
```
EOF_SPEC

  created=$((created + 1))
  echo "CREATED: $spec_path"
done <<< "$PLAN_BLOCK"

if [[ "$rows_seen" -eq 0 ]]; then
  echo "ERROR: no table rows found under Spec Creation Plan in $RFC_PATH"
  exit 1
fi

if [[ "$errors" -ne 0 ]]; then
  echo ""
  echo "Spec generation failed with $errors validation error(s)."
  exit 1
fi

echo ""
echo "Processed RFC: $RFC_PATH"
echo "Plan rows: $rows_seen"
echo "Create rows: $create_rows"
echo "Created: $created"
echo "Skipped existing: $skipped"
