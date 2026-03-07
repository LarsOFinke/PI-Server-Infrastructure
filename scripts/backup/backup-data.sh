#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
mkdir -p /srv/backups
outfile="/srv/backups/data-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
tar -czf "$outfile" -C "$ROOT_DIR" data
echo "Daten-Backup erstellt: $outfile"
