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
