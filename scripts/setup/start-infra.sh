#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/scripts/common/all.sh"
cd "$ROOT_DIR"
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
echo "Monitoring: http://monitoring.server"
