#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/scripts/common/all.sh"

cd "$ROOT_DIR"
load_runtime_env

[[ $# -eq 1 ]] || fail "Verwendung: $0 /pfad/zur/datei.sql"
[[ -f "$1" ]] || fail "Datei nicht gefunden: $1"

compose_cmd exec -T postgres psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" < "$1"
echo "Restore abgeschlossen: $1"
