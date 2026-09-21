#!/usr/bin/env bash
set -euo pipefail

install_service() {
  local name="$1"
  local content="$2"

  echo "$content" | sudo tee "/etc/systemd/system/${name}.service" >/dev/null
}

reload_services() {
  sudo systemctl daemon-reload
}

