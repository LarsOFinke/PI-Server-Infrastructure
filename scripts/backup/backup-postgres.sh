#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/scripts/common/all.sh"
cd "$ROOT_DIR"
ensure_env_file
export_env_file
mkdir -p /srv/backups
outfile="/srv/backups/postgres-$(date +%Y%m%d-%H%M%S).sql"
compose_cmd exec -T postgres pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" > "$outfile"
echo "Backup erstellt: $outfile"
