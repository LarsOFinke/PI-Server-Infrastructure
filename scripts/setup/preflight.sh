#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/scripts/common/all.sh"

section "Betriebssystem prüfen"
require_file /etc/os-release
# shellcheck disable=SC1091
. /etc/os-release
case "${ID:-}" in
  debian|raspbian)
    echo "Unterstütztes System erkannt: ${PRETTY_NAME:-unknown}"
    ;;
  *)
    echo "Nicht getestetes System: ${PRETTY_NAME:-unknown}"
    echo "Empfohlen: Debian oder Raspberry Pi OS"
    ;;
esac

section "Repo-Dateien prüfen"
ensure_repo_files \
  "$ROOT_DIR/compose.yml" \
  "$ROOT_DIR/.env.example" \
  "$ROOT_DIR/nginx/nginx.conf" \
  "$ROOT_DIR/nginx/conf.d/monitoring.conf" \
  "$ROOT_DIR/scripts/host/bootstrap.sh" \
  "$ROOT_DIR/scripts/setup/validate-env.sh"

section "Pflichtbefehle prüfen"
require_command bash
require_command sudo
require_command tee
require_command ss

section "Ports prüfen"
check_http_ports

section "Speicherplatz prüfen"
check_free_space "$ROOT_DIR"

section "Preflight abgeschlossen"
echo "Die Grundvoraussetzungen sind erfüllt oder mit Hinweisen versehen."
