#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/scripts/common/all.sh"

load_runtime_env
ensure_data_dirs "$@"
apply_data_permissions

if [[ "$#" -gt 0 ]]; then
  echo "Datenverzeichnisse wurden vorbereitet für: $*"
else
  echo "Alle Datenverzeichnisse sind vorbereitet."
fi
