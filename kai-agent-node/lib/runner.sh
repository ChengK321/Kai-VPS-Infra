#!/usr/bin/env bash
set -euo pipefail

register_project() {
  local config="$1"
  local workspace="$2"

  webcodex project register \
    --config "$config" \
    "$workspace"
}
