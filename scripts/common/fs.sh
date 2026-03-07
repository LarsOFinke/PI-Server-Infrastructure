#!/usr/bin/env bash

ensure_repo_dirs() {
  mkdir -p "$ROOT_DIR/logs" "$ROOT_DIR/data"
}

ensure_data_dirs() {
  mkdir -p \
    "$ROOT_DIR/data/nginx" \
    "$ROOT_DIR/data/postgres" \
    "$ROOT_DIR/data/uptime-kuma" \
    "$ROOT_DIR/logs"
}

apply_data_permissions() {
  chmod -R 750 "$ROOT_DIR/data"
  if [[ -n "${USERNAME:-}" ]] && id "$USERNAME" >/dev/null 2>&1; then
    chown -R "$USERNAME:$USERNAME" "$ROOT_DIR/data"
  fi
}
