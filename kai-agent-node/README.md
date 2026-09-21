# Kai Agent Node Bootstrap Installer v1.0

## Goal

Provide a one-command bootstrap path for a fresh Ubuntu VPS to become a Kai Agent Node.

Target environment:

- Fresh Ubuntu user with sudo permission
- No existing WebCodex installation
- No predefined `/opt/kai` dependency

## Design Principles

1. User-local installation first
2. Safe defaults with interactive overrides
3. Systemd managed services
4. Minimal secrets exposure
5. Reproducible installation

## Components

```text
Kai Agent Node
|
+-- WebCodex Server
|   +-- MCP endpoint
|
+-- WebCodex Runner
|   +-- project execution
|
+-- OpenAI Secure MCP Tunnel
|   +-- ChatGPT Desktop connection
|
+-- Health Check
```

## Planned installer flow

```text
install.sh
  |
  +-- check Ubuntu/sudo
  +-- install dependencies
  +-- install WebCodex
  +-- configure directories
  +-- register projects
  +-- create systemd units
  +-- enable services
  +-- run health check
```

## Default configuration

- WebCodex user: current login user
- Config: `~/.config/webcodex`
- Data: `~/.local/share/webcodex`
- Shared workspace: configurable (default `/opt/kai`)

