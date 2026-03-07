#!/usr/bin/env bash
set -Eeuo pipefail

if [[ "${DEBUG:-false}" == "true" ]]; then
  set -x
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$ROOT_DIR/logs"
LOG_FILE="$LOG_DIR/setup-$(date +%Y%m%d-%H%M%S).log"
mkdir -p "$LOG_DIR"

DEV_MODE=false
NO_START=false
ONLY_STEPS=()
SKIP_STEPS=()
TARGET_SERVICES=()

AVAILABLE_STEPS=(
  "init-env"
  "load-env"
  "preflight"
  "validate-env"
  "bootstrap"
  "data"
  "validate"
  "post-check"
  "start"
  "status"
)

log() {
  echo
  echo "==> $1"
}

die() {
  echo
  echo "FEHLER: $1"
  echo "Log: ${LOG_FILE}"
  exit 1
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

usage() {
  cat <<EOF_USAGE
Verwendung:
  ./setup.sh [OPTIONEN]

Optionen:
  --dev, -dev
      Interaktiver Modus. Vor jedem Schritt ausführen, skippen oder abbrechen.

  --only step1,step2
      Führt nur die angegebenen Schritte aus.

  --skip step1,step2
      Überspringt die angegebenen Schritte.

  --services svc1,svc2
      Startet oder zeigt nur diese Docker-Services an.

  --no-start
      Führt Setup aus, startet aber keine Container.

  --help, -h
      Zeigt diese Hilfe.

Verfügbare Schritte:
  init-env, load-env, preflight, validate-env, bootstrap,
  data, validate, post-check, start, status

Beispiele:
  ./setup.sh
  ./setup.sh --dev
  ./setup.sh --only validate,start,status
  ./setup.sh --skip bootstrap,preflight
  ./setup.sh --services uptime-kuma
  ./setup.sh --only start,status --services nginx,uptime-kuma
  ./setup.sh --no-start
EOF_USAGE
}

parse_csv_to_array() {
  local input="$1"
  local -n out_array=$2
  IFS=',' read -r -a out_array <<< "$input"
}

contains_element() {
  local needle="$1"
  shift || true
  local item
  for item in "$@"; do
    [[ "$item" == "$needle" ]] && return 0
  done
  return 1
}

validate_step_names() {
  local step
  for step in "$@"; do
    [[ -z "$step" ]] && continue
    if ! contains_element "$step" "${AVAILABLE_STEPS[@]}"; then
      die "Unbekannter Schritt: '$step'"
    fi
  done
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dev|-dev)
        DEV_MODE=true
        shift
        ;;
      --no-start)
        NO_START=true
        shift
        ;;
      --only)
        [[ $# -ge 2 ]] || die "--only benötigt einen Wert"
        parse_csv_to_array "$2" ONLY_STEPS
        shift 2
        ;;
      --skip)
        [[ $# -ge 2 ]] || die "--skip benötigt einen Wert"
        parse_csv_to_array "$2" SKIP_STEPS
        shift 2
        ;;
      --services)
        [[ $# -ge 2 ]] || die "--services benötigt einen Wert"
        parse_csv_to_array "$2" TARGET_SERVICES
        shift 2
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      *)
        die "Unbekanntes Argument: $1"
        ;;
    esac
  done

  validate_step_names "${ONLY_STEPS[@]}"
  validate_step_names "${SKIP_STEPS[@]}"
}

confirm_step() {
  local label="$1"
  local step_name="$2"

  if [[ "$DEV_MODE" == "true" ]]; then
    echo
    echo "DEV MODE: Schritt '${label}' (${step_name}) ausführen?"
    echo "[Enter] = ausführen | s = skip | q = abbrechen"
    read -r choice

    case "$choice" in
      s|S)
        echo "Überspringe: $label"
        return 1
        ;;
      q|Q)
        echo "Setup abgebrochen."
        exit 1
        ;;
      *)
        return 0
        ;;
    esac
  fi

  return 0
}

should_run_step() {
  local step_name="$1"

  if [[ "${#ONLY_STEPS[@]}" -gt 0 ]]; then
    contains_element "$step_name" "${ONLY_STEPS[@]}" || return 1
  fi

  if [[ "${#SKIP_STEPS[@]}" -gt 0 ]]; then
    contains_element "$step_name" "${SKIP_STEPS[@]}" && return 1
  fi

  if [[ "$NO_START" == "true" && "$step_name" == "start" ]]; then
    return 1
  fi

  return 0
}

run_step() {
  local step_name="$1"
  local label="$2"
  shift 2

  if ! should_run_step "$step_name"; then
    echo "SKIP [$step_name]: $label"
    return 0
  fi

  if ! confirm_step "$label" "$step_name"; then
    return 0
  fi

  log "$label"
  "$@"
}

ensure_docker_session() {
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
}

run_step_requires_docker_session() {
  local step_name="$1"
  local label="$2"
  shift 2

  if ! should_run_step "$step_name"; then
    echo "SKIP [$step_name]: $label"
    return 0
  fi

  if ! confirm_step "$label" "$step_name"; then
    return 0
  fi

  log "$label"
  ensure_docker_session
  "$@"
}

prepare_env_and_user() {
  set -a
  # shellcheck disable=SC1091
  source "$ROOT_DIR/.env"
  set +a
  USERNAME="${SERVER_USER:-${SUDO_USER:-${USER:-serveradmin}}}"
  export USERNAME
  echo "Server-Benutzer: $USERNAME"
}

create_data_dirs() {
  mkdir -p \
    "$ROOT_DIR/data/nginx" \
    "$ROOT_DIR/data/postgres" \
    "$ROOT_DIR/data/uptime-kuma" \
    "$ROOT_DIR/logs"

  chmod -R 750 "$ROOT_DIR/data"

  if id "$USERNAME" >/dev/null 2>&1; then
    chown -R "$USERNAME:$USERNAME" "$ROOT_DIR/data"
  fi
}

start_services() {
  if [[ "${#TARGET_SERVICES[@]}" -gt 0 ]]; then
    echo "Starte nur ausgewählte Services: ${TARGET_SERVICES[*]}"
    bash "$ROOT_DIR/scripts/start.sh" "${TARGET_SERVICES[@]}"
  else
    bash "$ROOT_DIR/scripts/start.sh"
  fi
}

show_status() {
  if [[ "${#TARGET_SERVICES[@]}" -gt 0 ]]; then
    bash "$ROOT_DIR/scripts/status.sh" "${TARGET_SERVICES[@]}"
  else
    bash "$ROOT_DIR/scripts/status.sh"
  fi
}

exec > >(tee -a "$LOG_FILE") 2>&1

parse_args "$@"
cd "$ROOT_DIR"

log "Server-Setup wird gestartet"
echo "Repo: $ROOT_DIR"
echo "Log:  $LOG_FILE"
echo "Debug: ${DEBUG:-false}"
echo "Dev mode: ${DEV_MODE}"
echo "No start: ${NO_START}"
echo "Only steps: ${ONLY_STEPS[*]:-(alle)}"
echo "Skip steps: ${SKIP_STEPS[*]:-(keine)}"
echo "Target services: ${TARGET_SERVICES[*]:-(alle)}"

run_step "init-env" ".env vorbereiten" \
  bash "$ROOT_DIR/scripts/init-env.sh"

run_step "load-env" ".env laden" \
  prepare_env_and_user

if [[ -z "${USERNAME:-}" ]]; then
  prepare_env_and_user
fi

run_step "preflight" "Preflight-Checks ausführen" \
  bash "$ROOT_DIR/scripts/preflight-check.sh"

run_step "validate-env" ".env validieren" \
  bash "$ROOT_DIR/scripts/validate-env.sh"

run_step "bootstrap" "Host-Bootstrap ausführen" \
  sudo SERVER_USER="$USERNAME" bash "$ROOT_DIR/scripts/bootstrap-pi.sh"

run_step "data" "Datenverzeichnisse erstellen" \
  create_data_dirs

run_step "validate" "Compose-Konfiguration validieren" \
  bash "$ROOT_DIR/scripts/validate.sh"

run_step "post-check" "Post-Setup-Checks ausführen" \
  bash "$ROOT_DIR/scripts/post-setup-check.sh"

run_step_requires_docker_session "start" "Infrastruktur starten" \
  start_services

run_step_requires_docker_session "status" "Status anzeigen" \
  show_status

log "Setup abgeschlossen"
echo "Monitoring: http://<PI-IP>/ oder per vHost wie monitoring.local"
echo "Troubleshooting: docs/troubleshooting.md"
