# Kai-VPS-Infra — Bandwagon branch

Modular VPS deployment for the BandwagonHost-style instance, also usable on compatible Ubuntu VPS nodes such as the current DMIT node, derived from the configuration already validated on the Tencent Cloud VPS.

The goal is **stepwise, observable, repeatable deployment** rather than one large all-in-one script.

## Modules

- `00-system-base.sh` — OS update and base packages
- `05-init-config.sh` — initialize runtime configuration
- `10-admin-ssh.sh` — admin user and SSH key hardening
- `20-security-network.sh` — UFW, fail2ban, unattended upgrades, BBR
- `30-xray-reality.sh` — Xray VLESS + XTLS Vision + REALITY on 443/tcp
- `35-dmit-backup-port.sh` — optional IPv4 TCP 24443 → 443 UFW NAT redirect for DMIT; never changes Xray clients
- `40-subscription.sh` — local Mihomo / Shadowrocket subscription backend on 127.0.0.1:18080; generates strict TUN, split DNS, IPv6-off and fixed AI-routing policy
- `50-nginx-cert.sh` — Nginx + Let's Encrypt + HTTPS subscription on 8443
- `90-health-check.sh` — service, ports and firewall checks

## Clash profiles

Additional client profiles:

- `clash/strict-ai-exit.yaml`
  - AI dedicated exit
  - OpenAI / Claude / Cursor / Gemini fixed through DMIT
  - IPv6 disabled
  - Fake-IP DNS mode

- `clash/daily-balanced.yaml`
  - Daily browsing mode
  - CN direct access
  - Overseas traffic through proxy

## Verification

See:

- `docs/deployment.md`
- `docs/client-leak-check.md`
- `docs/SECURITY_CHECKLIST.md`
- `docs/AI_PROXY_USAGE.md`

for deployment, client leak checks and AI usage recommendations.

## Secrets policy

This repository contains **no server credentials**. Runtime UUIDs, REALITY keys and subscription tokens are generated on the VPS and stored only in `/etc/kai-vps/secrets.env`.

The current DMIT host has additional clients, a local REALITY fallback and a hardened service override. `30-xray-reality.sh` refuses to overwrite an existing Xray configuration unless `XRAY_REPLACE_EXISTING=1` is set explicitly. See `docs/dmit-current-network.md` before changing that host.
