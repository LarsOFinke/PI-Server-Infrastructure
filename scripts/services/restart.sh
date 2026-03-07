#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/scripts/common/all.sh"
cd "$ROOT_DIR"
ensure_env_file
validate_service_names "$@"
if [[ "$#" -gt 0 ]]; then
  echo "Starte Services neu: $*"
  compose_cmd restart "$@"
else
  compose_cmd restart
fi
