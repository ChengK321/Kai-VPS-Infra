# Bandwagon deployment runbook

## Recommended order

1. `sudo bash scripts/00-system-base.sh`
2. `sudo bash scripts/05-init-config.sh`
3. Edit `/etc/kai-vps/bandwagon.env`
4. `sudo bash scripts/10-admin-ssh.sh`
5. Open a **new terminal** and verify SSH key login before closing the current session.
6. `sudo bash scripts/20-security-network.sh`
7. `sudo bash scripts/30-xray-reality.sh`
8. `sudo bash scripts/40-subscription.sh`
9. Configure the subscription domain A record to this VPS.
10. `sudo bash scripts/50-nginx-cert.sh`
11. `sudo bash scripts/90-health-check.sh`

## Runtime state

Public configuration is stored at `/etc/kai-vps/bandwagon.env`.
Generated credentials are stored at `/etc/kai-vps/secrets.env` with mode `600`.
Never commit either runtime file back into Git.

## Design principle

Each script owns one layer and can be rerun independently. A failure in Nginx or DNS should not force Xray, SSH, or firewall to be reinstalled. This makes troubleshooting and future changes much safer than a monolithic bootstrap script.
