#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

[[ -f .env ]] || { echo ".env fehlt."; exit 1; }

set -a
source .env
set +a

required_vars=(
  SERVER_USER
  POSTGRES_USER
  POSTGRES_PASSWORD
  POSTGRES_DB
)

for var_name in "${required_vars[@]}"; do
  if [[ -z "${!var_name:-}" ]]; then
    echo "Pflichtvariable fehlt oder ist leer: ${var_name}"
    exit 1
  fi
done

echo ".env ist vollständig."
