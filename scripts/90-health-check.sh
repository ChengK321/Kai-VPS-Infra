#!/usr/bin/env bash
set -Eeuo pipefail
[[ ${EUID:-$(id -u)} -eq 0 ]] || { echo 'Please run as root/sudo'; exit 1; }
source /etc/kai-vps/bandwagon.env
printf '=== Services ===\n'
for s in ssh xray kai-subscription nginx fail2ban unattended-upgrades; do printf '%-22s ' "$s"; systemctl is-active "$s" 2>/dev/null || true; done
printf '\n=== Listening ports ===\n'
ss -lntp | grep -E ":(${SSH_PORT:-22}|80|443|${SUB_HTTPS_PORT:-8443}|${SUB_PORT:-18080})\\b" || true
printf '\n=== Firewall ===\n'
ufw status verbose || true
printf '\n=== BBR ===\n'
sysctl net.ipv4.tcp_congestion_control 2>/dev/null || true
printf '\n=== Runtime files ===\n'
printf '%s\n' /etc/kai-vps/bandwagon.env /etc/kai-vps/secrets.env /usr/local/etc/xray/config.json /opt/kai-subscription/mihomo.yaml
if [[ -f /etc/kai-vps/secrets.env ]]; then
  source /etc/kai-vps/secrets.env
  if [[ -n "${SUB_DOMAIN:-}" && -n "${SUB_TOKEN:-}" ]]; then
    printf '\nHTTPS subscription: https://%s:%s/sub/%s.yaml\n' "$SUB_DOMAIN" "${SUB_HTTPS_PORT:-8443}" "$SUB_TOKEN"
  fi
fi
