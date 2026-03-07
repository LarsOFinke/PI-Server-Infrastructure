#!/usr/bin/env bash

harden_ssh() {
  backup_file /etc/ssh/sshd_config
  set_sshd_option "PermitRootLogin" "no"
  systemctl_restart_ssh
}

configure_firewall() {
  ufw allow 22/tcp
  ufw allow 80/tcp
  ufw allow 443/tcp
  ufw --force enable
  ufw status verbose || true
}
