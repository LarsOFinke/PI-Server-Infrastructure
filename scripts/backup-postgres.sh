#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

[[ -f .env ]] || { echo "Fehler: .env fehlt."; exit 1; }
set -a
source .env
set +a

BACKUP_DIR="/srv/backups/postgres"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_FILE="$BACKUP_DIR/postgres-${POSTGRES_DB}-${TIMESTAMP}.sql"

sudo mkdir -p "$BACKUP_DIR"
sudo chown "${SERVER_USER}:${SERVER_USER}" "$BACKUP_DIR" 2>/dev/null || true

docker compose --env-file "$ROOT_DIR/.env" exec -T postgres \
  pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" > "$BACKUP_FILE"

echo "Postgres-Backup erstellt: $BACKUP_FILE"
