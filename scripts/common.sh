#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

repo_root() {
  echo "$ROOT_DIR"
}

ensure_env_file() {
  if [[ ! -f "$ROOT_DIR/.env" ]]; then
    echo "Fehler: .env fehlt. Bitte zuerst ./scripts/init-env.sh ausführen."
    exit 1
  fi
}

load_env() {
  ensure_env_file
  set -a
  # shellcheck disable=SC1091
  source "$ROOT_DIR/.env"
  set +a
}

compose_cmd() {
  docker compose --env-file "$ROOT_DIR/.env" "$@"
}

ensure_data_dirs() {
  mkdir -p \
    "$ROOT_DIR/data/nginx" \
    "$ROOT_DIR/data/postgres" \
    "$ROOT_DIR/data/uptime-kuma" \
    "$ROOT_DIR/logs"
}
