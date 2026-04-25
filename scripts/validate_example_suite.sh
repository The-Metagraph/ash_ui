#!/usr/bin/env bash
set -euo pipefail

ROOT="${EXAMPLE_SUITE_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
cd "$ROOT"

mix ash_ui.examples.validate
mix ash_ui.examples.list >/dev/null
mix ash_ui.examples.preview button >/dev/null
mix ash_ui.examples.preview cluster_dashboard >/dev/null
mix ash_ui.examples.start dialog --dry-run >/dev/null
mix ash_ui.examples.start status --dry-run --actor operator >/dev/null
mix ash_ui.examples.report >/dev/null
