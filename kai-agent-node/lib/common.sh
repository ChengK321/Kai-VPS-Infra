#!/usr/bin/env bash

set -euo pipefail

log() {
  echo "[kai-agent] $*"
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "missing command: $1" >&2
    return 1
  }
}

