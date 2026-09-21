# Kai Agent Node Bootstrap v1.0 Phase 9

## Goal

Upgrade the installer from a development helper into a repeatable production bootstrap flow.

## Principles

- Installer is idempotent.
- Secrets are never committed.
- Installer never performs automatic reboot.
- Reboot is only a manual validation step after installation.
- Authentication steps requiring user authorization remain interactive.

## State Tracking

Installer keeps state under:

```
~/.local/state/kai-agent-node/install.state
```

Purpose:

- identify completed phases
- support future resume mode
- simplify repair workflows

## Installation Flow

```
Input configuration
        |
        v
Create directories
        |
        v
Install system dependencies
        |
        v
Install WebCodex
        |
        v
Prepare Server / Runner
        |
        v
Prepare OpenAI Secure MCP Tunnel
        |
        v
Generate systemd services
        |
        v
Health check
```

## Reboot Policy

The installer does NOT run:

```
shutdown
reboot
systemctl reboot
```

After successful installation the user may manually execute:

```
sudo reboot
```

and then verify:

```
./health-check.sh
```

## Future Resume

Future versions will support:

```
./install.sh --resume
```

using the state file to skip completed phases.
