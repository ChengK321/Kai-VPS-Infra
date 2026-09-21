#!/usr/bin/env bash
set -euo pipefail

install_base_packages() {
  sudo apt-get update
  sudo apt-get install -y curl git jq ca-certificates unzip openssl
}

install_nodejs() {
  if command -v node >/dev/null 2>&1; then
    return
  fi
  curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
  sudo apt-get install -y nodejs
}

configure_npm_prefix() {
  mkdir -p "$HOME/.npm-global"
  npm config set prefix "$HOME/.npm-global"
}
