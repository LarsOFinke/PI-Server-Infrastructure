#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/scripts/common/all.sh"
cd "$ROOT_DIR"
ensure_env_file
if [[ "$#" -gt 0 ]]; then compose_cmd ps "$@"; else compose_cmd ps; fi
