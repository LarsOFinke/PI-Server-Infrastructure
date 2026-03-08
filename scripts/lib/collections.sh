#!/usr/bin/env bash

parse_csv_to_array() {
  local input="$1"
  local -n out_array=$2
  IFS=',' read -r -a out_array <<< "$input"
}

contains_element() {
  local needle="$1"
  shift || true
  local item
  for item in "$@"; do
    [[ "$item" == "$needle" ]] && return 0
  done
  return 1
}
