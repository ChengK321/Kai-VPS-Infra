#!/usr/bin/env bash
set -euo pipefail

# Kai Agent Node Bootstrap Installer v1.0
# Initial scaffold. Installation logic will be added incrementally.

DEFAULT_WORKSPACE="/opt/kai"
DEFAULT_CONFIG="$HOME/.config/webcodex"

read -r -p "Workspace directory [$DEFAULT_WORKSPACE]: " WORKSPACE
WORKSPACE=${WORKSPACE:-$DEFAULT_WORKSPACE}

read -r -p "WebCodex config directory [$DEFAULT_CONFIG]: " CONFIG_DIR
CONFIG_DIR=${CONFIG_DIR:-$DEFAULT_CONFIG}

cat <<EOF
Kai Agent Node Bootstrap

Workspace: $WORKSPACE
Config:    $CONFIG_DIR

Next steps:
- install WebCodex
- configure Server
- configure Runner
- configure OpenAI Secure MCP Tunnel
- install systemd services
EOF
