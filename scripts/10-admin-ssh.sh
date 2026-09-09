#!/usr/bin/env bash
set -Eeuo pipefail
[[ ${EUID:-$(id -u)} -eq 0 ]] || { echo 'Please run as root/sudo'; exit 1; }
source /etc/kai-vps/bandwagon.env
: "${ADMIN_USER:=kai}"
: "${SSH_PORT:=22}"
id "$ADMIN_USER" >/dev/null 2>&1 || adduser --disabled-password --gecos '' "$ADMIN_USER"
usermod -aG sudo "$ADMIN_USER"
printf '%s ALL=(ALL) NOPASSWD:ALL\n' "$ADMIN_USER" > "/etc/sudoers.d/90-${ADMIN_USER}"
chmod 440 "/etc/sudoers.d/90-${ADMIN_USER}"
home_dir="$(getent passwd "$ADMIN_USER" | cut -d: -f6)"
install -d -m 700 -o "$ADMIN_USER" -g "$ADMIN_USER" "$home_dir/.ssh"
if [[ -s /root/.ssh/authorized_keys && ! -s "$home_dir/.ssh/authorized_keys" ]]; then
  cp /root/.ssh/authorized_keys "$home_dir/.ssh/authorized_keys"
  chown "$ADMIN_USER:$ADMIN_USER" "$home_dir/.ssh/authorized_keys"
  chmod 600 "$home_dir/.ssh/authorized_keys"
fi
if [[ ! -s "$home_dir/.ssh/authorized_keys" ]]; then
  echo '[WARN] No SSH public key found. Root/password login remains unchanged.'
  exit 0
fi
cat > /etc/ssh/sshd_config.d/99-kai-hardening.conf <<EOF
Port ${SSH_PORT}
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
KbdInteractiveAuthentication no
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding no
AllowUsers ${ADMIN_USER}
EOF
sshd -t
systemctl restart ssh 2>/dev/null || systemctl restart sshd
echo '[OK] SSH hardening applied. Test a new SSH session before closing this one.'
