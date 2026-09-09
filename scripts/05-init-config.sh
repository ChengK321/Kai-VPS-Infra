#!/usr/bin/env bash
set -Eeuo pipefail
[[ ${EUID:-$(id -u)} -eq 0 ]] || { echo 'Please run as root/sudo'; exit 1; }
install -d -m 700 /etc/kai-vps
if [[ ! -f /etc/kai-vps/bandwagon.env ]]; then
  cp "$(dirname "$0")/../config/bandwagon.env.example" /etc/kai-vps/bandwagon.env
  chmod 600 /etc/kai-vps/bandwagon.env
fi
echo 'Edit /etc/kai-vps/bandwagon.env before continuing.'
