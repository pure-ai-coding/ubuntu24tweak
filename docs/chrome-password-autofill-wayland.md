# Chrome 在原生 Wayland 下不弹「已保存账号」下拉

## 现象

GNOME Wayland 会话，Chrome 点用户名/密码输入框时，不再自动弹出已保存账号的
autofill 下拉，必须手动输入。规律：测试右键优化（见 `vscode-keybindings.md`
同期的右键条目）切 X11 后端时能弹，切回原生 Wayland 后不弹。

## 诊断

逐项排除「密码丢失/读不出」这一类原因，确认都正常：

| 检查 | 结果 |
|---|---|
| 会话类型 | `wayland` |
| Chrome 后端 | 原生 Wayland（进程有 `wayland-cursor` memfd、无 X11 socket、不在 XWayland 客户端名单） |
| gnome-keyring | 在运行 `--components=pkcs11,secrets`（密钥服务在线，能解密） |
| 密码管理器开关 | Preferences 全默认（保存密码/自动登录均开启） |
| 密码 | 已存（用户日常要用） |
| Chrome 版本 | 149.0.7827.155，apt 无更新可升 |

关键证据：Chrome 二进制里有字符串 **`Failed to create XdgPopup`**。

**根因**：原生 Wayland 后端下，Chrome 把气泡/下拉（含 autofill 下拉）做成 Wayland
的 xdg-popup，创建失败 → 下拉不渲染。X11(XWayland) 后端走另一套 popup 机制，所以能弹。

这与右键优化条目的结论死锁：那一项主动选择原生 Wayland（`--ozone-platform=x11`
会连累 fcitx 中文输入与 HiDPI），而原生 Wayland 恰恰就是这里出问题的环境。Chrome
自带 autofill 在本机无法同时满足「原生 Wayland + 自动弹下拉」。

## 解法（无损，保留原生 Wayland）

启动参数加：

```
--disable-features=OzoneBubblesUsePlatformWidgets
```

`OzoneBubblesUsePlatformWidgets` 控制 Ozone 气泡/弹层是否用「平台原生 widget」
（即 Wayland 的 xdg-popup）。关掉后，气泡/下拉改用浏览器窗口内渲染，绕开创建失败的
xdg-popup 路径，下拉恢复；且不切后端，原生 Wayland、右键、中文输入、HiDPI 全不受影响。

实测：加该 flag 后下拉正常弹出。

## 固化

google-chrome 的包装脚本 `/opt/google/chrome/google-chrome` 不读任何用户 flags 文件，
所以固化在**用户级 desktop 覆盖**：

```
~/.local/share/applications/google-chrome.desktop
```

从系统模板 `/usr/share/applications/google-chrome.desktop` 复制一份，给三处 `Exec`
（主入口 `%U`、新建窗口、无痕窗口）都插入该 flag：

```
Exec=/usr/bin/google-chrome-stable --disable-features=OzoneBubblesUsePlatformWidgets %U
Exec=/usr/bin/google-chrome-stable --disable-features=OzoneBubblesUsePlatformWidgets
Exec=/usr/bin/google-chrome-stable --disable-features=OzoneBubblesUsePlatformWidgets --incognito
```

用户级覆盖优先于系统文件、不怕 Chrome 升级覆盖、覆盖 Dock 启动 + 点链接打开 +
右键动作全部入口。改完 `update-desktop-database ~/.local/share/applications`，
重启 Chrome（从 Dock 正常启动）即生效。

## 被否方案

- **整体切 X11**：密码恢复，但重新引入 fcitx/HiDPI 问题，推翻右键优化条目的成果。
- **升级 Chrome**：已是最新 149.0.7827.155，无更新。
- **Bitwarden / KeePassXC 扩展**（备选，未采用）：扩展自带填充 UI，不依赖 Chrome
  原生浮层，同样能绕开本 bug 并保留原生 Wayland；但需把现有密码导出再导入一次。
  本次 flag 方案更轻、零迁移，故优先。
