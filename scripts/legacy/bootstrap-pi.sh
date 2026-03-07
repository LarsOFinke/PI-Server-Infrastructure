#!/usr/bin/env bash
set -Eeuo pipefail

if [[ "${DEBUG:-false}" == "true" ]]; then
  set -x
fi

USERNAME="${SERVER_USER:-${SUDO_USER:-${USER:-serveradmin}}}"
USER_HOME="$(getent passwd "$USERNAME" | cut -d: -f6 || true)"
INSTALL_TMPFS="true"
DISABLE_ROOT_SSH="true"
CONFIGURE_UFW="true"
INSTALL_DOCKER="true"
INSTALL_MONITORING_TOOLS="true"
CREATE_DIRS="true"
CREATE_HUSHLOGIN="true"

log() {
  echo
  echo "==> $1"
}

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    echo "Bitte als root ausführen: sudo bash $0"
    exit 1
  fi
}

require_user() {
  if [[ -z "$USER_HOME" ]]; then
    echo "Konnte Home-Verzeichnis für Benutzer '$USERNAME' nicht ermitteln."
    echo "Bitte SERVER_USER in .env prüfen oder das Script mit sudo als Zielbenutzer starten."
    exit 1
  fi
}

append_fstab_tmpfs_if_missing() {
  local entry1="tmpfs /tmp tmpfs defaults,noatime,nosuid 0 0"
  local entry2="tmpfs /var/tmp tmpfs defaults,noatime,nosuid 0 0"

  grep -Fxq "$entry1" /etc/fstab || echo "$entry1" >> /etc/fstab
  grep -Fxq "$entry2" /etc/fstab || echo "$entry2" >> /etc/fstab
}

set_sshd_option() {
  local key="$1"
  local value="$2"
  local file="/etc/ssh/sshd_config"

  if grep -Eq "^[#[:space:]]*${key}\b" "$file"; then
    sed -i -E "s|^[#[:space:]]*${key}\b.*|${key} ${value}|g" "$file"
  else
    echo "${key} ${value}" >> "$file"
  fi
}

install_docker_repo() {
  install -m 0755 -d /etc/apt/keyrings

  if [[ ! -f /etc/apt/keyrings/docker.asc ]]; then
    curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc
  fi

  local arch
  arch="$(dpkg --print-architecture)"

  local codename
  codename="$(. /etc/os-release && echo "${VERSION_CODENAME}")"

  cat > /etc/apt/sources.list.d/docker.list <<EOL
deb [arch=${arch} signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian ${codename} stable
EOL
}

require_root
require_user

log "System aktualisieren"
apt update
apt upgrade -y

log "Basis-Pakete installieren"
apt install -y \
  ca-certificates \
  curl \
  gnupg \
  lsb-release \
  unzip \
  tar \
  vim \
  nano \
  htop \
  tree \
  git \
  ufw

if [[ "$INSTALL_MONITORING_TOOLS" == "true" ]]; then
  log "Monitoring-/Debug-Tools installieren"
  apt install -y tcpdump
fi

if [[ "$INSTALL_TMPFS" == "true" ]]; then
  log "tmpfs für /tmp und /var/tmp konfigurieren"
  cp /etc/fstab "/etc/fstab.bak.$(date +%Y%m%d-%H%M%S)"
  append_fstab_tmpfs_if_missing
fi

if [[ "$DISABLE_ROOT_SSH" == "true" ]]; then
  log "SSH härten"
  cp /etc/ssh/sshd_config "/etc/ssh/sshd_config.bak.$(date +%Y%m%d-%H%M%S)"
  set_sshd_option "PermitRootLogin" "no"
  systemctl restart ssh || systemctl restart sshd
fi

if [[ "$CONFIGURE_UFW" == "true" ]]; then
  log "Firewall konfigurieren"
  ufw allow 22/tcp
  ufw allow 80/tcp
  ufw allow 443/tcp
  ufw --force enable
  ufw status verbose || true
fi

if [[ "$CREATE_DIRS" == "true" ]]; then
  log "Standard-Verzeichnisse anlegen"
  sudo -u "$USERNAME" mkdir -p "$USER_HOME/bin"
  sudo -u "$USERNAME" mkdir -p "$USER_HOME/repositories"
  mkdir -p /srv/backups
  chown "$USERNAME:$USERNAME" /srv/backups
  chmod 770 /srv/backups
fi

if [[ "$CREATE_HUSHLOGIN" == "true" ]]; then
  log "Login-Banner deaktivieren"
  sudo -u "$USERNAME" touch "$USER_HOME/.hushlogin"
fi

if [[ "$INSTALL_DOCKER" == "true" ]]; then
  log "Docker Repository einrichten"
  install_docker_repo

  log "APT aktualisieren"
  apt update

  log "Docker installieren"
  apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  log "Benutzer zur docker-Gruppe hinzufügen"
  usermod -aG docker "$USERNAME"

  log "Docker-Dienste aktivieren"
  systemctl enable docker
  systemctl enable containerd
  systemctl start docker
fi

log "Bootstrap abgeschlossen"
echo "Benutzer: $USERNAME"
echo "Home:     $USER_HOME"
echo "Hinweis:  Nach neuer docker-Gruppenzuweisung bitte neu anmelden oder rebooten."
