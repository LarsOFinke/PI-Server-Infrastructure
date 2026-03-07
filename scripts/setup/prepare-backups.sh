#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/scripts/common/all.sh"
load_runtime_env
ensure_backup_dirs

echo "Backup-Verzeichnisse sind vorbereitet:"
echo "- /srv/backups/postgres"
echo "- /srv/backups/data"
