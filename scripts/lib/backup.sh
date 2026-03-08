#!/usr/bin/env bash

backup_data_archive() {
  load_runtime_env
  ensure_backup_dirs

  local outfile="/srv/backups/data/data-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
  tar -czf "$outfile" -C "$ROOT_DIR" data
  echo "Daten-Backup erstellt: $outfile"
}

backup_postgres_dump() {
  cd "$ROOT_DIR"
  load_runtime_env
  ensure_backup_dirs

  local outfile="/srv/backups/postgres/postgres-$(date +%Y%m%d-%H%M%S).sql"
  compose_cmd exec -T postgres pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" > "$outfile"
  echo "Backup erstellt: $outfile"
}

restore_postgres_dump() {
  cd "$ROOT_DIR"
  load_runtime_env

  [[ $# -eq 1 ]] || fail "Verwendung: $0 /pfad/zur/datei.sql"
  [[ -f "$1" ]] || fail "Datei nicht gefunden: $1"

  compose_cmd exec -T postgres psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" < "$1"
  echo "Restore abgeschlossen: $1"
}
