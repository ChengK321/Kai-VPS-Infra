#!/usr/bin/env bash
set -euo pipefail

install_webcodex() {
  if command -v webcodex >/dev/null 2>&1; then
    echo "WebCodex already installed"
    return
  fi

  npm install -g @yyjeqhc/webcodex
}

check_webcodex() {
  webcodex --version
}
