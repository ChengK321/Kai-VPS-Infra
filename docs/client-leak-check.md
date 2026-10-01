# Mihomo / Clash 客户端防泄漏与固定出口检查

适用场景：Windows（Clash Verge Rev / Mihomo）与 Android（Clash / Mihomo）通过本仓库生成的 HTTPS 订阅连接 Xray VLESS + REALITY。

## 推荐基线

### Windows

- TUN：开启
- System Proxy：关闭
- Mode：Rule
- PROXY：选择 `Kai-Xray-Reality`（或 `NODE_NAME` 自定义名称）
- IPv6：由订阅统一关闭

### Android

- VPN / TUN：开启
- Mode：Rule
- PROXY：选择固定 Xray 节点
- 排查阶段建议先关闭 Android Private DNS，避免与 Mihomo DNS 叠加

## 配置设计

生成的 Mihomo 配置具备：

- `strict-route: true`
- `dns-hijack: any:53`
- Fake-IP DNS
- IPv6 全局关闭
- `respect-rules: true`
- DIRECT 使用 direct DNS
- 代理流量默认使用经 `PROXY` 出口的远端 DoH
- `AI-US` 独立策略组，只有固定 Xray 节点，没有 DIRECT fallback
- OpenAI / ChatGPT / Claude / Anthropic / Gemini 核心域名 / Cursor 核心域名优先命中 `AI-US`

## 八项验收

### 1. TUN / System Proxy / 固定出口

Windows：

```powershell
curl.exe -4 ifconfig.me
```

应返回 VPS 的公网 IPv4。浏览器、ChatGPT/Claude/Cursor 等应用在 Mihomo Connections 中应命中 `AI-US` 或 `PROXY`，不能命中 DIRECT。

Android：分别在 Wi-Fi 和蜂窝网络下检查公网 IPv4，都应为同一 VPS 出口。

### 2. DNS 分流与 DNS 泄漏

Windows 测试前可清缓存：

```powershell
ipconfig /flushdns
```

使用 DNS leak 检测页时，重点检查是否出现当前 ISP / 家庭路由器 DNS。DNS 服务器本身不要求显示 VPS IP；关键是目标域名解析不能绕过 Mihomo 回到 ISP DNS。

Android 排查阶段先关闭 Private DNS；确认 Mihomo 链路正常后，再决定是否恢复。

### 3. WebRTC

使用 WebRTC leak 检测页检查：

- 不应出现真实 ISP 公网 IPv4
- 不应出现真实 ISP IPv6
- `192.168.x.x`、`10.x.x.x` 等局域网地址不是公网泄漏

若泄漏，优先排查 TUN、IPv6、UDP 路由，不要先依赖浏览器扩展屏蔽 WebRTC。

### 4. 系统环境一致性

时区、系统语言、浏览器语言、Locale 属于浏览器指纹，不等同于网络泄漏。优先确保出口 IP、DNS、IPv6、WebRTC 一致，再决定是否调整系统环境。

浏览器控制台可检查：

```javascript
Intl.DateTimeFormat().resolvedOptions().timeZone
navigator.language
```

### 5. Strict Route / IPv6

Windows：

```powershell
curl.exe -4 ifconfig.me
curl.exe -6 ifconfig.me
```

当前策略下预期：

- IPv4：返回 VPS IPv4
- IPv6：失败或无可用 IPv6

如果 `curl -6` 返回本地 ISP IPv6，视为 IPv6 泄漏。

### 6. 规则优先级

AI 规则必须位于 private / CN / MATCH 之前。

Clash/Mihomo 日志或 Connections 中确认：

- ChatGPT / OpenAI -> `AI-US`
- Claude / Anthropic -> `AI-US`
- Gemini 核心域名 -> `AI-US`
- Cursor 核心域名 -> `AI-US`

`AI-US` 只有固定节点，不允许 DIRECT fallback。

### 7. Cookie / LocalStorage / App 本地状态

网络层验证通过后，如果某个站点仍异常，先用无痕窗口验证。只有“无痕正常、旧 Profile 异常”时，再针对单站点清理 Cookie、LocalStorage、Service Worker 和缓存。

不要把全浏览器清空或重装作为第一排查手段。

### 8. 最终验收

| 项目 | Windows | Android | 合格标准 |
| --- | --- | --- | --- |
| IPv4 | 检查 | 检查 | VPS 固定出口 |
| IPv6 | 检查 | 检查 | 当前策略下不泄漏 / 不通 |
| DNS | 检查 | 检查 | 无 ISP DNS 泄漏 |
| WebRTC | 检查 | 检查 | 无真实公网 IP |
| TUN | 开启 | 开启 | 流量受 Mihomo 接管 |
| System Proxy | 关闭 | N/A | Windows 不依赖 System Proxy |
| AI Rule | 检查 | 检查 | 命中 `AI-US` |
| Wi-Fi / Cellular | N/A | 两者检查 | 出口一致 |

## 更新订阅后的客户端操作

服务端重新运行 `40-subscription.sh` 时会保留已有 `SUB_TOKEN`，因此 HTTPS 订阅 URL 不变。

客户端不需要删除并重新粘贴订阅地址，只需要：

1. 在 Clash/Mihomo 中执行“更新订阅 / Refresh”。
2. 确认新配置包含 `AI-US` 策略组。
3. Windows 如正在使用 TUN，建议关闭再开启一次 TUN，或重启 Mihomo Core。
4. Android 建议断开再连接一次 VPN/TUN。
5. 按本文件八项验收重新检查。
