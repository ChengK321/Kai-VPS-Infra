#!/usr/bin/env bash
set -Eeuo pipefail
[[ ${EUID:-$(id -u)} -eq 0 ]] || { echo 'Please run as root/sudo'; exit 1; }
source /etc/kai-vps/bandwagon.env
source /etc/kai-vps/secrets.env
: "${SUB_PORT:=18080}"
: "${SUB_HTTPS_PORT:=8443}"
: "${AUTO_SSLIP_DOMAIN:=1}"
: "${NODE_NAME:=Kai-Xray-Reality}"
PUBLIC_IP="${PUBLIC_IP:-$(curl -4 -fsS --max-time 8 https://api.ipify.org)}"
if [[ -z "${SUB_DOMAIN:-}" && "$AUTO_SSLIP_DOMAIN" == 1 ]]; then
  SUB_DOMAIN="$(printf '%s' "$PUBLIC_IP" | tr '.' '-').sslip.io"
fi
[[ -n "${SUB_DOMAIN:-}" ]] || { echo 'Set SUB_DOMAIN or enable AUTO_SSLIP_DOMAIN'; exit 1; }
SUB_TOKEN="${SUB_TOKEN:-$(openssl rand -hex 32)}"

# Keep exactly one SUB_TOKEN entry so this script can be rerun safely.
tmp_secrets="$(mktemp)"
grep -v '^SUB_TOKEN=' /etc/kai-vps/secrets.env > "$tmp_secrets" || true
printf 'SUB_TOKEN=%s\n' "$SUB_TOKEN" >> "$tmp_secrets"
install -m 600 "$tmp_secrets" /etc/kai-vps/secrets.env
rm -f "$tmp_secrets"

install -d -m 750 -o root -g www-data /opt/kai-subscription
install -d -m 750 -o root -g www-data /opt/kai-subscription/rules
if [[ ! -s /opt/kai-subscription/rules/microsoft-download.yaml ]]; then
  install -m 640 -o root -g www-data "$(dirname "$0")/../config/microsoft-download.yaml" /opt/kai-subscription/rules/microsoft-download.yaml
fi
install -m 640 -o root -g www-data "$(dirname "$0")/update-microsoft-rules.py" /opt/kai-subscription/update-microsoft-rules.py

cat > /etc/systemd/system/kai-microsoft-rules.service <<'EOF'
[Unit]
Description=Refresh validated Microsoft download routing rules
After=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/bin/python3 /opt/kai-subscription/update-microsoft-rules.py
NoNewPrivileges=yes
ProtectSystem=strict
ReadWritePaths=/opt/kai-subscription/rules
ProtectHome=yes
PrivateTmp=yes
TimeoutStartSec=45
EOF
cat > /etc/systemd/system/kai-microsoft-rules.timer <<'EOF'
[Unit]
Description=Refresh Microsoft download routing rules daily

[Timer]
OnCalendar=daily
RandomizedDelaySec=30min
Persistent=true

[Install]
WantedBy=timers.target
EOF
systemctl daemon-reload
systemctl enable --now kai-microsoft-rules.timer

# Mihomo / Clash Verge subscription.
# Design goals:
# - TUN as the primary traffic capture path, with strict routing and DNS hijack.
# - IPv6 disabled end-to-end until an explicit IPv6 proxy policy is introduced.
# - DIRECT traffic uses direct DNS; proxied traffic uses remote DoH through PROXY.
# - AI services use a dedicated fixed group so they cannot silently fall back to DIRECT.
# - Fake-IP exclusions keep LAN / captive-portal / Windows connectivity checks functional.
cat > /opt/kai-subscription/mihomo.yaml <<EOF
mixed-port: 7890
allow-lan: false
mode: rule
log-level: info
ipv6: false
unified-delay: true
tcp-concurrent: true

profile:
  store-selected: true
  store-fake-ip: true

tun:
  enable: true
  stack: mixed
  dns-hijack:
    - any:53
  auto-route: true
  auto-detect-interface: true
  strict-route: true

dns:
  enable: true
  listen: 127.0.0.1:1053
  ipv6: false
  prefer-h3: false
  respect-rules: true
  enhanced-mode: fake-ip
  fake-ip-range: 198.18.0.1/16
  fake-ip-filter-mode: blacklist
  fake-ip-filter:
    - '*.lan'
    - '*.local'
    - 'localhost'
    - '+.msftconnecttest.com'
    - '+.msftncsi.com'
    - 'connectivitycheck.gstatic.com'
    - 'captive.apple.com'
  # Bootstrap resolvers are IP literals so resolver hostnames can always be resolved.
  default-nameserver:
    - 223.5.5.5
    - 1.1.1.1
  # Default / proxied DNS leaves through the selected proxy group.
  nameserver:
    - 'https://1.1.1.1/dns-query#PROXY'
    - 'https://8.8.8.8/dns-query#PROXY'
  # Required when respect-rules=true. The Xray endpoint is currently an IP, but
  # keeping this explicit avoids a bootstrap loop if it becomes a hostname later.
  proxy-server-nameserver:
    - 223.5.5.5
    - 1.1.1.1
  # CN/private domains prefer nearby resolvers.
  nameserver-policy:
    'services.googleapis.cn':
      - 'https://1.1.1.1/dns-query#AI-US'
    '+.xn--ngstr-lra8j.com':
      - 'https://1.1.1.1/dns-query#AI-US'
    'geosite:private,cn':
      - https://doh.pub/dns-query
      - https://dns.alidns.com/dns-query
  # DIRECT connections are re-resolved with direct DNS instead of remote DoH.
  direct-nameserver:
    - https://doh.pub/dns-query
    - https://dns.alidns.com/dns-query
  direct-nameserver-follow-policy: true

proxies:
  - name: "${NODE_NAME}"
    type: vless
    server: ${PUBLIC_IP}
    port: 443
    uuid: "${VLESS_UUID}"
    network: tcp
    tls: true
    udp: true
    flow: xtls-rprx-vision
    servername: ${REALITY_SNI}
    client-fingerprint: chrome
    packet-encoding: xudp
    reality-opts:
      public-key: "${REALITY_PUBLIC_KEY}"
      short-id: "${REALITY_SHORT_ID}"

proxy-groups:
  - name: AI-US
    type: select
    proxies:
      - "${NODE_NAME}"
  - name: PROXY
    type: select
    proxies:
      - "${NODE_NAME}"
      - DIRECT

rules:
  # Google Play bootstrap, storefront and downloads stay on the fixed node.
  - DOMAIN,services.googleapis.cn,AI-US
  - DOMAIN,play-fe.googleapis.com,AI-US
  - DOMAIN,android.clients.google.com,AI-US
  - DOMAIN-SUFFIX,xn--ngstr-lra8j.com,AI-US
  - DOMAIN,play.google.com,AI-US
  - DOMAIN,play.googleapis.com,AI-US
  - DOMAIN,android.googleapis.com,AI-US
  - DOMAIN,android.apis.google.com,AI-US
  - DOMAIN,dl.google.com,AI-US
  - DOMAIN,dl-ssl.google.com,AI-US
  - DOMAIN-SUFFIX,gvt1.com,AI-US
  - DOMAIN-SUFFIX,ggpht.com,AI-US
  - DOMAIN-SUFFIX,gvt2.com,AI-US
  - DOMAIN-SUFFIX,gvt3.com,AI-US

  # AI / coding services first: fixed node, no DIRECT fallback.
  - DOMAIN-SUFFIX,openai.com,AI-US
  - DOMAIN-SUFFIX,chatgpt.com,AI-US
  - DOMAIN-SUFFIX,oaistatic.com,AI-US
  - DOMAIN-SUFFIX,oaiusercontent.com,AI-US
  - DOMAIN-SUFFIX,anthropic.com,AI-US
  - DOMAIN-SUFFIX,claude.ai,AI-US
  - DOMAIN,gemini.google.com,AI-US
  - DOMAIN,aistudio.google.com,AI-US
  - DOMAIN-SUFFIX,ai.google.dev,AI-US
  - DOMAIN-SUFFIX,generativelanguage.googleapis.com,AI-US
  - DOMAIN-SUFFIX,cursor.com,AI-US
  - DOMAIN-SUFFIX,cursor.sh,AI-US

  # Local and mainland-China traffic stays direct.
  - RULE-SET,microsoft-download,DIRECT
  - GEOSITE,private,DIRECT
  - GEOIP,private,DIRECT,no-resolve
  - GEOSITE,cn,DIRECT
  - GEOIP,CN,DIRECT,no-resolve

  # Everything else follows the normal proxy group.
  - MATCH,PROXY

rule-providers:
  microsoft-download:
    type: http
    behavior: classical
    format: yaml
    url: https://${SUB_DOMAIN}:${SUB_HTTPS_PORT}/rules/microsoft-download.yaml
    path: ./ruleset/kai-microsoft-download.yaml
    interval: 86400
    proxy: AI-US
EOF

# Generic VLESS + REALITY URI. Shadowrocket can import this URI directly.
VLESS_URI="vless://${VLESS_UUID}@${PUBLIC_IP}:443?security=reality&encryption=none&pbk=${REALITY_PUBLIC_KEY}&fp=chrome&type=tcp&flow=xtls-rprx-vision&sni=${REALITY_SNI}&sid=${REALITY_SHORT_ID}#${NODE_NAME}"
printf '%s\n' "$VLESS_URI" > /opt/kai-subscription/vless-link.txt

# Shadowrocket subscription body: Base64-encoded VLESS URI.
printf '%s\n' "$VLESS_URI" | base64 | tr -d '\n' > /opt/kai-subscription/shadowrocket.txt
printf '\n' >> /opt/kai-subscription/shadowrocket.txt

chown root:www-data /opt/kai-subscription/mihomo.yaml /opt/kai-subscription/vless-link.txt /opt/kai-subscription/shadowrocket.txt
chmod 640 /opt/kai-subscription/mihomo.yaml /opt/kai-subscription/vless-link.txt /opt/kai-subscription/shadowrocket.txt

cat > /opt/kai-subscription/server.py <<'PY'
import os
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

PORT = int(os.environ.get('SUB_PORT', '18080'))
MIHOMO_PATH = os.environ['MIHOMO_PATH']
SHADOWROCKET_PATH = os.environ['SHADOWROCKET_PATH']
FILES = {
    MIHOMO_PATH: ('/opt/kai-subscription/mihomo.yaml', 'text/yaml; charset=utf-8'),
    SHADOWROCKET_PATH: ('/opt/kai-subscription/shadowrocket.txt', 'text/plain; charset=utf-8'),
}

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        item = FILES.get(self.path)
        if not item:
            self.send_response(404)
            self.end_headers()
            return
        path, content_type = item
        with open(path, 'rb') as f:
            data = f.read()
        self.send_response(200)
        self.send_header('Content-Type', content_type)
        self.send_header('Cache-Control', 'no-store')
        self.end_headers()
        self.wfile.write(data)

    def log_message(self, *args):
        return

ThreadingHTTPServer(('127.0.0.1', PORT), Handler).serve_forever()
PY
chmod 640 /opt/kai-subscription/server.py
chown root:www-data /opt/kai-subscription/server.py
/usr/bin/python3 -m py_compile /opt/kai-subscription/server.py

cat > /etc/kai-subscription.env <<EOF
MIHOMO_PATH=/sub/${SUB_TOKEN}.yaml
SHADOWROCKET_PATH=/sr/${SUB_TOKEN}
SUB_PORT=${SUB_PORT}
EOF
chmod 600 /etc/kai-subscription.env

cat > /etc/systemd/system/kai-subscription.service <<'EOF'
[Unit]
Description=Kai local client subscription backend
After=network.target

[Service]
Type=simple
User=www-data
Group=www-data
EnvironmentFile=/etc/kai-subscription.env
ExecStart=/usr/bin/python3 /opt/kai-subscription/server.py
Restart=on-failure
RestartSec=3
NoNewPrivileges=true
PrivateTmp=true
ProtectHome=true
ProtectSystem=strict
ReadOnlyPaths=/opt/kai-subscription
RestrictAddressFamilies=AF_INET AF_UNIX

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable kai-subscription >/dev/null 2>&1 || true
systemctl restart kai-subscription

# Type=simple returns before the Python server necessarily finishes binding.
# Wait for the local backend instead of racing it with an immediate curl.
ready=0
for _ in $(seq 1 20); do
  if curl -fsS --connect-timeout 1 "http://127.0.0.1:${SUB_PORT}/sub/${SUB_TOKEN}.yaml" >/dev/null 2>&1; then
    ready=1
    break
  fi
  if ! systemctl is-active --quiet kai-subscription; then
    break
  fi
  sleep 0.25
done

if [[ "$ready" != 1 ]]; then
  echo '[ERROR] kai-subscription did not become ready.'
  systemctl status kai-subscription --no-pager || true
  journalctl -u kai-subscription -n 30 --no-pager || true
  exit 1
fi

# Minimal generated-profile assertions. These catch accidental regression in the
# critical leak-prevention and fixed-AI-routing settings without requiring mihomo
# itself to be installed on the VPS.
grep -q '^  strict-route: true$' /opt/kai-subscription/mihomo.yaml
grep -q '^  respect-rules: true$' /opt/kai-subscription/mihomo.yaml
grep -q '^  direct-nameserver:$' /opt/kai-subscription/mihomo.yaml
grep -q '^  - name: AI-US$' /opt/kai-subscription/mihomo.yaml
grep -q 'DOMAIN-SUFFIX,chatgpt.com,AI-US' /opt/kai-subscription/mihomo.yaml
grep -q 'DOMAIN-SUFFIX,claude.ai,AI-US' /opt/kai-subscription/mihomo.yaml
grep -q 'DOMAIN,services.googleapis.cn,AI-US' /opt/kai-subscription/mihomo.yaml
grep -q 'DOMAIN-SUFFIX,gvt1.com,AI-US' /opt/kai-subscription/mihomo.yaml
grep -q 'RULE-SET,microsoft-download,DIRECT' /opt/kai-subscription/mihomo.yaml
grep -q "url: https://${SUB_DOMAIN}:${SUB_HTTPS_PORT}/rules/microsoft-download.yaml" /opt/kai-subscription/mihomo.yaml
grep -q 'DOMAIN-SUFFIX,windowsupdate.com' /opt/kai-subscription/rules/microsoft-download.yaml
systemctl is-active --quiet kai-microsoft-rules.timer

curl -fsS "http://127.0.0.1:${SUB_PORT}/sr/${SUB_TOKEN}" | base64 -d | grep -q '^vless://'
ss -lnt | grep -q "127.0.0.1:${SUB_PORT}"
echo '[OK] Mihomo and Shadowrocket local subscription endpoints ready on 127.0.0.1:'"${SUB_PORT}"
echo '[OK] Mihomo profile includes strict TUN, split DNS, fixed AI/Google Play routing and Microsoft download DIRECT rules.'
