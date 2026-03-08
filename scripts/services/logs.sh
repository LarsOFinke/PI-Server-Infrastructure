#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/scripts/lib/all.sh"
setup_error_trap
cd "$ROOT_DIR"
load_runtime_env
compose_logs "$@"
