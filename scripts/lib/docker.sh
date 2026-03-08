#!/usr/bin/env bash

compose_cmd() {
  command -v docker >/dev/null 2>&1 || fail "Docker ist nicht installiert oder nicht im PATH. Bitte zuerst das Feature 'host' ausführen oder Docker manuell installieren."
  docker compose --env-file "$ROOT_DIR/.env" "$@"
}

ensure_docker_session() {
  if ! docker info >/dev/null 2>&1; then
    cat <<EOF_MSG

FEHLER: Docker ist in der aktuellen Session noch nicht ohne sudo nutzbar.
Wahrscheinliche Ursache:
  Der Benutzer '${USERNAME:-unknown}' wurde in diesem Lauf neu zur docker-Gruppe hinzugefügt,
  aber die aktuelle Session hat diese Gruppenänderung noch nicht übernommen.

Bitte einmal neu anmelden oder den Pi neu starten.
Danach erneut ausführen:
  ./setup.sh

Alternativ für einen Soforttest:
  newgrp docker
  ./setup.sh

Log: ${LOG_FILE:-keins}
EOF_MSG
    exit 1
  fi
}

validate_compose_config() {
  ensure_env_file
  compose_cmd config >/dev/null
}

compose_start() {
  local services=("$@")
  ensure_env_file
  validate_service_names "${services[@]}"
  ensure_data_dirs "${services[@]}"

  if [[ "${#services[@]}" -gt 0 ]]; then
    echo "Starte/Aktualisiere Services: ${services[*]}"
    compose_cmd up -d --remove-orphans "${services[@]}"
  else
    compose_cmd up -d --remove-orphans
  fi

  echo
  echo "Infrastruktur wurde gestartet."
  echo "Monitoring: http://monitoring.server"
}

compose_status() {
  local services=("$@")
  ensure_env_file
  validate_service_names "${services[@]}"

  if [[ "${#services[@]}" -gt 0 ]]; then
    compose_cmd ps "${services[@]}"
  else
    compose_cmd ps
  fi
}

compose_logs() {
  local services=("$@")
  ensure_env_file
  validate_service_names "${services[@]}"

  if [[ "${#services[@]}" -gt 0 ]]; then
    compose_cmd logs --tail=200 "${services[@]}"
  else
    compose_cmd logs --tail=200
  fi
}

compose_restart() {
  local services=("$@")
  ensure_env_file
  validate_service_names "${services[@]}"

  if [[ "${#services[@]}" -gt 0 ]]; then
    echo "Starte Services neu: ${services[*]}"
    compose_cmd restart "${services[@]}"
  else
    compose_cmd restart
  fi
}

compose_stop() {
  local services=("$@")
  ensure_env_file
  validate_service_names "${services[@]}"

  if [[ "${#services[@]}" -gt 0 ]]; then
    compose_cmd stop "${services[@]}"
  else
    compose_cmd down
  fi
}
