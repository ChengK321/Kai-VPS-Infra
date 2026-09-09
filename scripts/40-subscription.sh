#!/usr/bin/env bash
set -Eeuo pipefail
[[ ${EUID:-$(id -u)} -eq 0 ]] || { echo 'Please run as root/sudo'; exit 1; }
source /etc/kai-vps/bandwagon.env
source /etc/kai-vps/secrets.env
: "${SUB_PORT:=18080}"
PUBLIC_IP="${PUBLIC_IP:-$(curl -4 -fsS --max-time 8 https://api.ipify.org)}"
SUB_TOKEN="${SUB_TOKEN:-$(openssl rand -hex 32)}"
printf '\nSUB_TOKEN=%s\n' "$SUB_TOKEN" >> /etc/kai-vps/secrets.env
install -d -m 750 -o root -g www-data /opt/kai-subscription
cat > /opt/kai-subscription/mihomo.yaml <<EOF
mixed-port: 7890
allow-lan: false
mode: rule
log-level: info
ipv6: false
unified-delay: true
tcp-concurrent: true
tun:
  enable: true
  stack: mixed
  dns-hijack: [any:53]
  auto-route: true
  auto-detect-interface: true
  strict-route: true
dns:
  enable: true
  listen: 127.0.0.1:1053
  ipv6: false
  enhanced-mode: fake-ip
  fake-ip-range: 198.18.0.1/16
proxies:
  - name: Bandwagon-Xray-Reality
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
  - name: PROXY
    type: select
    proxies: [Bandwagon-Xray-Reality, DIRECT]
rules:
  - GEOSITE,private,DIRECT
  - GEOIP,private,DIRECT,no-resolve
  - GEOSITE,cn,DIRECT
  - GEOIP,CN,DIRECT,no-resolve
  - MATCH,PROXY
EOF
chown root:www-data /opt/kai-subscription/mihomo.yaml
chmod 640 /opt/kai-subscription/mihomo.yaml
cat > /opt/kai-subscription/server.py <<'PY'
import os
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
PORT=int(os.environ.get('SUB_PORT','18080')); SUB_PATH=os.environ['SUB_PATH']; YAML_PATH='/opt/kai-subscription/mihomo.yaml'
class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path != SUB_PATH:
            self.send_response(404); self.end_headers(); return
        with open(YAML_PATH,'rb') as f: data=f.read()
        self.send_response(200); self.send_header('Content-Type','text/yaml; charset=utf-8'); self.send_header('Cache-Control','no-store'); self.end_headers(); self.wfile.write(data)
    def log_message(self, *args): return
ThreadingHTTPServer(('127.0.0.1',PORT),Handler).serve_forever()
PY
cat > /etc/kai-subscription.env <<EOF
SUB_PATH=/sub/${SUB_TOKEN}.yaml
SUB_PORT=${SUB_PORT}
EOF
chmod 600 /etc/kai-subscription.env
cat > /etc/systemd/system/kai-subscription.service <<'EOF'
[Unit]
Description=Kai local Mihomo subscription backend
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
systemctl enable --now kai-subscription
systemctl restart kai-subscription
curl -fsS "http://127.0.0.1:${SUB_PORT}/sub/${SUB_TOKEN}.yaml" >/dev/null
echo '[OK] local subscription backend ready'
