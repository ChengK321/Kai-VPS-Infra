# Kai Agent Node Bootstrap v1.0 Phase 8

## Goal

Turn the previous module collection into an executable deployment workflow.

## Flow

```
Ubuntu VPS
   |
   v
install.sh
   |
   +-- collect directories
   |
   +-- install system dependencies
   |
   +-- install Node.js
   |
   +-- install WebCodex CLI
   |
   +-- prepare Server
   |
   +-- prepare Runner
   |
   +-- prepare OpenAI Secure MCP Tunnel
   |
   +-- generate systemd services
   |
   v
Kai Agent Node
```

## Design constraints

- Run as normal user, not root.
- Secrets stay outside git.
- Tunnel credentials are stored with restricted permissions.
- Service startup must survive reboot.

## Verification

After installation:

```
./health-check.sh

systemctl status webcodex
systemctl status webcodex-runner
systemctl status webcodex-tunnel
```
