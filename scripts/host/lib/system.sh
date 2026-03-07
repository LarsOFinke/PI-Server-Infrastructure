#!/usr/bin/env bash

update_system_packages() {
  apt-get update
  apt-get upgrade -y
}

install_base_packages() {
  apt_install \
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
}

install_monitoring_tools() {
  apt_install tcpdump
}
