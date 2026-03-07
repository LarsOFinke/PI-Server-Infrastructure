#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

[[ -f .env ]] || { echo "Fehler: .env fehlt."; exit 1; }
set -a
source .env
set +a

BACKUP_FILE="${1:-}"
if [[ -z "$BACKUP_FILE" || ! -f "$BACKUP_FILE" ]]; then
  echo "Bitte eine existierende SQL-Datei angeben."
  echo "Beispiel: ./scripts/restore-postgres.sh /srv/backups/postgres/postgres-appdb-20260307-120000.sql"
  exit 1
fi

cat "$BACKUP_FILE" | docker compose --env-file "$ROOT_DIR/.env" exec -T postgres \
  psql -U "$POSTGRES_USER" -d "$POSTGRES_DB"

echo "Postgres-Restore abgeschlossen aus: $BACKUP_FILE"
