#!/usr/bin/env bash
set -Eeuo pipefail

cd "$(dirname "$0")/.."

if [[ -f .env ]]; then
  echo ".env existiert bereits. Nichts zu tun."
  exit 0
fi

cp .env.example .env
echo ".env wurde aus .env.example erstellt."
echo "Bitte SERVER_USER und POSTGRES_PASSWORD in .env anpassen."
