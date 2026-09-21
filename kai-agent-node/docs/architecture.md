# Kai Agent Node v1.0 Architecture

## Overview

Kai Agent Node packages a VPS into a persistent AI development node.

## Runtime

```text
ChatGPT Desktop
      |
      | OpenAI Secure MCP Tunnel
      |
Kai VPS
      |
      +-- WebCodex Server
      |      |
      |      +-- MCP endpoint
      |
      +-- WebCodex Runner
             |
             +-- registered projects
```

## Bootstrap requirements

Input:

- Ubuntu account
- sudo permission
- optional workspace directory

Output:

- WebCodex installed
- MCP server running
- Runner registered
- OpenAI tunnel persistent
- systemd auto start

## Service model

Expected services:

- webcodex.service
- webcodex-runner.service
- webcodex-tunnel.service

## Future versions

v1.0:
- reliable bootstrap
- service management
- health check

v1.1:
- upgrade management
- backup/restore
- multi-project support

