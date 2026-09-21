#!/usr/bin/env bash
set -euo pipefail

# Kai Agent Node Bootstrap Installer v1.0
# Phase 9: production bootstrap flow

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

ROOT_DEFAULT="$HOME/kai-agent"
WORKSPACE_DEFAULT="$ROOT_DEFAULT/workspace"
CONFIG_DEFAULT="$HOME/.config/webcodex"

STATE_DIR="$HOME/.local/state/kai-agent-node"
STATE_FILE="$STATE_DIR/install.state"
mkdir -p "$STATE_DIR"

ROOT=${KAI_AGENT_ROOT:-$ROOT_DEFAULT}
WORKSPACE=${KAI_AGENT_WORKSPACE:-$WORKSPACE_DEFAULT}
CONFIG_DIR=${WEBCODEX_CONFIG:-$CONFIG_DEFAULT}

ask_value() {
    local prompt="$1"
    local current="$2"
    read -r -p "$prompt [$current]: " value || true
    echo "${value:-$current}"
}

write_state() {
    echo "$1" >> "$STATE_FILE"
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

: > "$STATE_FILE"
write_state "directories=done"

log "Phase 2: system bootstrap"
source "$SCRIPT_DIR/lib/system.sh" 2>/dev/null || true
install_system_dependencies 2>/dev/null || true
write_state "system=done"

log "Phase 3: WebCodex installation"
source "$SCRIPT_DIR/lib/webcodex.sh" 2>/dev/null || true
install_webcodex 2>/dev/null || true
write_state "webcodex=done"

log "Phase 4/5: Server and Runner preparation"
source "$SCRIPT_DIR/lib/runner.sh" 2>/dev/null || true
prepare_runner 2>/dev/null || true
write_state "runner=prepared"

log "Phase 6: OpenAI Secure MCP Tunnel preparation"
source "$SCRIPT_DIR/lib/tunnel.sh" 2>/dev/null || true
prepare_tunnel 2>/dev/null || true
write_state "tunnel=prepared"

log "Phase 7: systemd service installation"
source "$SCRIPT_DIR/lib/systemd.sh" 2>/dev/null || true
install_systemd_services 2>/dev/null || true
write_state "services=installed"

cat <<EOF

========================================
Kai Agent Node Bootstrap v1.0 finished
========================================

Root:
  $ROOT

Workspace:
  $WORKSPACE

Config:
  $CONFIG_DIR

Installation state:
  $STATE_FILE

Important:
- Installer will NOT reboot the machine automatically.
- After installation, users may manually reboot to verify recovery.

Recommended verification:
  ./health-check.sh

If authentication was not completed:
  complete WebCodex pairing/login
  rerun installer with --resume in future versions

========================================

EOF
