#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/scripts/common/all.sh"
ensure_env_file
compose_cmd config >/dev/null
echo "Compose-Konfiguration ist gültig."
