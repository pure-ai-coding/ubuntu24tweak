# Mihomo TUN 模式配置

将 mihomo 从 mixed-port 代理模式切换为 TUN 透明代理模式。

## 配置变更

在 `/etc/mihomo/config.yaml` 中添加：

```yaml
tun:
  enable: true
  stack: system
  auto-route: true
  auto-detect-interface: true
  dns-hijack:
    - "any:53"

dns:
  enable: true
  listen: 0.0.0.0:53
  default-nameserver:
    - 223.5.5.5
  nameserver:
    - 223.5.5.5
    - 119.29.29.29
```

### 注意

- `dns-hijack` 的值必须是 YAML 字符串 `"any:53"`，带引号，否则会被解析为映射导致配置错误
- 启用 `dns-hijack` 后必须同步配置 `dns` 节，否则 DNS 无法解析

## 重启服务

```bash
sudo systemctl restart mihomo
```

## 验证

```bash
ip addr show Meta          # 应看到 TUN 网卡，IP 198.18.0.1/30
ip route show table 2022   # 应有 default via 198.18.0.2
curl -sS -o /dev/null -w "%{http_code}" https://www.baidu.com   # 应返回 200
```

## 清除原有代理设置

TUN 模式接管全部流量后，应清除所有显式代理设置避免重复代理。

### GNOME 系统代理

```bash
gsettings set org.gnome.system.proxy mode 'none'
```

### 环境变量

从 `~/.bashrc`（或 `~/.zshrc`）中删除 `http_proxy`、`https_proxy`、`all_proxy` 等 export 行。

### npm

```bash
npm config delete proxy
npm config delete https-proxy
sudo npm config --global delete proxy
sudo npm config --global delete https-proxy
```

### git / apt

```bash
git config --global --unset http.proxy
git config --global --unset https.proxy
# 检查 /etc/apt/apt.conf.d/ 下是否有 proxy 配置
```

## 恢复

```bash
sudo cp /etc/mihomo/config.yaml.bak /etc/mihomo/config.yaml
sudo systemctl restart mihomo
```

恢复 `~/.bashrc` 中的代理环境变量并 `source ~/.bashrc` 即可回到 mixed-port 模式。
