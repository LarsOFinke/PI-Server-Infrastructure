#!/usr/bin/env bash
set -Eeuo pipefail

if [[ "${DEBUG:-false}" == "true" ]]; then
  set -x
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$ROOT_DIR/scripts/lib/all.sh"

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

  [[ "${#resolved[@]}" -gt 0 ]] || fail "Es wurden keine Features ausgewählt."

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

  log ".env vorbereiten"
  init_env_file

  log ".env laden"
  load_runtime_env
  echo "Server-Benutzer: $USERNAME"

  log ".env validieren"
  validate_env_file

  log "Preflight-Checks ausführen"
  run_preflight_checks

  if needs_any_feature host; then
    log "Host-Bootstrap ausführen"
    bash "$ROOT_DIR/scripts/host/bootstrap.sh"
  else
    info "SKIP: Host-Bootstrap wurde nicht ausgewählt."
  fi

  if needs_any_feature nginx postgres monitoring; then
    log "Datenverzeichnisse erstellen"
    prepare_service_data_dirs "${TARGET_SERVICES[@]}"

    log "Compose-Konfiguration validieren"
    validate_compose_config
    echo "Compose-Konfiguration ist gültig."
  else
    info "SKIP: Keine Container-Features ausgewählt."
  fi

  if needs_any_feature backup; then
    log "Backup-Verzeichnisse vorbereiten"
    prepare_backup_dirs
  else
    info "SKIP: Backup-Feature wurde nicht ausgewählt."
  fi

  if needs_any_feature checks; then
    log "Post-Setup-Checks ausführen"
    if needs_any_feature nginx postgres monitoring; then
      run_post_checks false "${TARGET_SERVICES[@]}"
    else
      run_post_checks true
    fi
  else
    info "SKIP: Zusätzliche Checks wurden nicht ausgewählt."
  fi

  if [[ "${NO_START}" == "true" ]]; then
    info "SKIP: Container-Start wurde mit --no-start deaktiviert."
  elif needs_any_feature nginx postgres monitoring; then
    ensure_docker_session
    log "Infrastruktur starten"
    compose_start "${TARGET_SERVICES[@]}"
    log "Status anzeigen"
    compose_status "${TARGET_SERVICES[@]}"
  else
    info "SKIP: Keine Container-Features zum Starten ausgewählt."
  fi

  log "Setup abgeschlossen"
  echo "Monitoring: http://monitoring.server"
  echo "Troubleshooting: docs/troubleshooting.md"
}

main
