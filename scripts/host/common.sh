#!/usr/bin/env bash

if [[ "${DEBUG:-false}" == "true" ]]; then
  set -x
fi

host_log() {
  echo
  echo "==> $1"
}

host_info() {
  echo "$1"
}

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    echo "Bitte als root ausführen: sudo bash $0"
    exit 1
  fi
}

resolve_host_user() {
  HOST_USERNAME="${SERVER_USER:-${SUDO_USER:-${USER:-serveradmin}}}"
  HOST_USER_HOME="$(getent passwd "$HOST_USERNAME" | cut -d: -f6 || true)"
  export HOST_USERNAME HOST_USER_HOME
}

require_host_user() {
  if [[ -z "${HOST_USER_HOME:-}" ]]; then
    echo "Konnte Home-Verzeichnis für Benutzer '${HOST_USERNAME:-unknown}' nicht ermitteln."
    echo "Bitte SERVER_USER in .env prüfen oder das Script mit sudo als Zielbenutzer starten."
    exit 1
  fi
}

backup_file() {
  local file_path="$1"
  [[ -f "$file_path" ]] || return 0
  cp "$file_path" "${file_path}.bak.$(date +%Y%m%d-%H%M%S)"
}

apt_install() {
  apt-get install -y "$@"
}

set_sshd_option() {
  local key="$1"
  local value="$2"
  local file="/etc/ssh/sshd_config"

  if grep -Eq "^[#[:space:]]*${key}\\b" "$file"; then
    sed -i -E "s|^[#[:space:]]*${key}\\b.*|${key} ${value}|g" "$file"
  else
    echo "${key} ${value}" >> "$file"
  fi
}

append_fstab_entry_if_missing() {
  local entry="$1"
  grep -Fxq "$entry" /etc/fstab || echo "$entry" >> /etc/fstab
}

systemctl_restart_ssh() {
  systemctl restart ssh || systemctl restart sshd
}

ensure_user_directory() {
  local directory_path="$1"
  sudo -u "$HOST_USERNAME" mkdir -p "$directory_path"
}
