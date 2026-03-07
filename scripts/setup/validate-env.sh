#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/scripts/common/all.sh"
ensure_env_file
export_env_file
required_file="$(required_env_keys_file)"
[[ -f "$required_file" ]] || fail "Pflichtvariablen-Datei fehlt: $required_file"
while IFS= read -r var_name; do
  [[ -z "$var_name" || "$var_name" =~ ^# ]] && continue
  [[ -n "${!var_name:-}" ]] || fail "Pflichtvariable fehlt oder ist leer: ${var_name}"
done < "$required_file"
echo ".env ist vollständig."
