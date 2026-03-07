#!/usr/bin/env bash
set -Eeuo pipefail

if [[ "${DEBUG:-false}" == "true" ]]; then
  set -x
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$ROOT_DIR/logs"
LOG_FILE="$LOG_DIR/setup-$(date +%Y%m%d-%H%M%S).log"
mkdir -p "$LOG_DIR"

# shellcheck source=/dev/null
source "$ROOT_DIR/scripts/common/log.sh"
# shellcheck source=/dev/null
source "$ROOT_DIR/scripts/common/error.sh"
# shellcheck source=/dev/null
source "$ROOT_DIR/scripts/common/env.sh"
# shellcheck source=/dev/null
source "$ROOT_DIR/scripts/common/docker.sh"

NON_INTERACTIVE=false
NO_START=false
PROFILE=""
SELECTED_FEATURES=()

VALID_FEATURES=(
  host
  nginx
  postgres
  monitoring
  backup
  checks
)

show_help() {
  cat <<'EOF'
Verwendung:
  ./setup.sh
  ./setup.sh --features host,nginx,postgres
  ./setup.sh --profile minimal --non-interactive
  ./setup.sh --profile full --no-start

Optionen:
  --features <csv>       Kommagetrennte Feature-Liste
  --profile <name>       Vordefiniertes Profil (minimal|full|monitoring)
  --non-interactive      Keine Rückfragen, Auswahl nur über Flags/Profil
  --no-start             Setup ausführen, Container aber nicht starten
  --help, -h             Diese Hilfe anzeigen

Verfügbare Features:
  host, nginx, postgres, monitoring, backup, checks
EOF
}

parse_csv_into_array() {
  local input="$1"
  local -n out_ref="$2"
  out_ref=()

  [[ -n "$input" ]] || return 0

  local raw_parts=()
  IFS=',' read -r -a raw_parts <<< "$input"

  local item trimmed
  for item in "${raw_parts[@]}"; do
    trimmed="$(echo "$item" | xargs)"
    [[ -n "$trimmed" ]] && out_ref+=("$trimmed")
  done
}

contains_feature() {
  local needle="$1"
  shift || true
  local item
  for item in "$@"; do
    [[ "$item" == "$needle" ]] && return 0
  done
  return 1
}

validate_features() {
  local feature
  for feature in "${SELECTED_FEATURES[@]}"; do
    if ! contains_feature "$feature" "${VALID_FEATURES[@]}"; then
      die "Unbekanntes Feature: '$feature'"
    fi
  done
}

dedupe_selected_features() {
  local unique=()
  local feature
  for feature in "${SELECTED_FEATURES[@]}"; do
    if ! contains_feature "$feature" "${unique[@]}"; then
      unique+=("$feature")
    fi
  done
  SELECTED_FEATURES=("${unique[@]}")
}

get_feature_description() {
  case "$1" in
    host) echo "Host vorbereiten (Pakete, SSH, UFW, Docker, Verzeichnisse)" ;;
    nginx) echo "Nginx-Container bereitstellen und starten" ;;
    postgres) echo "Postgres-Container bereitstellen und starten" ;;
    monitoring) echo "Uptime Kuma bereitstellen und starten" ;;
    backup) echo "Backup-Verzeichnisse und Backup-Skripte vorbereiten" ;;
    checks) echo "Validierungen und Post-Setup-Checks ausführen" ;;
    *) return 1 ;;
  esac
}

apply_profile() {
  case "$1" in
    minimal)
      SELECTED_FEATURES=(host nginx postgres monitoring checks)
      ;;
    full)
      SELECTED_FEATURES=(host nginx postgres monitoring backup checks)
      ;;
    monitoring)
      SELECTED_FEATURES=(nginx monitoring checks)
      ;;
    *)
      die "Unbekanntes Profil: '$1'"
      ;;
  esac
}

prompt_yes_no_default_yes() {
  local prompt="$1"
  local answer
  read -r -p "$prompt [Y/n] " answer
  answer="${answer:-Y}"
  [[ "$answer" =~ ^[Yy]$ ]]
}

prompt_yes_no_default_no() {
  local prompt="$1"
  local answer
  read -r -p "$prompt [y/N] " answer
  answer="${answer:-N}"
  [[ "$answer" =~ ^[Yy]$ ]]
}

prompt_feature_selection() {
  SELECTED_FEATURES=()

  local feature description enabled=false
  for feature in "${VALID_FEATURES[@]}"; do
    description="$(get_feature_description "$feature")"

    case "$feature" in
      backup)
        if prompt_yes_no_default_no "- ${feature}: ${description}"; then
          enabled=true
        else
          enabled=false
        fi
        ;;
      *)
        if prompt_yes_no_default_yes "- ${feature}: ${description}"; then
          enabled=true
        else
          enabled=false
        fi
        ;;
    esac

    if [[ "$enabled" == "true" ]]; then
      SELECTED_FEATURES+=("$feature")
    fi
  done
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --features)
        [[ $# -ge 2 ]] || die "--features benötigt einen Wert"
        parse_csv_into_array "$2" SELECTED_FEATURES
        shift 2
        ;;
      --profile)
        [[ $# -ge 2 ]] || die "--profile benötigt einen Wert"
        PROFILE="$2"
        shift 2
        ;;
      --non-interactive)
        NON_INTERACTIVE=true
        shift
        ;;
      --no-start)
        NO_START=true
        shift
        ;;
      --help|-h)
        show_help
        exit 0
        ;;
      *)
        die "Unbekanntes Argument: $1"
        ;;
    esac
  done
}

feature_selected() {
  local feature="$1"
  contains_feature "$feature" "${SELECTED_FEATURES[@]}"
}

run_shell_script() {
  local label="$1"
  local script_path="$2"
  shift 2

  log "$label"
  bash "$script_path" "$@"
}

start_selected_services() {
  local services=()

  feature_selected nginx && services+=(nginx)
  feature_selected postgres && services+=(postgres)
  feature_selected monitoring && services+=(uptime-kuma)

  if [[ "${#services[@]}" -eq 0 ]]; then
    echo "Keine Container-Services zum Starten ausgewählt."
    return 0
  fi

  log "Ausgewählte Services starten"
  echo "Services: ${services[*]}"
  docker compose up -d "${services[@]}"
}

show_selected_status() {
  local services=()

  feature_selected nginx && services+=(nginx)
  feature_selected postgres && services+=(postgres)
  feature_selected monitoring && services+=(uptime-kuma)

  log "Status anzeigen"

  if [[ "${#services[@]}" -eq 0 ]]; then
    docker compose ps
  else
    docker compose ps "${services[@]}"
  fi
}

prepare_data_dirs_for_selected_features() {
  local dirs=()

  feature_selected nginx && dirs+=("$ROOT_DIR/data/nginx")
  feature_selected postgres && dirs+=("$ROOT_DIR/data/postgres")
  feature_selected monitoring && dirs+=("$ROOT_DIR/data/uptime-kuma")
  feature_selected backup && dirs+=("$ROOT_DIR/data/backups")

  if [[ "${#dirs[@]}" -eq 0 ]]; then
    echo "Keine Datenverzeichnisse anzulegen."
    return 0
  fi

  mkdir -p "${dirs[@]}"
  chmod -R 750 "$ROOT_DIR/data"

  if id "$USERNAME" >/dev/null 2>&1; then
    chown -R "$USERNAME:$USERNAME" "$ROOT_DIR/data"
  fi
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

main() {
  parse_args "$@"

  log "Server-Setup wird gestartet"
  echo "Repo: $ROOT_DIR"
  echo "Log:  $LOG_FILE"
  echo "Debug: ${DEBUG:-false}"

  if [[ -n "$PROFILE" ]]; then
    apply_profile "$PROFILE"
  elif [[ "${#SELECTED_FEATURES[@]}" -eq 0 ]]; then
    if [[ "$NON_INTERACTIVE" == "true" ]]; then
      die "Im non-interactive Modus muss --features oder --profile gesetzt sein"
    fi
    prompt_feature_selection
  fi

  dedupe_selected_features
  validate_features

  echo
  echo "Ausgewählte Features: ${SELECTED_FEATURES[*]}"

  run_shell_script ".env vorbereiten" "$ROOT_DIR/scripts/setup/init-env.sh"

  log ".env laden"
  # shellcheck disable=SC1091
  source "$ROOT_DIR/.env"
  USERNAME="${SERVER_USER:-${SUDO_USER:-${USER:-serveradmin}}}"
  export USERNAME
  echo "Server-Benutzer: $USERNAME"

  run_shell_script ".env validieren" "$ROOT_DIR/scripts/setup/validate-env.sh"

  if feature_selected host; then
    log "Host-Bootstrap ausführen"
    sudo SERVER_USER="$USERNAME" bash "$ROOT_DIR/scripts/setup/bootstrap-host.sh"
  else
    echo "Host-Bootstrap übersprungen."
  fi

  if feature_selected checks; then
    run_shell_script "Preflight-Checks ausführen" "$ROOT_DIR/scripts/setup/preflight.sh"
  else
    echo "Preflight-Checks übersprungen."
  fi

  if feature_selected nginx || feature_selected postgres || feature_selected monitoring || feature_selected backup; then
    log "Datenverzeichnisse erstellen"
    prepare_data_dirs_for_selected_features
  else
    echo "Datenverzeichnisse übersprungen."
  fi

  if feature_selected nginx || feature_selected postgres || feature_selected monitoring; then
    run_shell_script "Compose-Konfiguration validieren" "$ROOT_DIR/scripts/setup/validate-compose.sh"
  else
    echo "Compose-Validierung übersprungen."
  fi

  if feature_selected backup; then
    run_shell_script "Backup-Vorbereitung ausführen" "$ROOT_DIR/scripts/setup/prepare-backup.sh"
  else
    echo "Backup-Vorbereitung übersprungen."
  fi

  if feature_selected checks; then
    run_shell_script "Post-Setup-Checks ausführen" "$ROOT_DIR/scripts/setup/post-check.sh"
  else
    echo "Post-Setup-Checks übersprungen."
  fi

  if [[ "$NO_START" == "true" ]]; then
    echo "Container-Start mit --no-start übersprungen."
  elif feature_selected nginx || feature_selected postgres || feature_selected monitoring; then
    ensure_docker_session "$LOG_FILE" "${USERNAME:-serveradmin}"
    start_selected_services
    show_selected_status
  else
    echo "Keine Container-Services ausgewählt."
  fi

  log "Setup abgeschlossen"
  echo "Monitoring: http://monitoring.server"
  echo "Troubleshooting: docs/troubleshooting.md"
}

main "$@"
