#!/usr/bin/env bash

log() {
  echo
  echo "==> $1"
}

warn() {
  echo
  echo "WARNUNG: $1"
}

info() {
  echo "$1"
}

error() {
  echo
  echo "FEHLER: $1" >&2
}

init_logging() {
  local root_dir="$1"
  LOG_DIR="$root_dir/logs"
  LOG_FILE="$LOG_DIR/setup-$(date +%Y%m%d-%H%M%S).log"
  mkdir -p "$LOG_DIR"
  export LOG_DIR LOG_FILE
  exec > >(tee -a "$LOG_FILE") 2>&1
}
