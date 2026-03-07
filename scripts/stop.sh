#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/common.sh"

cd "$(repo_root)"
ensure_env_file

if [[ "$#" -gt 0 ]]; then
  compose_cmd stop "$@"
else
  compose_cmd down
fi
