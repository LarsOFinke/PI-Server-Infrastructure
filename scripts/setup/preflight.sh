#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
section() { echo; echo "==> $1"; }
require_file() { [[ -f "$1" ]] || { echo "Fehlende Datei: $1"; exit 1; }; }
require_command() { command -v "$1" >/dev/null 2>&1 || { echo "Befehl fehlt: $1"; exit 1; }; }
section "Betriebssystem prüfen"
require_file /etc/os-release
. /etc/os-release
case "${ID:-}" in debian|raspbian) echo "Unterstütztes System erkannt: ${PRETTY_NAME:-unknown}" ;; *) echo "Nicht getestetes System: ${PRETTY_NAME:-unknown}"; echo "Empfohlen: Debian oder Raspberry Pi OS" ;; esac
section "Repo-Dateien prüfen"
for f in "$ROOT_DIR/compose.yml" "$ROOT_DIR/.env.example" "$ROOT_DIR/nginx/nginx.conf" "$ROOT_DIR/nginx/conf.d/monitoring.conf" "$ROOT_DIR/scripts/legacy/bootstrap-pi.sh" "$ROOT_DIR/scripts/setup/validate-env.sh"; do require_file "$f"; done
section "Pflichtbefehle prüfen"
for c in bash sudo tee ss; do require_command "$c"; done
section "Ports prüfen"
for port in 80 443; do if ss -ltn | awk '{print $4}' | grep -Eq "(^|:)${port}$"; then echo "Hinweis: Port ${port} ist bereits belegt. Das kann gewollt sein, z.B. durch einen alten Container oder Host-Nginx."; else echo "Port ${port} ist frei."; fi; done
section "Speicherplatz prüfen"
avail_kb="$(df -Pk "$ROOT_DIR" | awk 'NR==2 {print $4}')"
if [[ -n "$avail_kb" ]] && (( avail_kb < 1048576 )); then echo "Wenig freier Speicherplatz verfügbar (< 1 GB)."; else echo "Speicherplatz ist ausreichend."; fi
section "Preflight abgeschlossen"
echo "Die Grundvoraussetzungen sind erfüllt oder mit Hinweisen versehen."
