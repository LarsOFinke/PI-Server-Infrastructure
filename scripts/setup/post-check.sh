#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/scripts/common/all.sh"
section() { echo; echo "==> $1"; }

SKIP_DATA=false
SERVICES=()

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --skip-data)
      SKIP_DATA=true
      shift
      ;;
    *)
      SERVICES+=("$1")
      shift
      ;;
  esac
done

validate_service_names "${SERVICES[@]}"

section "Grundlegende Dateien prüfen"
for f in "$ROOT_DIR/compose.yml" "$ROOT_DIR/.env.example" "$ROOT_DIR/.env" "$ROOT_DIR/nginx/nginx.conf" "$ROOT_DIR/nginx/conf.d/monitoring.conf"; do [[ -f "$f" ]] || fail "Fehlende Datei: $f"; done

if [[ "$SKIP_DATA" != "true" ]]; then
  section "Datenverzeichnisse prüfen"
  if [[ "${#SERVICES[@]}" -gt 0 ]]; then
    for service in "${SERVICES[@]}"; do
      dir="$(service_data_dir "$service")"
      [[ -d "$dir" ]] || fail "Fehlendes Verzeichnis: $dir"
    done
  else
    for d in "$ROOT_DIR/data/nginx" "$ROOT_DIR/data/postgres" "$ROOT_DIR/data/uptime-kuma"; do [[ -d "$d" ]] || fail "Fehlendes Verzeichnis: $d"; done
  fi
fi

section "Docker prüfen"
command -v docker >/dev/null 2>&1 || fail "Docker ist nicht installiert oder nicht im PATH."
docker --version

section "Docker Compose prüfen"
docker compose version || fail "Docker Compose Plugin fehlt oder Benutzerrechte greifen noch nicht."

section "Docker-Dienst prüfen"
systemctl is-active --quiet docker || fail "Docker-Dienst läuft nicht."
echo "Docker-Dienst läuft."

section "Compose-Konfiguration validieren"
compose_cmd config >/dev/null
echo "compose.yml ist gültig."

section "Hinweise"
echo "Der Host ist vorbereitet."
echo "Die Monitoring-Konfiguration ist im Repo enthalten."
echo "Container lassen sich gezielt über ./scripts/services/start.sh <service> aktualisieren."
