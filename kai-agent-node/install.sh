#!/usr/bin/env bash
set -euo pipefail

# Kai Agent Node Bootstrap Installer v1.0

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

ROOT_DEFAULT="$HOME/kai-agent"
WORKSPACE_DEFAULT="$ROOT_DEFAULT/workspace"
CONFIG_DEFAULT="$HOME/.config/webcodex"

ROOT="$ROOT_DEFAULT"
WORKSPACE="$WORKSPACE_DEFAULT"
CONFIG_DIR="$CONFIG_DEFAULT"

read -r -p "Agent root [$ROOT]: " value || true
ROOT=${value:-$ROOT}

read -r -p "Workspace directory [$WORKSPACE]: " value || true
WORKSPACE=${value:-$WORKSPACE}

read -r -p "WebCodex config directory [$CONFIG_DIR]: " value || true
CONFIG_DIR=${value:-$CONFIG_DIR}

mkdir -p "$ROOT" "$WORKSPACE" "$CONFIG_DIR"

cat > "$ROOT/node.env" <<EOF
KAI_AGENT_ROOT=$ROOT
KAI_AGENT_WORKSPACE=$WORKSPACE
WEBCODEX_CONFIG=$CONFIG_DIR
EOF

cat <<EOF

Kai Agent Node Bootstrap v1.0

Root:      $ROOT
Workspace: $WORKSPACE
Config:    $CONFIG_DIR

Completed:
 ✓ directory initialization
 ✓ node configuration generated

Pending modules:
 - WebCodex installation
 - Runner registration
 - OpenAI Secure MCP Tunnel
 - systemd services

EOF
