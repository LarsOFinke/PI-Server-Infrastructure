#!/usr/bin/env bash

fail() {
  local message="$1"
  error "$message"
  if [[ -n "${LOG_FILE:-}" ]]; then
    echo "Log: ${LOG_FILE}" >&2
  fi
  exit 1
}

setup_error_trap() {
  trap 'on_error ${LINENO}' ERR
}

on_error() {
  local line_no="${1:-unknown}"
  local exit_code="$?"
  error "Fehler in ${0##*/} in Zeile ${line_no} (Exit-Code: ${exit_code})."
  if [[ -n "${LOG_FILE:-}" ]]; then
    echo "Log: ${LOG_FILE}" >&2
  fi
  exit "$exit_code"
}
