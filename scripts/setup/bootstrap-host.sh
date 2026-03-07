#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/scripts/common/all.sh"
load_runtime_env
sudo SERVER_USER="$USERNAME" DEBUG="${DEBUG:-false}" bash "$ROOT_DIR/scripts/host/bootstrap.sh"
