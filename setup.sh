#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$ROOT_DIR/logs"
LOG_FILE="$LOG_DIR/setup-$(date +%Y%m%d-%H%M%S).log"
mkdir -p "$LOG_DIR"

log() {
  echo
  echo "==> $1"
}

on_error() {
  local exit_code="$?"
  local line_no="${1:-unknown}"
  echo
  echo "Fehler in setup.sh in Zeile ${line_no} (Exit-Code: ${exit_code})."
  echo "Log: ${LOG_FILE}"
  exit "$exit_code"
}
trap 'on_error $LINENO' ERR

exec > >(tee -a "$LOG_FILE") 2>&1

log "Server-Setup wird gestartet"
echo "Repo: $ROOT_DIR"
echo "Log:  $LOG_FILE"

log "Host-Bootstrap ausführen"
sudo bash "$ROOT_DIR/scripts/bootstrap-pi.sh"

log ".env vorbereiten"
bash "$ROOT_DIR/scripts/init-env.sh"

log "Post-Setup-Checks ausführen"
bash "$ROOT_DIR/scripts/post-setup-check.sh"

log "Hinweise"
echo "1. Falls dein Benutzer gerade erst zur docker-Gruppe hinzugefügt wurde, bitte einmal neu anmelden oder rebooten."
echo "2. Danach kannst du die Infrastruktur mit ./scripts/start.sh starten."
echo "3. Mit ./scripts/status.sh prüfst du den aktuellen Zustand."
