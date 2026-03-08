#!/usr/bin/env bash

AVAILABLE_FEATURES=(
  host
  nginx
  postgres
  monitoring
  backup
  checks
)

DEFAULT_FEATURES=(
  host
  nginx
  postgres
  monitoring
  checks
)

AVAILABLE_SERVICES=(
  nginx
  postgres
  uptime-kuma
)

feature_description() {
  case "$1" in
    host) echo "Host vorbereiten (Pakete, SSH, UFW, Docker, Verzeichnisse)" ;;
    nginx) echo "Nginx-Container bereitstellen und starten" ;;
    postgres) echo "Postgres-Container bereitstellen und starten" ;;
    monitoring) echo "Uptime Kuma bereitstellen und starten" ;;
    backup) echo "Backup-Verzeichnisse und Backup-Skripte vorbereiten" ;;
    checks) echo "Validierungen und Post-Setup-Checks ausführen" ;;
    *) echo "Unbekanntes Feature" ;;
  esac
}

validate_feature_names() {
  local feature
  for feature in "$@"; do
    [[ -z "$feature" ]] && continue
    contains_element "$feature" "${AVAILABLE_FEATURES[@]}" || fail "Unbekanntes Feature: '$feature'"
  done
}

validate_service_names() {
  local service
  for service in "$@"; do
    [[ -z "$service" ]] && continue
    contains_element "$service" "${AVAILABLE_SERVICES[@]}" || fail "Unbekannter Service: '$service'"
  done
}

expand_profile_features() {
  case "$1" in
    core|minimal)
      printf '%s\n' "${DEFAULT_FEATURES[@]}"
      ;;
    full)
      printf '%s\n' "${DEFAULT_FEATURES[@]}" backup
      ;;
    host-only)
      printf '%s\n' host checks
      ;;
    services)
      printf '%s\n' nginx postgres monitoring checks
      ;;
    monitoring-only)
      printf '%s\n' monitoring checks
      ;;
    *)
      fail "Unbekanntes Profil: '$1'"
      ;;
  esac
}

normalize_selected_features() {
  local selected=()
  local feature
  for feature in "$@"; do
    [[ -z "$feature" ]] && continue
    if ! contains_element "$feature" "${selected[@]}"; then
      selected+=("$feature")
    fi
  done
  printf '%s\n' "${selected[@]}"
}

prompt_yes_no() {
  local prompt="$1"
  local default_value="$2"
  local answer=""
  local hint="[y/N]"

  [[ "$default_value" == "true" ]] && hint="[Y/n]"

  while true; do
    read -r -p "$prompt $hint " answer || true
    answer="${answer:-}"

    if [[ -z "$answer" ]]; then
      [[ "$default_value" == "true" ]] && return 0 || return 1
    fi

    case "$answer" in
      y|Y|yes|YES) return 0 ;;
      n|N|no|NO) return 1 ;;
      *) echo "Bitte y oder n eingeben." ;;
    esac
  done
}

interactive_feature_selection() {
  local selected=()
  local feature default=false

  echo >&2
  echo "Feature-Auswahl" >&2
  echo "Bitte wähle aus, welche Bereiche eingerichtet werden sollen." >&2
  echo >&2

  for feature in "${AVAILABLE_FEATURES[@]}"; do
    default=false
    contains_element "$feature" "${DEFAULT_FEATURES[@]}" && default=true

    if prompt_yes_no "- ${feature}: $(feature_description "$feature")" "$default"; then
      selected+=("$feature")
    fi
  done

  [[ "${#selected[@]}" -gt 0 ]] || fail "Es wurde kein Feature ausgewählt."
  printf '%s\n' "${selected[@]}"
}

selected_features_to_services() {
  local services=()
  local feature
  for feature in "$@"; do
    case "$feature" in
      nginx) services+=(nginx) ;;
      postgres) services+=(postgres) ;;
      monitoring) services+=(uptime-kuma) ;;
    esac
  done
  normalize_selected_features "${services[@]}"
}

has_feature() {
  local needle="$1"
  shift || true
  contains_element "$needle" "$@"
}
