#!/usr/bin/env bash
set -Eeuo pipefail

if [[ "${DEBUG:-false}" == "true" ]]; then
  set -x
fi

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

cd "$ROOT_DIR"

log "Server-Setup wird gestartet"
echo "Repo: $ROOT_DIR"
echo "Log:  $LOG_FILE"
echo "Debug: ${DEBUG:-false}"

log ".env vorbereiten"
bash "$ROOT_DIR/scripts/init-env.sh"

log ".env laden"
set -a
source "$ROOT_DIR/.env"
set +a
USERNAME="${SERVER_USER:-${SUDO_USER:-${USER:-serveradmin}}}"
echo "Server-Benutzer: $USERNAME"

log "Preflight-Checks ausführen"
bash "$ROOT_DIR/scripts/preflight-check.sh"

log ".env validieren"
bash "$ROOT_DIR/scripts/validate-env.sh"

log "Host-Bootstrap ausführen"
sudo SERVER_USER="$USERNAME" bash "$ROOT_DIR/scripts/bootstrap-pi.sh"

log "Datenverzeichnisse erstellen"
mkdir -p \
  "$ROOT_DIR/data/nginx" \
  "$ROOT_DIR/data/postgres" \
  "$ROOT_DIR/data/uptime-kuma"
chmod -R 750 "$ROOT_DIR/data"
if id "$USERNAME" >/dev/null 2>&1; then
  chown -R "$USERNAME:$USERNAME" "$ROOT_DIR/data"
fi

log "Compose-Konfiguration validieren"
bash "$ROOT_DIR/scripts/validate.sh"

actionable_group_hint="Falls 'permission denied' erscheint: bitte einmal neu anmelden oder rebooten und setup.sh erneut starten."

log "Post-Setup-Checks ausführen"
bash "$ROOT_DIR/scripts/post-setup-check.sh"

log "Infrastruktur starten"
bash "$ROOT_DIR/scripts/start.sh"

log "Status anzeigen"
bash "$ROOT_DIR/scripts/status.sh"

log "Setup abgeschlossen"
echo "Monitoring: http://<PI-IP>/monitoring/"
echo "Hinweis: ${actionable_group_hint}"
echo "Troubleshooting: docs/troubleshooting.md"
