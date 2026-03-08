#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/scripts/common/all.sh"

load_runtime_env
ensure_backup_dirs

outfile="/srv/backups/data/data-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
tar -czf "$outfile" -C "$ROOT_DIR" data
echo "Daten-Backup erstellt: $outfile"
