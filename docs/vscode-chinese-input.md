# VSCode 无法输入中文（fcitx5 / GNOME Wayland）

对应 TODO：vscode无法输入中文。

## 现象

VSCode 里打字无法弹出中文候选、输入法切不过去；其它部分应用可能也受影响。

## 根因

输入法**框架与环境变量不一致**：

- Ubuntu 24.04 GNOME 默认输入法是 **ibus**，所以系统环境变量是
  `XMODIFIERS=@im=ibus`、`QT_IM_MODULE=ibus`，且 `GTK_IM_MODULE` 未设置；
  `im-config` 仍是 `default`（=ibus）。
- 但实际运行的守护进程是 **fcitx5**（已安装 fcitx5-chinese-addons，配好了拼音/五笔）。
- 于是：守护进程是 fcitx5，环境变量却让应用去连 ibus，`GTK_IM_MODULE` 又为空
  → VSCode（Electron，走 XWayland）拿不到任何可用输入法。

### 一个必须知道的 GNOME Wayland 限制

GNOME 的 Mutter 只把 Wayland 文本输入协议接到**自带的 ibus**，**fcitx5 的 Wayland 前端在 GNOME 上不工作**。因此 fcitx5 要生效，应用必须：

- 走 **XWayland**（X11 前端 + `XMODIFIERS`），或
- 用 **GTK/Qt 输入模块**（`GTK_IM_MODULE=fcitx` / `QT_IM_MODULE=fcitx`，经 DBus 直连 fcitx5）。

VSCode（snap，启动项 `code --force-user-env`）默认走 XWayland 且继承用户环境，
所以只要把环境变量正确指向 fcitx 即可。

## 已做的修复

统一到 fcitx5，全部为用户级、可逆：

1. **systemd 用户环境** `~/.config/environment.d/im-fcitx5.conf`
   （GNOME Wayland 登录时加载）：
   ```ini
   GTK_IM_MODULE=fcitx
   QT_IM_MODULE=fcitx
   XMODIFIERS=@im=fcitx
   ```
2. **im-config** 切到 fcitx5：`im-config -n fcitx5`
   → 写入 `~/.xinputrc`（`run_im fcitx5`），覆盖 X11 会话登录路径。

fcitx5 本身已自启动（`/etc/xdg/autostart/org.fcitx.Fcitx5.desktop`）、拼音引擎已就绪，无需再动。

## 生效与验证

**必须登出再登入**（环境变量只在登录时导出，重启 VSCode 不够）。

登入后检查环境变量已指向 fcitx：
```bash
systemctl --user show-environment | grep -E "IM_MODULE|XMODIFIERS"
# 期望：GTK_IM_MODULE=fcitx  QT_IM_MODULE=fcitx  XMODIFIERS=@im=fcitx
```
然后打开 VSCode，在编辑器里按 `Ctrl+Space`（fcitx5 默认切换键）切到拼音试打中文。

## 排查：若登入后仍不行

1. **确认 VSCode 没跑成 Wayland 原生**（那样在 GNOME 上 fcitx5 够不着）：
   ```bash
   cat /proc/$(pgrep -f 'snap/code.*electron' | head -1)/cmdline | tr '\0' ' '
   ```
   若看到 `--ozone-platform=wayland`，强制它走 XWayland：复制桌面项到本地并加 `--ozone-platform=x11`：
   ```bash
   cp /var/lib/snapd/desktop/applications/code_code.desktop ~/.local/share/applications/
   # 编辑其中 Exec 行：code --force-user-env --ozone-platform=x11 %F
   ```
2. **确认 fcitx5 当前输入法组里有“拼音”**：运行 `fcitx5-configtool`，把“拼音”加入右侧已用列表，`Ctrl+Space` 才能切到它。
3. **fcitx5 没在跑**：`pgrep -a fcitx5`，无则 `fcitx5 -d &` 并确认自启动项存在。

## 还原

删除 `~/.config/environment.d/im-fcitx5.conf`，并 `im-config -n ibus`（或删 `~/.xinputrc`），登出登入即恢复 ibus。
