#!/usr/bin/env bash

ensure_repo_dirs() {
  mkdir -p "$ROOT_DIR/logs" "$ROOT_DIR/data"
}

ensure_env_file() {
  [[ -f "$ROOT_DIR/.env" ]] || fail ".env fehlt. Bitte zuerst ./setup.sh oder ./.env aus .env.example erstellen."
}

export_env_file() {
  ensure_env_file
  set -a
  # shellcheck disable=SC1091
  source "$ROOT_DIR/.env"
  set +a
}

load_runtime_env() {
  export_env_file
  USERNAME="${SERVER_USER:-${SUDO_USER:-${USER:-serveradmin}}}"
  export USERNAME
}

required_env_keys_file() {
  echo "$ROOT_DIR/config/env/required.env.keys"
}

init_env_file() {
  if [[ -f "$ROOT_DIR/.env" ]]; then
    echo ".env existiert bereits. Nichts zu tun."
    return 0
  fi

  cp "$ROOT_DIR/.env.example" "$ROOT_DIR/.env"
  echo ".env wurde aus .env.example erstellt."
  echo "Bitte SERVER_USER und POSTGRES_PASSWORD in .env anpassen."
}

validate_env_file() {
  ensure_env_file
  export_env_file

  local required_file
  required_file="$(required_env_keys_file)"
  [[ -f "$required_file" ]] || fail "Pflichtvariablen-Datei fehlt: $required_file"

  local var_name
  while IFS= read -r var_name; do
    [[ -z "$var_name" || "$var_name" =~ ^# ]] && continue
    [[ -n "${!var_name:-}" ]] || fail "Pflichtvariable fehlt oder ist leer: ${var_name}"
  done < "$required_file"

  echo ".env ist vollständig."
}
