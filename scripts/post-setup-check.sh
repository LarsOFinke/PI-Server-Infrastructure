#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

section() {
  echo
  echo "==> $1"
}

warn() {
  echo "WARNUNG: $1"
}

section "Grundlegende Dateien prüfen"
[[ -f "$ROOT_DIR/compose.yml" ]] || { echo "compose.yml fehlt."; exit 1; }
[[ -f "$ROOT_DIR/.env.example" ]] || { echo ".env.example fehlt."; exit 1; }
[[ -f "$ROOT_DIR/.env" ]] || warn ".env fehlt noch. Vor dem Start bitte ./scripts/init-env.sh ausführen."

section "Docker prüfen"
if ! command -v docker >/dev/null 2>&1; then
  echo "Docker ist nicht installiert oder nicht im PATH."
  exit 1
fi

docker --version

actionable_group_hint="Falls 'permission denied' erscheint: neu anmelden oder kurzzeitig mit sudo arbeiten."

section "Docker Compose prüfen"
docker compose version || { echo "Docker Compose Plugin fehlt. ${actionable_group_hint}"; exit 1; }

section "Docker-Dienst prüfen"
if ! systemctl is-active --quiet docker; then
  echo "Docker-Dienst läuft nicht."
  exit 1
fi
echo "Docker-Dienst läuft."

section "Compose-Konfiguration validieren"
docker compose -f "$ROOT_DIR/compose.yml" --env-file "$ROOT_DIR/.env" config >/dev/null
echo "compose.yml ist gültig."

section "Hinweise"
echo "Der Host ist vorbereitet."
echo "Als Nächstes: ./scripts/start.sh"
