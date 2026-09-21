#!/usr/bin/env bash
set -euo pipefail

npm update -g @yyjeqhc/webcodex

systemctl restart webcodex webcodex-runner webcodex-tunnel || true

./health-check.sh
