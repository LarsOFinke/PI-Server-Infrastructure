#!/usr/bin/env bash

ensure_env_file() {
  [[ -f "$ROOT_DIR/.env" ]] || fail ".env fehlt. Bitte zuerst ./scripts/setup/init-env.sh oder ./setup.sh ausführen."
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
