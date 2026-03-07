#!/usr/bin/env bash
confirm_step() {
  local label="$1"
  local step_name="$2"
  if [[ "${DEV_MODE:-false}" == "true" ]]; then
    echo
    echo "DEV MODE: Schritt '${label}' (${step_name}) ausführen?"
    echo "[Enter] = ausführen | s = skip | q = abbrechen"
    read -r choice
    case "$choice" in
      s|S) echo "Überspringe: $label"; return 1 ;;
      q|Q) echo "Setup abgebrochen."; exit 1 ;;
      *) return 0 ;;
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
  if [[ "${NO_START:-false}" == "true" && "$step_name" == "start" ]]; then
    return 1
  fi
  return 0
}
run_step() {
  local step_name="$1"; local label="$2"; shift 2
  if ! should_run_step "$step_name"; then echo "SKIP [$step_name]: $label"; return 0; fi
  if ! confirm_step "$label" "$step_name"; then return 0; fi
  log "$label"
  "$@"
}
run_step_requires_docker_session() {
  local step_name="$1"; local label="$2"; shift 2
  if ! should_run_step "$step_name"; then echo "SKIP [$step_name]: $label"; return 0; fi
  if ! confirm_step "$label" "$step_name"; then return 0; fi
  log "$label"
  ensure_docker_session
  "$@"
}
