#!/usr/bin/env bash

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

check_supported_os() {
  section "Betriebssystem prüfen"
  require_file /etc/os-release
  # shellcheck disable=SC1091
  . /etc/os-release
  case "${ID:-}" in
    debian|raspbian)
      echo "Unterstütztes System erkannt: ${PRETTY_NAME:-unknown}"
      ;;
    *)
      echo "Nicht getestetes System: ${PRETTY_NAME:-unknown}"
      echo "Empfohlen: Debian oder Raspberry Pi OS"
      ;;
  esac
}

check_required_repo_files() {
  section "Repo-Dateien prüfen"
  ensure_repo_files \
    "$ROOT_DIR/compose.yml" \
    "$ROOT_DIR/.env.example" \
    "$ROOT_DIR/nginx/nginx.conf" \
    "$ROOT_DIR/nginx/conf.d/monitoring.conf" \
    "$ROOT_DIR/scripts/host/bootstrap.sh"
}

check_required_commands() {
  section "Pflichtbefehle prüfen"
  require_command bash
  require_command sudo
  require_command tee
  require_command ss
}

check_http_ports() {
  section "Ports prüfen"
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
  section "Speicherplatz prüfen"
  local target_path="$1"
  local avail_kb
  avail_kb="$(df -Pk "$target_path" | awk 'NR==2 {print $4}')"

  if [[ -n "$avail_kb" ]] && (( avail_kb < 1048576 )); then
    echo "Wenig freier Speicherplatz verfügbar (< 1 GB)."
  else
    echo "Speicherplatz ist ausreichend."
  fi
}

run_preflight_checks() {
  check_supported_os
  check_required_repo_files
  check_required_commands
  check_http_ports
  check_free_space "$ROOT_DIR"

  section "Preflight abgeschlossen"
  echo "Die Grundvoraussetzungen sind erfüllt oder mit Hinweisen versehen."
}

check_docker_runtime() {
  section "Docker prüfen"
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

run_post_checks() {
  local skip_data="$1"
  shift || true
  local services=("$@")

  section "Grundlegende Dateien prüfen"
  ensure_repo_files \
    "$ROOT_DIR/compose.yml" \
    "$ROOT_DIR/.env.example" \
    "$ROOT_DIR/.env" \
    "$ROOT_DIR/nginx/nginx.conf" \
    "$ROOT_DIR/nginx/conf.d/monitoring.conf"

  if [[ "$skip_data" != "true" ]]; then
    section "Datenverzeichnisse prüfen"
    ensure_service_data_dirs_exist "${services[@]}"
  fi

  check_docker_runtime

  section "Compose-Konfiguration validieren"
  validate_compose_config
  echo "compose.yml ist gültig."

  section "Hinweise"
  echo "Der Host ist vorbereitet."
  echo "Die Monitoring-Konfiguration ist im Repo enthalten."
  echo "Container lassen sich gezielt über ./scripts/services/start.sh <service> aktualisieren."
}
