#!/usr/bin/env bash
set -Eeuo pipefail

HOST_ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HOST_ROOT_DIR/common.sh"
source "$HOST_ROOT_DIR/config.sh"
source "$HOST_ROOT_DIR/lib/system.sh"
source "$HOST_ROOT_DIR/lib/filesystem.sh"
source "$HOST_ROOT_DIR/lib/security.sh"
source "$HOST_ROOT_DIR/lib/docker.sh"
source "$HOST_ROOT_DIR/lib/summary.sh"

main() {
  require_root
  resolve_host_user
  require_host_user

  host_log "System aktualisieren"
  update_system_packages

  host_log "Basis-Pakete installieren"
  install_base_packages

  if [[ "$HOST_INSTALL_MONITORING_TOOLS" == "true" ]]; then
    host_log "Monitoring-/Debug-Tools installieren"
    install_monitoring_tools
  fi

  if [[ "$HOST_INSTALL_TMPFS" == "true" ]]; then
    host_log "tmpfs für /tmp und /var/tmp konfigurieren"
    configure_tmpfs_mounts
  fi

  if [[ "$HOST_DISABLE_ROOT_SSH" == "true" ]]; then
    host_log "SSH härten"
    harden_ssh
  fi

  if [[ "$HOST_CONFIGURE_UFW" == "true" ]]; then
    host_log "Firewall konfigurieren"
    configure_firewall
  fi

  if [[ "$HOST_CREATE_DIRS" == "true" ]]; then
    host_log "Standard-Verzeichnisse anlegen"
    create_standard_directories
  fi

  if [[ "$HOST_CREATE_HUSHLOGIN" == "true" ]]; then
    host_log "Login-Banner deaktivieren"
    create_hushlogin_file
  fi

  if [[ "$HOST_INSTALL_DOCKER" == "true" ]]; then
    host_log "Docker Repository einrichten"
    install_docker_repo

    host_log "Docker installieren"
    install_and_enable_docker
  fi

  host_log "Bootstrap abgeschlossen"
  print_bootstrap_summary
}

main "$@"
