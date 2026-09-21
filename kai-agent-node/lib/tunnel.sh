#!/usr/bin/env bash
set -euo pipefail

configure_tunnel() {
  local file="$HOME/.config/webcodex/tunnel.env"

  mkdir -p "$(dirname "$file")"

  if [ -f "$file" ]; then
    echo "Existing tunnel.env preserved"
    return
  fi

  read -r -p "CONTROL_PLANE_TUNNEL_ID: " tunnel_id
  read -r -s -p "CONTROL_PLANE_API_KEY: " api_key
  echo

  cat > "$file" <<EOF
CONTROL_PLANE_TUNNEL_ID=$tunnel_id
CONTROL_PLANE_API_KEY=$api_key
EOF

  chmod 600 "$file"
}
