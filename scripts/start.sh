#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [[ ! -f .env ]]; then
  echo "Fehler: .env fehlt. Bitte zuerst ./scripts/init-env.sh ausführen."
  exit 1
fi

docker compose up -d

echo
echo "Infrastruktur wurde gestartet."
echo "Monitoring: http://<PI-IP>/monitoring/"
