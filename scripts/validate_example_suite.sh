#!/usr/bin/env bash
set -euo pipefail

ROOT="${EXAMPLE_SUITE_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
cd "$ROOT"

mix ash_ui.examples.validate
