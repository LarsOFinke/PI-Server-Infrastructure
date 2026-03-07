#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/scripts/common/all.sh"
cd "$ROOT_DIR"
ensure_env_file
export_env_file
[[ $# -eq 1 ]] || { echo "Verwendung: $0 /pfad/zur/datei.sql"; exit 1; }
[[ -f "$1" ]] || { echo "Datei nicht gefunden: $1"; exit 1; }
compose_cmd exec -T postgres psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" < "$1"
echo "Restore abgeschlossen: $1"
