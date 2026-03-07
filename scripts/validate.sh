#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

[[ -f .env ]] || { echo "Fehler: .env fehlt."; exit 1; }

docker compose --env-file "$ROOT_DIR/.env" config >/dev/null
echo "Compose-Konfiguration ist gültig."
