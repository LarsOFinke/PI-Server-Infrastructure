#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

section() {
  echo
  echo "==> $1"
}

require_file() {
  local file="$1"
  [[ -f "$file" ]] || { echo "Fehlende Datei: $file"; exit 1; }
}

require_command() {
  local cmd="$1"
  command -v "$cmd" >/dev/null 2>&1 || { echo "Befehl fehlt: $cmd"; exit 1; }
}

section "Betriebssystem prüfen"
require_file /etc/os-release
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
require_file "$ROOT_DIR/compose.yml"
require_file "$ROOT_DIR/.env.example"
require_file "$ROOT_DIR/nginx/nginx.conf"
require_file "$ROOT_DIR/nginx/conf.d/monitoring.conf"
require_file "$ROOT_DIR/scripts/bootstrap-pi.sh"
require_file "$ROOT_DIR/scripts/validate-env.sh"

section "Pflichtbefehle prüfen"
require_command bash
require_command sudo
require_command tee
require_command ss

section "Ports prüfen"
for port in 80 443; do
  if ss -ltn | awk '{print $4}' | grep -Eq "(^|:)${port}$"; then
    echo "Hinweis: Port ${port} ist bereits belegt. Das kann gewollt sein, z.B. durch einen alten Container oder Host-Nginx."
  else
    echo "Port ${port} ist frei."
  fi
done

section "Speicherplatz prüfen"
avail_kb="$(df -Pk "$ROOT_DIR" | awk 'NR==2 {print $4}')"
if [[ -n "$avail_kb" ]] && (( avail_kb < 1048576 )); then
  echo "Wenig freier Speicherplatz verfügbar (< 1 GB)."
else
  echo "Speicherplatz ist ausreichend."
fi

section "Preflight abgeschlossen"
echo "Die Grundvoraussetzungen sind erfüllt oder mit Hinweisen versehen."
