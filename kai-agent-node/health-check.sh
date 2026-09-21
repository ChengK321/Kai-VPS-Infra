#!/usr/bin/env bash
set -euo pipefail

check_service() {
  if systemctl is-active --quiet "$1"; then
    echo "✓ $1 active"
  else
    echo "✗ $1 failed"
  fi
}

echo "Kai Agent Node Health Check"

command -v webcodex >/dev/null && echo "✓ webcodex installed" || echo "✗ webcodex missing"

check_service webcodex || true
check_service webcodex-runner || true
check_service webcodex-tunnel || true
