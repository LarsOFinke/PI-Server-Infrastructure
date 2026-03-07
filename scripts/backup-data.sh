#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

BACKUP_DIR="/srv/backups/data"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
ARCHIVE_FILE="$BACKUP_DIR/server-data-${TIMESTAMP}.tar.gz"

sudo mkdir -p "$BACKUP_DIR"

tar -czf "$ARCHIVE_FILE" data

echo "Daten-Backup erstellt: $ARCHIVE_FILE"
