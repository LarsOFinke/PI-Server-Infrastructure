#!/usr/bin/env bash

print_bootstrap_summary() {
  host_info "Bootstrap abgeschlossen"
  host_info "Benutzer: $HOST_USERNAME"
  host_info "Home:     $HOST_USER_HOME"
  host_info "Hinweis:  Nach neuer docker-Gruppenzuweisung bitte neu anmelden oder rebooten."
}
