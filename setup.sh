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

run_step() {
  local label="$1"
  shift

  log "$label"
  "$@"
}

run_step_requires_docker_session() {
  local label="$1"
  shift

  log "$label"

  if ! docker info >/dev/null 2>&1; then
    echo
    echo "FEHLER: Docker ist in der aktuellen Session noch nicht ohne sudo nutzbar."
    echo "Wahrscheinliche Ursache:"
    echo "  Der Benutzer '${USERNAME}' wurde in diesem Lauf neu zur docker-Gruppe hinzugefügt,"
    echo "  aber die aktuelle Session hat diese Gruppenänderung noch nicht übernommen."
    echo
    echo "Bitte einmal neu anmelden oder den Pi neu starten."
    echo "Danach erneut ausführen:"
    echo "  ./setup.sh"
    echo
    echo "Alternativ für einen Soforttest:"
    echo "  newgrp docker"
    echo "  ./setup.sh"
    echo
    echo "Log: ${LOG_FILE}"
    exit 1
  fi

  "$@"
}

cd "$ROOT_DIR"

log "Server-Setup wird gestartet"
echo "Repo: $ROOT_DIR"
echo "Log:  $LOG_FILE"
echo "Debug: ${DEBUG:-false}"

run_step ".env vorbereiten" \
  bash "$ROOT_DIR/scripts/init-env.sh"

run_step ".env laden" \
  bash -c "
    set -a
    source '$ROOT_DIR/.env'
    set +a
    echo 'Server-Benutzer: ${SERVER_USER:-${SUDO_USER:-${USER:-serveradmin}}}'
  "

set -a
source "$ROOT_DIR/.env"
set +a
USERNAME="${SERVER_USER:-${SUDO_USER:-${USER:-serveradmin}}}"

run_step "Preflight-Checks ausführen" \
  bash "$ROOT_DIR/scripts/preflight-check.sh"

run_step ".env validieren" \
  bash "$ROOT_DIR/scripts/validate-env.sh"

run_step "Host-Bootstrap ausführen" \
  sudo SERVER_USER="$USERNAME" bash "$ROOT_DIR/scripts/bootstrap-pi.sh"

run_step "Datenverzeichnisse erstellen" \
  bash -c "
    mkdir -p \
      '$ROOT_DIR/data/nginx' \
      '$ROOT_DIR/data/postgres' \
      '$ROOT_DIR/data/uptime-kuma'
    chmod -R 750 '$ROOT_DIR/data'
    if id '$USERNAME' >/dev/null 2>&1; then
      chown -R '$USERNAME:$USERNAME' '$ROOT_DIR/data'
    fi
  "

run_step "Compose-Konfiguration validieren" \
  bash "$ROOT_DIR/scripts/validate.sh"

run_step "Post-Setup-Checks ausführen" \
  bash "$ROOT_DIR/scripts/post-setup-check.sh"

run_step_requires_docker_session "Infrastruktur starten" \
  bash "$ROOT_DIR/scripts/start.sh"

run_step_requires_docker_session "Status anzeigen" \
  bash "$ROOT_DIR/scripts/status.sh"

log "Setup abgeschlossen"
echo "Monitoring: http://<PI-IP>/monitoring/"
echo "Troubleshooting: docs/troubleshooting.md"