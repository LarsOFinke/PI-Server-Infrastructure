#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/scripts/common/all.sh"

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
ensure_repo_files \
  "$ROOT_DIR/compose.yml" \
  "$ROOT_DIR/.env.example" \
  "$ROOT_DIR/.env" \
  "$ROOT_DIR/nginx/nginx.conf" \
  "$ROOT_DIR/nginx/conf.d/monitoring.conf"

if [[ "$SKIP_DATA" != "true" ]]; then
  section "Datenverzeichnisse prüfen"
  ensure_service_data_dirs_exist "${SERVICES[@]}"
fi

section "Docker prüfen"
check_docker_runtime

section "Compose-Konfiguration validieren"
validate_compose_config
echo "compose.yml ist gültig."

section "Hinweise"
echo "Der Host ist vorbereitet."
echo "Die Monitoring-Konfiguration ist im Repo enthalten."
echo "Container lassen sich gezielt über ./scripts/services/start.sh <service> aktualisieren."
