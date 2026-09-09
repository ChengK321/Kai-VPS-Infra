#!/usr/bin/env bash
set -Eeuo pipefail
[[ ${EUID:-$(id -u)} -eq 0 ]] || { echo 'Please run as root/sudo'; exit 1; }
source /etc/kai-vps/bandwagon.env
: "${XRAY_VERSION:=v26.6.27}"
: "${REALITY_SNI:=www.cloudflare.com}"
STATE_DIR=/etc/kai-vps
SECRETS="$STATE_DIR/secrets.env"
install -d -m 700 "$STATE_DIR"
curl -fsSL --retry 3 https://github.com/XTLS/Xray-install/raw/main/install-release.sh -o /tmp/xray-install-release.sh
bash /tmp/xray-install-release.sh install --version "$XRAY_VERSION" --force
XRAY=/usr/local/bin/xray
[[ -x "$XRAY" ]] || { echo 'Xray install failed'; exit 1; }
[[ -f "$SECRETS" ]] && source "$SECRETS" || true
VLESS_UUID="${VLESS_UUID:-$($XRAY uuid)}"
if [[ -z "${REALITY_PRIVATE_KEY:-}" || -z "${REALITY_PUBLIC_KEY:-}" ]]; then
  key_output="$($XRAY x25519)"
  REALITY_PRIVATE_KEY="$(printf '%s\n' "$key_output" | grep -Ei '^Private ?key:' | head -n1 | sed -E 's/^[^:]+:[[:space:]]*//')"
  REALITY_PUBLIC_KEY="$(printf '%s\n' "$key_output" | grep -Ei '^(Public ?key|Password)' | head -n1 | sed -E 's/^[^:]+:[[:space:]]*//')"
fi
REALITY_SHORT_ID="${REALITY_SHORT_ID:-$(openssl rand -hex 8)}"
cat > "$SECRETS" <<EOF
VLESS_UUID=${VLESS_UUID}
REALITY_PRIVATE_KEY=${REALITY_PRIVATE_KEY}
REALITY_PUBLIC_KEY=${REALITY_PUBLIC_KEY}
REALITY_SHORT_ID=${REALITY_SHORT_ID}
EOF
chmod 600 "$SECRETS"
install -d -m 755 /usr/local/etc/xray
jq -n --arg uuid "$VLESS_UUID" --arg sni "$REALITY_SNI" --arg privateKey "$REALITY_PRIVATE_KEY" --arg shortId "$REALITY_SHORT_ID" '{log:{loglevel:"warning"},inbounds:[{listen:"0.0.0.0",port:443,protocol:"vless",settings:{clients:[{id:$uuid,flow:"xtls-rprx-vision"}],decryption:"none"},streamSettings:{network:"tcp",security:"reality",realitySettings:{show:false,dest:($sni+":443"),xver:0,serverNames:[$sni],privateKey:$privateKey,shortIds:[$shortId]}}}],outbounds:[{protocol:"freedom",tag:"direct"}]}' > /usr/local/etc/xray/config.json
$XRAY run -test -config /usr/local/etc/xray/config.json
systemctl enable xray >/dev/null 2>&1 || true
systemctl restart xray
systemctl is-active --quiet xray
echo '[OK] Xray REALITY listening on 443/tcp'
