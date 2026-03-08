#!/usr/bin/env bash

section() {
  echo
  echo "==> $1"
}

require_file() {
  local file_path="$1"
  [[ -f "$file_path" ]] || fail "Fehlende Datei: $file_path"
}

require_command() {
  local command_name="$1"
  command -v "$command_name" >/dev/null 2>&1 || fail "Befehl fehlt: $command_name"
}

ensure_repo_files() {
  local files=("$@")
  local file_path
  for file_path in "${files[@]}"; do
    require_file "$file_path"
  done
}

check_http_ports() {
  local port
  for port in 80 443; do
    if ss -ltn | awk '{print $4}' | grep -Eq "(^|:)${port}$"; then
      echo "Hinweis: Port ${port} ist bereits belegt. Das kann gewollt sein, z.B. durch einen alten Container oder Host-Nginx."
    else
      echo "Port ${port} ist frei."
    fi
  done
}

check_free_space() {
  local target_path="$1"
  local avail_kb
  avail_kb="$(df -Pk "$target_path" | awk 'NR==2 {print $4}')"

  if [[ -n "$avail_kb" ]] && (( avail_kb < 1048576 )); then
    echo "Wenig freier Speicherplatz verfügbar (< 1 GB)."
  else
    echo "Speicherplatz ist ausreichend."
  fi
}

validate_compose_config() {
  ensure_env_file
  compose_cmd config >/dev/null
}

check_docker_runtime() {
  require_command docker
  docker --version

  section "Docker Compose prüfen"
  docker compose version || fail "Docker Compose Plugin fehlt oder Benutzerrechte greifen noch nicht."

  section "Docker-Dienst prüfen"
  systemctl is-active --quiet docker || fail "Docker-Dienst läuft nicht."
  echo "Docker-Dienst läuft."
}

ensure_service_data_dirs_exist() {
  local services=("$@")

  if [[ "${#services[@]}" -gt 0 ]]; then
    local service dir
    for service in "${services[@]}"; do
      dir="$(service_data_dir "$service")"
      [[ -d "$dir" ]] || fail "Fehlendes Verzeichnis: $dir"
    done
    return 0
  fi

  local dir
  for dir in \
    "$ROOT_DIR/data/nginx" \
    "$ROOT_DIR/data/postgres" \
    "$ROOT_DIR/data/uptime-kuma"; do
    [[ -d "$dir" ]] || fail "Fehlendes Verzeichnis: $dir"
  done
}
