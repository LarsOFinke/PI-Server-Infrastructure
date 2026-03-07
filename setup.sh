#!/usr/bin/env bash
set -Eeuo pipefail

if [[ "${DEBUG:-false}" == "true" ]]; then
  set -x
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$ROOT_DIR/scripts/common/all.sh"

setup_error_trap
ensure_repo_dirs
init_logging "$ROOT_DIR"
parse_args "$@"

resolve_selected_features() {
  local resolved=()

  if [[ "${#SELECTED_FEATURES[@]}" -gt 0 ]]; then
    mapfile -t resolved < <(normalize_selected_features "${SELECTED_FEATURES[@]}")
  elif [[ -n "${FEATURE_PROFILE:-}" ]]; then
    mapfile -t resolved < <(expand_profile_features "$FEATURE_PROFILE")
  elif [[ "${NON_INTERACTIVE:-false}" == "true" ]]; then
    resolved=("${DEFAULT_FEATURES[@]}")
  elif [[ ! -t 0 ]]; then
    warn "Keine interaktive Eingabe verfügbar. Es wird automatisch das Profil 'core' verwendet."
    resolved=("${DEFAULT_FEATURES[@]}")
  else
    mapfile -t resolved < <(interactive_feature_selection)
  fi

  mapfile -t resolved < <(normalize_selected_features "${resolved[@]}")
  validate_feature_names "${resolved[@]}"

  if [[ "${#resolved[@]}" -eq 0 ]]; then
    fail "Es wurden keine Features ausgewählt."
  fi

  SELECTED_FEATURES=("${resolved[@]}")
  mapfile -t TARGET_SERVICES < <(selected_features_to_services "${SELECTED_FEATURES[@]}")
}

show_runtime_summary() {
  log "Server-Setup wird gestartet"
  echo "Repo: $ROOT_DIR"
  echo "Log:  $LOG_FILE"
  echo "Debug: ${DEBUG:-false}"
  echo "Non-interactive: ${NON_INTERACTIVE}"
  echo "No start: ${NO_START}"
  echo "Feature profile: ${FEATURE_PROFILE:-custom}"
  echo "Ausgewählte Features: ${SELECTED_FEATURES[*]}"
  echo "Ziel-Services: ${TARGET_SERVICES[*]:-(keine)}"
}

run_task() {
  local label="$1"
  shift
  log "$label"
  "$@"
}

needs_any_feature() {
  local feature
  for feature in "$@"; do
    if has_feature "$feature" "${SELECTED_FEATURES[@]}"; then
      return 0
    fi
  done
  return 1
}

main() {
  cd "$ROOT_DIR"

  resolve_selected_features
  show_runtime_summary

  run_task ".env vorbereiten" bash "$ROOT_DIR/scripts/setup/init-env.sh"
  run_task ".env laden" bash "$ROOT_DIR/scripts/setup/load-env.sh"
  load_runtime_env

  run_task "Preflight-Checks ausführen" bash "$ROOT_DIR/scripts/setup/preflight.sh"
  run_task ".env validieren" bash "$ROOT_DIR/scripts/setup/validate-env.sh"

  if needs_any_feature host; then
    run_task "Host-Bootstrap ausführen" bash "$ROOT_DIR/scripts/setup/bootstrap-host.sh"
  else
    info "SKIP: Host-Bootstrap wurde nicht ausgewählt."
  fi

  if needs_any_feature nginx postgres monitoring; then
    run_task "Datenverzeichnisse erstellen" bash "$ROOT_DIR/scripts/setup/prepare-data-dirs.sh" "${TARGET_SERVICES[@]}"
    run_task "Compose-Konfiguration validieren" bash "$ROOT_DIR/scripts/setup/validate-compose.sh"
  else
    info "SKIP: Keine Container-Features ausgewählt."
  fi

  if needs_any_feature backup; then
    run_task "Backup-Verzeichnisse vorbereiten" bash "$ROOT_DIR/scripts/setup/prepare-backups.sh"
  else
    info "SKIP: Backup-Feature wurde nicht ausgewählt."
  fi

  if needs_any_feature checks; then
    if needs_any_feature nginx postgres monitoring; then
      run_task "Post-Setup-Checks ausführen" bash "$ROOT_DIR/scripts/setup/post-check.sh" "${TARGET_SERVICES[@]}"
    else
      run_task "Post-Setup-Checks ausführen" bash "$ROOT_DIR/scripts/setup/post-check.sh" --skip-data
    fi
  else
    info "SKIP: Zusätzliche Checks wurden nicht ausgewählt."
  fi

  if [[ "${NO_START}" == "true" ]]; then
    info "SKIP: Container-Start wurde mit --no-start deaktiviert."
  elif needs_any_feature nginx postgres monitoring; then
    ensure_docker_session
    run_task "Infrastruktur starten" bash "$ROOT_DIR/scripts/setup/start-infra.sh" "${TARGET_SERVICES[@]}"
    run_task "Status anzeigen" bash "$ROOT_DIR/scripts/setup/show-status.sh" "${TARGET_SERVICES[@]}"
  else
    info "SKIP: Keine Container-Features zum Starten ausgewählt."
  fi

  log "Setup abgeschlossen"
  echo "Monitoring: http://monitoring.server"
  echo "Troubleshooting: docs/troubleshooting.md"
}

main
