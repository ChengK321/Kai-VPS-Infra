#!/usr/bin/env bash
set -euo pipefail

# Kai Agent Node Bootstrap Installer v1.0
# Phase 8: orchestration layer

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

ROOT_DEFAULT="$HOME/kai-agent"
WORKSPACE_DEFAULT="$ROOT_DEFAULT/workspace"
CONFIG_DEFAULT="$HOME/.config/webcodex"

ROOT=${KAI_AGENT_ROOT:-$ROOT_DEFAULT}
WORKSPACE=${KAI_AGENT_WORKSPACE:-$WORKSPACE_DEFAULT}
CONFIG_DIR=${WEBCODEX_CONFIG:-$CONFIG_DEFAULT}

ask_value() {
    local prompt="$1"
    local current="$2"
    read -r -p "$prompt [$current]: " value || true
    echo "${value:-$current}"
}

ROOT=$(ask_value "Agent root" "$ROOT")
WORKSPACE=$(ask_value "Workspace directory" "$WORKSPACE")
CONFIG_DIR=$(ask_value "WebCodex config directory" "$CONFIG_DIR")

export KAI_AGENT_ROOT="$ROOT"
export KAI_AGENT_WORKSPACE="$WORKSPACE"
export WEBCODEX_CONFIG="$CONFIG_DIR"

mkdir -p "$ROOT" "$WORKSPACE" "$CONFIG_DIR"

cat > "$ROOT/node.env" <<EOF
KAI_AGENT_ROOT=$ROOT
KAI_AGENT_WORKSPACE=$WORKSPACE
WEBCODEX_CONFIG=$CONFIG_DIR
EOF

log "Phase 2: system bootstrap"
if [[ -f "$SCRIPT_DIR/lib/system.sh" ]]; then
    source "$SCRIPT_DIR/lib/system.sh"
    install_system_dependencies || true
fi

log "Phase 3: WebCodex installation"
if [[ -f "$SCRIPT_DIR/lib/webcodex.sh" ]]; then
    source "$SCRIPT_DIR/lib/webcodex.sh"
    install_webcodex || true
fi

log "Phase 4/5: Server and Runner preparation"
if [[ -f "$SCRIPT_DIR/lib/runner.sh" ]]; then
    source "$SCRIPT_DIR/lib/runner.sh"
fi

log "Phase 6: OpenAI Secure MCP Tunnel preparation"
if [[ -f "$SCRIPT_DIR/lib/tunnel.sh" ]]; then
    source "$SCRIPT_DIR/lib/tunnel.sh"
fi

log "Phase 7: systemd service installation"
if [[ -f "$SCRIPT_DIR/lib/systemd.sh" ]]; then
    source "$SCRIPT_DIR/lib/systemd.sh"
fi

cat <<EOF

Kai Agent Node Bootstrap v1.0 completed.

Root:
  $ROOT

Workspace:
  $WORKSPACE

Config:
  $CONFIG_DIR

Next manual step:
  Complete WebCodex pairing/login if required.

Health check:
  ./health-check.sh

EOF
