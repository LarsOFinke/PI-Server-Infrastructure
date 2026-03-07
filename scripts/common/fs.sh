#!/usr/bin/env bash

ensure_repo_dirs() {
  mkdir -p "$ROOT_DIR/logs" "$ROOT_DIR/data"
}

service_data_dir() {
  case "$1" in
    nginx) echo "$ROOT_DIR/data/nginx" ;;
    postgres) echo "$ROOT_DIR/data/postgres" ;;
    uptime-kuma) echo "$ROOT_DIR/data/uptime-kuma" ;;
    *) fail "Unbekannter Service für Datenverzeichnis: '$1'" ;;
  esac
}

ensure_data_dirs() {
  local services=("$@")

  mkdir -p "$ROOT_DIR/logs" "$ROOT_DIR/data"

  if [[ "${#services[@]}" -eq 0 ]]; then
    services=(nginx postgres uptime-kuma)
  fi

  local service dir
  for service in "${services[@]}"; do
    dir="$(service_data_dir "$service")"
    mkdir -p "$dir"
  done
}

apply_data_permissions() {
  chmod -R 750 "$ROOT_DIR/data"
  if [[ -n "${USERNAME:-}" ]] && id "$USERNAME" >/dev/null 2>&1; then
    chown -R "$USERNAME:$USERNAME" "$ROOT_DIR/data"
  fi
}

ensure_backup_dirs() {
  mkdir -p /srv/backups/postgres /srv/backups/data

  if [[ -n "${USERNAME:-}" ]] && id "$USERNAME" >/dev/null 2>&1; then
    chown -R "$USERNAME:$USERNAME" /srv/backups
  fi

  chmod -R 770 /srv/backups
}
