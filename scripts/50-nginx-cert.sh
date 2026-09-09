#!/usr/bin/env bash
set -Eeuo pipefail
[[ ${EUID:-$(id -u)} -eq 0 ]] || { echo 'Please run as root/sudo'; exit 1; }
source /etc/kai-vps/bandwagon.env
source /etc/kai-vps/secrets.env
: "${SUB_PORT:=18080}"
: "${SUB_HTTPS_PORT:=8443}"
[[ -n "${SUB_DOMAIN:-}" ]] || { echo 'SUB_DOMAIN is empty'; exit 1; }
PUBLIC_IP="${PUBLIC_IP:-$(curl -4 -fsS --max-time 8 https://api.ipify.org)}"
DNS_A="$(dig +short A "$SUB_DOMAIN" | tr '\n' ' ')"
[[ " $DNS_A " == *" $PUBLIC_IP "* ]] || { echo "DNS A record does not point to this VPS: $DNS_A"; exit 1; }
ACME_ROOT=/var/www/letsencrypt
SITE=/etc/nginx/sites-available/kai-subscription
install -d -m 755 "$ACME_ROOT"
rm -f /etc/nginx/sites-enabled/default
cat > "$SITE" <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name ${SUB_DOMAIN};
    server_tokens off;
    access_log off;
    location ^~ /.well-known/acme-challenge/ { root ${ACME_ROOT}; default_type text/plain; }
    location / { return 404; }
}
EOF
ln -sfn "$SITE" /etc/nginx/sites-enabled/kai-subscription
nginx -t
systemctl enable --now nginx
systemctl reload nginx
if [[ ! -s "/etc/letsencrypt/live/${SUB_DOMAIN}/fullchain.pem" ]]; then
  if [[ -n "${CERTBOT_EMAIL:-}" ]]; then
    certbot certonly --webroot -w "$ACME_ROOT" -d "$SUB_DOMAIN" --agree-tos --non-interactive --email "$CERTBOT_EMAIL"
  else
    certbot certonly --webroot -w "$ACME_ROOT" -d "$SUB_DOMAIN" --agree-tos --non-interactive --register-unsafely-without-email
  fi
fi
cat > "$SITE" <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name ${SUB_DOMAIN};
    server_tokens off;
    access_log off;
    location ^~ /.well-known/acme-challenge/ { root ${ACME_ROOT}; default_type text/plain; }
    location / { return 404; }
}
server {
    listen ${SUB_HTTPS_PORT} ssl;
    listen [::]:${SUB_HTTPS_PORT} ssl;
    server_name ${SUB_DOMAIN};
    ssl_certificate /etc/letsencrypt/live/${SUB_DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${SUB_DOMAIN}/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_session_tickets off;
    server_tokens off;
    access_log off;
    add_header X-Content-Type-Options nosniff always;
    add_header Cache-Control "no-store" always;

    location = /sub/${SUB_TOKEN}.yaml {
        proxy_pass http://127.0.0.1:${SUB_PORT};
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }

    location = /sr/${SUB_TOKEN} {
        proxy_pass http://127.0.0.1:${SUB_PORT};
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }

    location / { return 404; }
}
EOF
nginx -t
systemctl reload nginx
install -d -m 755 /etc/letsencrypt/renewal-hooks/deploy
printf '%s\n' '#!/usr/bin/env bash' 'systemctl reload nginx' > /etc/letsencrypt/renewal-hooks/deploy/reload-nginx.sh
chmod 755 /etc/letsencrypt/renewal-hooks/deploy/reload-nginx.sh
echo "[OK] Mihomo: https://${SUB_DOMAIN}:${SUB_HTTPS_PORT}/sub/${SUB_TOKEN}.yaml"
echo "[OK] Shadowrocket: https://${SUB_DOMAIN}:${SUB_HTTPS_PORT}/sr/${SUB_TOKEN}"
