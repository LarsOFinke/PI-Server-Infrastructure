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

show_runtime_summary() {
  log "Server-Setup wird gestartet"
  echo "Repo: $ROOT_DIR"
  echo "Log:  $LOG_FILE"
  echo "Debug: ${DEBUG:-false}"
  echo "Dev mode: ${DEV_MODE}"
  echo "No start: ${NO_START}"
  echo "Only steps: ${ONLY_STEPS[*]:-(alle)}"
  echo "Skip steps: ${SKIP_STEPS[*]:-(keine)}"
  echo "Target services: ${TARGET_SERVICES[*]:-(alle)}"
}

start_services() {
  if [[ "${#TARGET_SERVICES[@]}" -gt 0 ]]; then
    bash "$ROOT_DIR/scripts/setup/start-infra.sh" "${TARGET_SERVICES[@]}"
  else
    bash "$ROOT_DIR/scripts/setup/start-infra.sh"
  fi
}

show_status() {
  if [[ "${#TARGET_SERVICES[@]}" -gt 0 ]]; then
    bash "$ROOT_DIR/scripts/setup/show-status.sh" "${TARGET_SERVICES[@]}"
  else
    bash "$ROOT_DIR/scripts/setup/show-status.sh"
  fi
}

main() {
  cd "$ROOT_DIR"
  show_runtime_summary

  run_step "init-env" ".env vorbereiten" bash "$ROOT_DIR/scripts/setup/init-env.sh"
  run_step "load-env" ".env laden" bash "$ROOT_DIR/scripts/setup/load-env.sh"

  load_runtime_env

  run_step "preflight" "Preflight-Checks ausführen" bash "$ROOT_DIR/scripts/setup/preflight.sh"
  run_step "validate-env" ".env validieren" bash "$ROOT_DIR/scripts/setup/validate-env.sh"
  run_step "bootstrap" "Host-Bootstrap ausführen" bash "$ROOT_DIR/scripts/setup/bootstrap-host.sh"
  run_step "data" "Datenverzeichnisse erstellen" bash "$ROOT_DIR/scripts/setup/prepare-data-dirs.sh"
  run_step "validate" "Compose-Konfiguration validieren" bash "$ROOT_DIR/scripts/setup/validate-compose.sh"
  run_step "post-check" "Post-Setup-Checks ausführen" bash "$ROOT_DIR/scripts/setup/post-check.sh"
  run_step_requires_docker_session "start" "Infrastruktur starten" start_services
  run_step_requires_docker_session "status" "Status anzeigen" show_status

  log "Setup abgeschlossen"
  echo "Monitoring: http://monitoring.server"
  echo "Troubleshooting: docs/troubleshooting.md"
}

main
