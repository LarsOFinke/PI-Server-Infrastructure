#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/scripts/common/all.sh"

load_runtime_env
ensure_backup_dirs

cat <<'EOF_MSG'
Backup-Verzeichnisse sind vorbereitet:
- /srv/backups/postgres
- /srv/backups/data
EOF_MSG
