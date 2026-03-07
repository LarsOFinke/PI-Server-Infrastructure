#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/common.sh"

cd "$(repo_root)"
ensure_env_file
ensure_data_dirs

if [[ "$#" -gt 0 ]]; then
  echo "Starte/Aktualisiere Services: $*"
  compose_cmd up -d --remove-orphans "$@"
else
  compose_cmd up -d --remove-orphans
fi

echo
echo "Infrastruktur wurde gestartet."
echo "Monitoring: http://<PI-IP>/ oder per vHost wie monitoring.local"
