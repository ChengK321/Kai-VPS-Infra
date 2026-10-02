#!/usr/bin/env bash
set -Eeuo pipefail

# Kai VPS proxy final validation
# Checks runtime state after deployment or subscription regeneration.

ok=0
fail=0

pass(){
  echo "[OK] $1"
  ok=$((ok+1))
}

warn(){
  echo "[WARN] $1"
}

error(){
  echo "[FAIL] $1"
  fail=$((fail+1))
}

check_service(){
  if systemctl is-active --quiet "$1"; then
    pass "service $1"
  else
    error "service $1"
  fi
}

echo "========== Kai VPS Proxy Health =========="

echo ""
echo "[1] Services"
check_service xray
check_service nginx
check_service kai-subscription

echo ""
echo "[2] Ports"
for port in 443 80 18080; do
  if ss -lnt | grep -q ":${port} "; then
    pass "listen port ${port}"
  else
    warn "port ${port} not detected"
  fi
done

echo ""
echo "[3] Memory"
free -m
AVAILABLE=$(free -m | awk '/Mem:/ {print $7}')
if [ "${AVAILABLE}" -gt 500 ]; then
  pass "memory available ${AVAILABLE}MB"
else
  warn "low memory available ${AVAILABLE}MB"
fi

echo ""
echo "[4] Xray config"
if /usr/local/bin/xray -test -config /usr/local/etc/xray/config.json >/dev/null 2>&1; then
  pass "xray config syntax"
else
  warn "xray config test unavailable or failed"
fi

echo ""
echo "[5] Subscription backend"
if curl -fsS --connect-timeout 3 http://127.0.0.1:18080/ >/dev/null 2>&1; then
  pass "subscription backend reachable"
else
  warn "subscription endpoint requires generated token path"
fi

echo ""
echo "[6] Network identity"
IPV4=$(curl -4 -fsS --max-time 5 https://api.ipify.org || true)
if [ -n "${IPV4}" ]; then
  pass "IPv4 exit ${IPV4}"
else
  error "IPv4 exit check failed"
fi

if curl -6 -fsS --max-time 5 https://api64.ipify.org >/tmp/kai_ipv6_check 2>/dev/null; then
  warn "IPv6 reachable: $(cat /tmp/kai_ipv6_check)"
else
  pass "IPv6 unavailable/disabled"
fi
rm -f /tmp/kai_ipv6_check

echo ""
echo "[7] Recent processes"
ps aux --sort=-%mem | head -10

echo ""
if [ "$fail" -eq 0 ]; then
  echo "========== HEALTHY =========="
else
  echo "========== FAILED: ${fail} =========="
fi

echo "Passed checks: ${ok}"
exit "$fail"
