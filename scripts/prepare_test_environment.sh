#!/usr/bin/env bash
set -euo pipefail

ROOT="${PREPARE_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
cd "$ROOT"

export MIX_ENV="${MIX_ENV:-test}"

echo "Preparing ${MIX_ENV} environment..."

if [[ "${PREPARE_RUN_DEPS:-true}" == "true" ]]; then
  echo "Installing dependencies..."
  mix deps.get
fi

if [[ "${PREPARE_RUN_DB:-true}" == "true" ]]; then
  echo "Ensuring database exists..."
  mix ecto.create

  echo "Running database migrations..."
  mix ecto.migrate
fi
