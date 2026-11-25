# DMIT Xray network state (read-only audit, 2026-11-25)

This is a snapshot for maintaining the DMIT deployment, not a claim that a fresh
install exactly reproduces the existing host. Verify again before changes.

- Xray 26.6.27 is active and listens on TCP 443. Its single VLESS + REALITY
  inbound uses `xtls-rprx-vision` and currently has seven clients. Client IDs,
  private key and short ID are deliberately absent from this repository.
- REALITY `serverNames` contains `reality.kaikunhome.cn`; `target` is a local
  Nginx listener at `127.0.0.1:14444`. Nginx also serves HTTPS on 8443.
- Xray uses a `90-dmit-hardening.conf` systemd override with a dedicated
  `xray-dmit` account, a bind-service capability and filesystem isolation.
- External IPv4 TCP 24443 is redirected to 443 by a NAT `PREROUTING` rule in
  `/etc/ufw/before.rules`. Xray itself does not listen on 24443. At audit time,
  `iptables-save -t nat` showed **two** live copies of the redirect; the first
  had packet hits and the second had none. The persistence file had one rule.
  Investigate before rerunning the optional setup script or removing a rule.
- UFW allows 443 and 8443. It also has a source-specific 443 deny rule; do not
  replace its policy with the generic security script without reviewing it.

## Safe maintenance

1. Back up `/usr/local/etc/xray/config.json`, the Xray service overrides,
   `/etc/ufw/before.rules` and `/etc/kai-vps/secrets.env` outside Git.
2. Run `xray run -test -config /usr/local/etc/xray/config.json` before any
   Xray restart. Check `systemctl is-active xray` and live connectivity after.
3. Do not rerun `30-xray-reality.sh` on this host. It is a fresh-install
   generator and would replace the seven-client configuration and local
   fallback. Its overwrite guard exists to prevent an accidental rerun.
4. `35-dmit-backup-port.sh` is for a new compatible UFW host with an explicit
   public IPv4 address. Review an existing DMIT redirect before using it.
   The script persists one NAT rule in UFW and reloads UFW; it does not add a
   second Xray inbound. If an upstream path to 443 fails, the client must
   explicitly select the 24443 endpoint.

## Read-only checks

```bash
systemctl is-active xray nginx
ss -lntp | grep -E ':443 |:8443 |:14444 '
sudo iptables-save -t nat | grep KAI_DMIT_BACKUP_24443
sudo grep KAI_DMIT_BACKUP_24443 /etc/ufw/before.rules
sudo xray run -test -config /usr/local/etc/xray/config.json
```
