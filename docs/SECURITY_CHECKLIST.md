# Proxy Security Checklist

## IPv4

Check:

```bash
curl -4 ifconfig.me
```

Expected: DMIT VPS IPv4.

## IPv6

IPv6 is disabled in AI profile to avoid identity split.

## DNS Leak

Verify with:

- dnsleaktest.com

Expected: DNS servers should not reveal local ISP.

## WebRTC

Verify with:

- browserleaks.com/webrtc

Expected:

```
No Public IP Leak
```

## Rule verification

Clash log should show:

```
chatgpt.com -> AI-US -> DMIT-Xray-Reality
claude.ai -> AI-US -> DMIT-Xray-Reality
```

## Current validation result

DMIT node verified:

- Windows Clash Verge Rev: passed
- Android Clash Meta: passed
- TUN mode: passed
- WebRTC: passed
