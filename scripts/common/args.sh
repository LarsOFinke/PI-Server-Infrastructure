#!/usr/bin/env bash

usage() {
  cat <<'EOF_USAGE'
Verwendung:
  ./setup.sh [OPTIONEN]

Optionen:
  --features feature1,feature2
      Richtet nur die angegebenen Features ein.

  --profile NAME
      Verwendet ein vordefiniertes Feature-Profil.
      Verfügbar: core, minimal, full, host-only, services, monitoring-only

  --non-interactive
      Keine Feature-Abfrage. Ohne --features/--profile wird automatisch das Profil 'core' verwendet.

  --no-start
      Bereitet alles vor, startet aber keine Container.

  --help, -h
      Zeigt diese Hilfe.

Features:
  host, nginx, postgres, monitoring, backup, checks

Beispiele:
  ./setup.sh
  ./setup.sh --features host,nginx,monitoring
  ./setup.sh --profile full
  ./setup.sh --features monitoring --no-start
  ./setup.sh --profile services --non-interactive
EOF_USAGE
}

parse_args() {
  NON_INTERACTIVE=false
  NO_START=false
  FEATURE_PROFILE=""
  SELECTED_FEATURES=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --features)
        [[ $# -ge 2 ]] || fail "--features benötigt einen Wert"
        parse_csv_to_array "$2" SELECTED_FEATURES
        shift 2
        ;;
      --profile)
        [[ $# -ge 2 ]] || fail "--profile benötigt einen Wert"
        FEATURE_PROFILE="$2"
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
        usage
        exit 0
        ;;
      *)
        fail "Unbekanntes Argument: $1"
        ;;
    esac
  done

  if [[ -n "$FEATURE_PROFILE" && "${#SELECTED_FEATURES[@]}" -gt 0 ]]; then
    fail "Bitte entweder --features oder --profile verwenden, nicht beides zusammen."
  fi

  validate_feature_names "${SELECTED_FEATURES[@]}"
  export NON_INTERACTIVE NO_START FEATURE_PROFILE
}
