#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
if [[ -f "$ROOT_DIR/.env" ]]; then
  echo ".env existiert bereits. Nichts zu tun."
  exit 0
fi
cp "$ROOT_DIR/.env.example" "$ROOT_DIR/.env"
echo ".env wurde aus .env.example erstellt."
echo "Bitte SERVER_USER und POSTGRES_PASSWORD in .env anpassen."
