#!/usr/bin/env bash

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
  sed -i '/^$/d' /etc/apt/sources.list.d/docker.list
}

install_and_enable_docker() {
  apt-get update
  apt_install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  usermod -aG docker "$HOST_USERNAME"
  systemctl enable docker
  systemctl enable containerd
  systemctl start docker
}
