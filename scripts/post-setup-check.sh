#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/common.sh"
ROOT_DIR="$(repo_root)"

section() {
  echo
  echo "==> $1"
}

section "Grundlegende Dateien prüfen"
[[ -f "$ROOT_DIR/compose.yml" ]] || { echo "compose.yml fehlt."; exit 1; }
[[ -f "$ROOT_DIR/.env.example" ]] || { echo ".env.example fehlt."; exit 1; }
[[ -f "$ROOT_DIR/.env" ]] || { echo ".env fehlt."; exit 1; }
[[ -f "$ROOT_DIR/nginx/nginx.conf" ]] || { echo "nginx/nginx.conf fehlt."; exit 1; }
[[ -f "$ROOT_DIR/nginx/conf.d/monitoring.conf" ]] || { echo "nginx/conf.d/monitoring.conf fehlt."; exit 1; }

section "Datenverzeichnisse prüfen"
[[ -d "$ROOT_DIR/data/nginx" ]] || { echo "data/nginx fehlt."; exit 1; }
[[ -d "$ROOT_DIR/data/postgres" ]] || { echo "data/postgres fehlt."; exit 1; }
[[ -d "$ROOT_DIR/data/uptime-kuma" ]] || { echo "data/uptime-kuma fehlt."; exit 1; }

section "Docker prüfen"
if ! command -v docker >/dev/null 2>&1; then
  echo "Docker ist nicht installiert oder nicht im PATH."
  exit 1
fi

docker --version

section "Docker Compose prüfen"
docker compose version || { echo "Docker Compose Plugin fehlt oder Benutzerrechte greifen noch nicht."; exit 1; }

section "Docker-Dienst prüfen"
if ! systemctl is-active --quiet docker; then
  echo "Docker-Dienst läuft nicht."
  exit 1
fi
echo "Docker-Dienst läuft."

section "Compose-Konfiguration validieren"
compose_cmd config >/dev/null
echo "compose.yml ist gültig."

section "Hinweise"
echo "Der Host ist vorbereitet."
echo "Die Monitoring-Konfiguration ist im Repo enthalten."
echo "Mit ./setup.sh --only start,status --services uptime-kuma kannst du nur Kuma neu starten."
