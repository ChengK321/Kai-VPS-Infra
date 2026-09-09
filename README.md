# Kai-VPS-Infra — Bandwagon branch

Modular VPS deployment for the BandwagonHost instance, derived from the configuration already validated on the Tencent Cloud VPS.

The goal is **stepwise, observable, repeatable deployment** rather than one large all-in-one script.

## Modules

- `00-system-base.sh` — OS update and base packages
- `05-init-config.sh` — initialize runtime configuration
- `10-admin-ssh.sh` — admin user and SSH key hardening
- `20-security-network.sh` — UFW, fail2ban, unattended upgrades, BBR
- `30-xray-reality.sh` — Xray VLESS + XTLS Vision + REALITY on 443/tcp
- `40-subscription.sh` — local Mihomo subscription backend on 127.0.0.1:18080
- `50-nginx-cert.sh` — Nginx + Let's Encrypt + HTTPS subscription on 8443
- `90-health-check.sh` — service, ports and firewall checks

See `docs/deployment.md` for the execution order.

## Secrets policy

This repository contains **no server credentials**. Runtime UUIDs, REALITY keys and subscription tokens are generated on the VPS and stored only in `/etc/kai-vps/secrets.env`.
