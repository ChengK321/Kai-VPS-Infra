#!/usr/bin/env bash
set -Eeuo pipefail
[[ ${EUID:-$(id -u)} -eq 0 ]] || { echo 'Please run as root/sudo'; exit 1; }
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get upgrade -y
apt-get install -y sudo openssh-server curl wget ca-certificates gnupg lsb-release unzip jq openssl ufw fail2ban unattended-upgrades nginx certbot python3 dnsutils iproute2
systemctl enable --now ssh 2>/dev/null || systemctl enable --now sshd
echo '[OK] base packages installed'
