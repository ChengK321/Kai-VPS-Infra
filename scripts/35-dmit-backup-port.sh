#!/usr/bin/env bash
set -Eeuo pipefail
[[ ${EUID:-$(id -u)} -eq 0 ]] || { echo 'Please run as root/sudo'; exit 1; }
source /etc/kai-vps/bandwagon.env
: "${XRAY_BACKUP_PORT:=24443}"
: "${XRAY_PRIMARY_PORT:=443}"
[[ "$XRAY_BACKUP_PORT" =~ ^[0-9]+$ && "$XRAY_PRIMARY_PORT" =~ ^[0-9]+$ ]] || { echo 'Invalid port'; exit 1; }
(( XRAY_BACKUP_PORT > 0 && XRAY_BACKUP_PORT < 65536 && XRAY_PRIMARY_PORT > 0 && XRAY_PRIMARY_PORT < 65536 && XRAY_BACKUP_PORT != XRAY_PRIMARY_PORT )) || { echo 'Invalid port range'; exit 1; }
[[ -n "${PUBLIC_IP:-}" ]] || { echo 'Set PUBLIC_IP in /etc/kai-vps/bandwagon.env first'; exit 1; }
python3 - "$PUBLIC_IP" <<'PY'
import ipaddress, sys
ipaddress.IPv4Address(sys.argv[1])
PY

rule="-A PREROUTING -d ${PUBLIC_IP}/32 -p tcp --dport ${XRAY_BACKUP_PORT} -m comment --comment KAI_DMIT_BACKUP_${XRAY_BACKUP_PORT} -j REDIRECT --to-ports ${XRAY_PRIMARY_PORT}"
rules=/etc/ufw/before.rules
[[ -f "$rules" ]] || { echo "Missing $rules"; exit 1; }
if grep -q "KAI_DMIT_BACKUP_${XRAY_BACKUP_PORT}" "$rules"; then
  grep -Fxq -- "$rule" "$rules" || { echo 'Existing backup rule differs; review manually'; exit 1; }
else
  # UFW loads this NAT rule before its filter rules. Keep a dated backup.
  cp -p "$rules" "${rules}.bak.$(date +%Y%m%d%H%M%S)"
  RULE="$rule" python3 - "$rules" <<'PY'
import os, pathlib, sys
p = pathlib.Path(sys.argv[1])
s = p.read_text()
if s.startswith('*nat\n'):
    pos = s.find('\nCOMMIT\n')
    if pos < 0:
        raise SystemExit('Unterminated UFW NAT table')
    s = s[:pos] + '\n' + os.environ['RULE'] + s[pos:]
else:
    s = '*nat\n:PREROUTING ACCEPT [0:0]\n:INPUT ACCEPT [0:0]\n:OUTPUT ACCEPT [0:0]\n:POSTROUTING ACCEPT [0:0]\n' + os.environ['RULE'] + '\nCOMMIT\n' + s
p.write_text(s)
PY
fi

# A reload applies the persisted rule and avoids adding another live copy.
ufw reload
count="$(iptables-save -t nat | grep -c "KAI_DMIT_BACKUP_${XRAY_BACKUP_PORT}" || true)"
[[ "$count" == 1 ]] || { echo "[WARN] Expected one live redirect, found $count; inspect PREROUTING before removing anything"; exit 1; }
echo "[OK] TCP ${XRAY_BACKUP_PORT} redirects to Xray ${XRAY_PRIMARY_PORT} for ${PUBLIC_IP}"
