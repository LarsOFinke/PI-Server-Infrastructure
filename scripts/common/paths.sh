#!/usr/bin/env bash

resolve_root_dir() {
  local source_path="$1"
  cd "$(dirname "$source_path")/../.." >/dev/null 2>&1 && pwd
}

repo_root() {
  echo "${ROOT_DIR:?ROOT_DIR ist nicht gesetzt}"
}
