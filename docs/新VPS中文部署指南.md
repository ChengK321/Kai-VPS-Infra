# 新 VPS 中文部署指南（bandwagon 分支）

本指南适用于**全新 Ubuntu VPS**，部署一个 VLESS + REALITY 的 Xray 节点，以及可选的 Mihomo / Shadowrocket HTTPS 订阅。先逐项确认结果，再进入下一步。脚本会修改 SSH、防火墙、系统服务和 Nginx；请保留 VPS 服务商的网页控制台作为恢复入口。

这套脚本生成的是**单客户端基础节点**。它不会复制旧 DMIT 的七个客户端、本机 REALITY 回退服务或专用 systemd 加固。旧 DMIT 的实际状态见 [DMIT 网络记录](dmit-current-network.md)。

## 0. 开始前准备

- VPS 使用兼容的 Ubuntu 系统，拥有 `root` 或可用 `sudo` 的初始账号，且能访问 GitHub、Ubuntu 软件源、Xray 下载源和证书服务。
- 有一个可从公网访问的 **IPv4 地址**，并在服务商的安全组 / 云防火墙中放行 SSH TCP 端口、80/TCP、443/TCP、8443/TCP；启用备用入口时再放行 24443/TCP。系统内的 UFW 规则不能替代服务商侧放行。
- 在自己的电脑上准备 SSH 密钥；**管理员账号必须有可用的公钥**。`10-admin-ssh.sh` 只会自动复制 `/root/.ssh/authorized_keys`，若初始登录账号不是 root，需手工把公钥放到新管理员账号。
- 记下当前 SSH 端口和服务商控制台入口。若要使用自己的订阅域名，准备好该域名的 DNS 管理权限。没有域名可使用脚本默认的 `sslip.io` 自动域名，但必须先确认它能解析到 VPS。
- 以下命令在 VPS 的仓库根目录执行。执行 `sudo` 命令前，先确认当前目录和分支。

## 1. 登录并取得脚本

用服务商提供的初始方式登录。若系统尚无 Git，先安装：

```bash
sudo apt-get update
sudo apt-get install -y git
git clone --branch bandwagon --single-branch https://github.com/ChengK321/Kai-VPS-Infra.git
cd Kai-VPS-Infra
git branch --show-current
```

最后一行应显示 `bandwagon`。不要从默认 `main` 分支执行本指南的命令。

## 2. 基础系统和参数

```bash
sudo bash scripts/00-system-base.sh
sudo bash scripts/05-init-config.sh
sudo nano /etc/kai-vps/bandwagon.env
```

`05` 只在配置文件不存在时复制模板，不会替你填写新 VPS 的真实值。至少逐项检查：

| 参数 | 如何填写 |
| --- | --- |
| `ADMIN_USER` | 新管理员账号名；默认 `kai`。 |
| `SSH_PORT` | 准备使用的 SSH 端口；更改前确认服务商侧已放行。 |
| `PUBLIC_IP` | 建议写入新 VPS 的公网 IPv4。运行备用端口脚本时**必须明确填写**，不能留空。 |
| `REALITY_SNI` | 基础节点使用的 REALITY 目标域名；默认 `www.cloudflare.com`。该目标需从 VPS 可达。 |
| `NODE_NAME` | 订阅里显示的节点名。 |
| `SUB_DOMAIN` | 自有订阅域名；使用它时需配置 A 记录指向 `PUBLIC_IP`。留空且 `AUTO_SSLIP_DOMAIN=1` 时，脚本使用 `<IPv4中的点改为连字符>.sslip.io`。 |
| `CERTBOT_EMAIL` | 建议填写自己的有效邮箱，以接收证书通知。 |
| `SUB_HTTPS_PORT` | 订阅 HTTPS 端口；默认 8443。 |

配置文件在 VPS 本地；不要把它、`/etc/kai-vps/secrets.env`、订阅 URL 或生成的客户端配置提交到 Git。

## 3. 管理员账号和 SSH：先验证，再开防火墙

```bash
sudo bash scripts/10-admin-ssh.sh
```

检查输出。若出现 `No SSH public key found`，脚本**没有启用 SSH 加固**。先将自己的公钥安装到管理员账号的 `~/.ssh/authorized_keys`，再重跑 `10`。例如初始账号已经通过公钥登录、其 `$HOME/.ssh/authorized_keys` 存在，且 `ADMIN_USER=kai` 时：

```bash
test -s "$HOME/.ssh/authorized_keys" && sudo install -m 600 -o kai -g kai "$HOME/.ssh/authorized_keys" /home/kai/.ssh/authorized_keys
sudo bash scripts/10-admin-ssh.sh
```

仅在 `test -s` 成功时执行后面的复制命令；如果初始账号用密码登录或密钥由云平台以其他方式注入，就在自己的电脑查看公钥（例如 `~/.ssh/id_ed25519.pub`），把**公钥文本**手工放入 `/home/kai/.ssh/authorized_keys`，设为 `kai:kai` 所有、权限 `600`，然后重跑 `10`。只复制 `.pub` 内容，绝不复制私钥。若改了 `ADMIN_USER`，示例中的账号和主目录也要对应修改。

**不要关闭当前 SSH 会话。**从自己的电脑新开终端，用配置的端口和管理员账号登录：

```bash
ssh -p <SSH_PORT> <ADMIN_USER>@<PUBLIC_IP>
```

登录后执行 `sudo -v`，确认新账号既能用密钥登录，也能执行 sudo。再确认服务商侧已放行新 SSH 端口。

在 VPS 上还可以核对 SSH 的**实际生效值**（仅看到脚本成功提示不够）：

```bash
sudo sshd -T | grep -E '^(port|permitrootlogin|passwordauthentication|pubkeyauthentication|allowusers) '
```

预期是配置的端口、`permitrootlogin no`、`passwordauthentication no`、`pubkeyauthentication yes` 和 `allowusers kai`（若改了管理员名，以实际账号为准）。新版 `10` 会检查这些值。部分 Ubuntu 云镜像的 `50-cloud-init.conf` 会启用密码认证；使用旧版脚本时请更新仓库并重跑 `10`，再检查生效值。

随后运行：

```bash
sudo bash scripts/20-security-network.sh
sudo ufw status verbose
```

`20` 会启用 UFW，并配置 fail2ban、自动更新和可用时的 BBR。运行后再次从新终端测试 SSH。如果 SSH 测试失败，使用仍开着的原会话或服务商控制台排查；不要继续安装后面的模块。

## 4. 部署 Xray

```bash
sudo bash scripts/30-xray-reality.sh
sudo systemctl is-active xray
sudo /usr/local/bin/xray run -test -config /usr/local/etc/xray/config.json
sudo ss -lntp | grep ':443 '
```

正常结果是 Xray `active`、配置测试通过、443/TCP 有监听。`30` 会下载安装指定版本的 Xray，生成 UUID、REALITY 密钥和短 ID，并把秘密写入 `/etc/kai-vps/secrets.env`。它只适合首次生成：若 Xray 配置文件已经存在，脚本会拒绝覆盖。**不要为了重跑而随意设置 `XRAY_REPLACE_EXISTING=1`**；这会替换现有客户端和回退配置。

### 可选：备用 24443 入口

只有确实需要备用端口时才做。先确认 `PUBLIC_IP` 已明确写成 VPS 的公网 IPv4，且服务商侧已放行 24443/TCP：

```bash
sudo bash scripts/35-dmit-backup-port.sh
sudo iptables-save -t nat | grep KAI_DMIT_BACKUP_24443
```

这个脚本把**外部 IPv4 TCP 24443 重定向到 Xray 的 443**，不会创建第二个 Xray 监听端口，也不会自动切换客户端。客户端需要另设 24443 节点或手动选择备用端口。已有 NAT 规则的 VPS 应先审查规则；脚本会重载 UFW。如果脚本提示规则重复或内容不同，不要盲目删规则。

## 5. 生成订阅并申请 HTTPS 证书

```bash
sudo bash scripts/40-subscription.sh
sudo systemctl is-active kai-subscription
```

`40` 会生成本地 Mihomo 配置、Shadowrocket 链接和订阅服务，并生成订阅令牌。服务只监听 `127.0.0.1:18080`，之后由 Nginx 对外提供 HTTPS。

运行 `50` **之前**，先确认域名条件：

- 自有域名：把 `SUB_DOMAIN` 的 A 记录指向新 VPS 的公网 IPv4，等待解析生效；可运行 `dig +short A <你的域名>` 核对。
- 自动 `sslip.io` 域名：确认派生出的域名解析为该公网 IPv4。若该域名在当前网络不可解析或无法从公网访问，请改用自己的域名。
- 80/TCP 必须能从公网到达 VPS，供 HTTP 证书验证使用；8443/TCP 供订阅 HTTPS 使用。若其他服务占用 80 或 8443，先处理端口冲突。

条件满足后运行：

```bash
sudo bash scripts/50-nginx-cert.sh
sudo nginx -t
sudo systemctl is-active nginx
```

`50` 会移除 Nginx 默认站点链接并写入订阅站点。成功时会打印 Mihomo 和 Shadowrocket 的 HTTPS 订阅 URL；**URL 中含有访问令牌**，只放入自己的客户端，不要公开截图或提交到仓库。证书申请失败时，先检查 DNS、服务商安全组和 80/TCP 的公网可达性，再重试 `50`。

## 6. 最后检查和客户端验证

```bash
sudo bash scripts/90-health-check.sh
sudo systemctl is-active xray kai-subscription nginx
sudo ufw status verbose
```

`90` 主要展示状态，**不能单独证明外部客户端可用**。在自己的 Mihomo / Shadowrocket 客户端导入 `50` 输出的订阅 URL，刷新订阅并实际连接；确认订阅通过 HTTPS 下载、443 节点可用。启用了备用入口时，再单独测试 24443。检查 DNS、IPv6、WebRTC 和 AI 服务路由可参考 [客户端防泄漏检查](client-leak-check.md)。

## 出错时先看哪里

| 现象 | 优先检查 |
| --- | --- |
| 新账号无法 SSH 登录 | 保留的初始会话、服务商控制台、公钥和 `authorized_keys` 权限、`SSH_PORT`、服务商安全组、UFW。 |
| `30` 提示配置已存在 | 这是覆盖保护；先确认是否为新机器或已有 Xray，不要直接强制覆盖。 |
| 443 可监听但客户端连不上 | 服务商安全组、UFW、客户端 IP/端口、UUID、REALITY 公钥、SNI、短 ID。 |
| `50` 证书申请失败 | 域名 A 记录、80/TCP 公网可达性、Nginx 端口占用、证书服务返回的具体错误。 |
| 订阅 URL 访问失败 | `kai-subscription`、Nginx、8443/TCP、证书和 URL 中的完整令牌。 |

完成后妥善备份服务器上的运行时配置和密钥。以后只更新客户端订阅模板时，按 [原部署说明](deployment.md)中的单模块更新步骤操作，不要重跑全部脚本。
