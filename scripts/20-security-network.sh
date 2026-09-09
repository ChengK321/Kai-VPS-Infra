#!/usr/bin/env bash
set -Eeuo pipefail
[[ ${EUID:-$(id -u)} -eq 0 ]] || { echo 'Please run as root/sudo'; exit 1; }
source /etc/kai-vps/bandwagon.env
: "${SSH_PORT:=22}"
: "${SUB_HTTPS_PORT:=8443}"
: "${ENABLE_BBR:=1}"
ufw default deny incoming
ufw default allow outgoing
ufw allow "${SSH_PORT}/tcp" comment 'SSH'
ufw allow 80/tcp comment 'ACME HTTP'
ufw allow 443/tcp comment 'Xray REALITY'
ufw allow "${SUB_HTTPS_PORT}/tcp" comment 'HTTPS Subscription'
ufw --force enable
cat > /etc/fail2ban/jail.d/sshd.local <<EOF
[sshd]
enabled = true
backend = systemd
port = ${SSH_PORT}
maxretry = 5
findtime = 10m
bantime = 1h
EOF
systemctl enable --now fail2ban
cat > /etc/apt/apt.conf.d/20auto-upgrades <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF
systemctl enable --now unattended-upgrades.service 2>/dev/null || true
if [[ "$ENABLE_BBR" == 1 ]] && modprobe tcp_bbr 2>/dev/null; then
  cat > /etc/sysctl.d/99-kai-bbr.conf <<'EOF'
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
EOF
  sysctl --system >/dev/null 2>&1 || true
fi
echo '[OK] firewall, fail2ban, unattended-upgrades and BBR configured'
