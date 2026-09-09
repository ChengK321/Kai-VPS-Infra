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
printf '%s\n' /etc/kai-vps/bandwagon.env /etc/kai-vps/secrets.env /usr/local/etc/xray/config.json /opt/kai-subscription/mihomo.yaml /opt/kai-subscription/vless-link.txt /opt/kai-subscription/shadowrocket.txt
if [[ -f /etc/kai-vps/secrets.env ]]; then
  source /etc/kai-vps/secrets.env
  RESOLVED_DOMAIN="${SUB_DOMAIN:-}"
  if [[ -z "$RESOLVED_DOMAIN" && -s /etc/kai-vps/sub-domain.resolved ]]; then
    RESOLVED_DOMAIN="$(cat /etc/kai-vps/sub-domain.resolved)"
  fi
  if [[ -n "$RESOLVED_DOMAIN" && -n "${SUB_TOKEN:-}" ]]; then
    printf '\nMihomo subscription: https://%s:%s/sub/%s.yaml\n' "$RESOLVED_DOMAIN" "${SUB_HTTPS_PORT:-8443}" "$SUB_TOKEN"
    printf 'Shadowrocket subscription: https://%s:%s/sr/%s\n' "$RESOLVED_DOMAIN" "${SUB_HTTPS_PORT:-8443}" "$SUB_TOKEN"
  else
    printf '\nHTTPS subscription not provisioned yet.\n'
    printf 'Direct VLESS link: /opt/kai-subscription/vless-link.txt\n'
  fi
fi
