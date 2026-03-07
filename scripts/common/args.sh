#!/usr/bin/env bash

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

usage() {
  cat <<'EOF_USAGE'
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

validate_step_names() {
  local step
  for step in "$@"; do
    [[ -z "$step" ]] && continue
    if ! contains_element "$step" "${AVAILABLE_STEPS[@]}"; then
      fail "Unbekannter Schritt: '$step'"
    fi
  done
}

parse_args() {
  DEV_MODE=false
  NO_START=false
  ONLY_STEPS=()
  SKIP_STEPS=()
  TARGET_SERVICES=()

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
        [[ $# -ge 2 ]] || fail "--only benötigt einen Wert"
        parse_csv_to_array "$2" ONLY_STEPS
        shift 2
        ;;
      --skip)
        [[ $# -ge 2 ]] || fail "--skip benötigt einen Wert"
        parse_csv_to_array "$2" SKIP_STEPS
        shift 2
        ;;
      --services)
        [[ $# -ge 2 ]] || fail "--services benötigt einen Wert"
        parse_csv_to_array "$2" TARGET_SERVICES
        shift 2
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      *)
        fail "Unbekanntes Argument: $1"
        ;;
    esac
  done

  validate_step_names "${ONLY_STEPS[@]}"
  validate_step_names "${SKIP_STEPS[@]}"

  export DEV_MODE NO_START
}
