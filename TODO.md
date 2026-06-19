[x] 终端鼠标右键复制粘贴：若有选中文本，则复制；若无且有光标，则粘贴 @done(2026-06-19)
    GNOME Terminal/VTE 做不到（右键菜单写死，Wayland 也无法全局拦截鼠标）；改用 WezTerm。
    ~/.config/wezterm/wezterm.lua：智能右键（选中→复制并清选区/否则粘贴）、不做选中即复制、
    仿 Windows Terminal 拆 pane（Ctrl+Shift+E/O 分屏，Alt+方向切焦点，Ctrl+Shift+方向调大小）。
    设默认：gsettings 已设；还需手动 sudo update-alternatives --set x-terminal-emulator /usr/bin/open-wezterm-here。
    tmux 远程仍用；其 mouse on 会截获鼠标，按 Shift 绕过。详见 docs/wezterm.md
[ ] 类windows的文件管理器，左侧树形结构、支持自动展开，右侧本目录下的子目录、文件列表；支持双侧同时显示、联动显示，一侧本地，一侧sftp（sftp可共享终端中的免密登录或能永久记住密码）
[ ] chrome浏览器右键优化，现在需要连点两次才有效，可能是跟右键手势插件有关系
[ ] 现系统登出待登入时，桌面花屏、闪烁、部分区域可见登出前窗口部分内容；按回车、盲输密码、回车，可进入系统，进入后恢复正常
[ ] 华为备忘录(笔记)同步
[ ] 语音输入法：~/funasr_input_linux
[x] 任务栏同一应用多窗口，hover 时显示缩略图或平铺 @done(2026-06-19)
    现状：Ubuntu Dock 原生不支持 hover 触发缩略图。当前配置下——
    · 右键点击图标弹出菜单，菜单内含各窗口的缩略图，点缩略图可跳转到对应窗口；
    · 左键保留 minimize（不弹缩略图）。
    相关设置：show-windows-preview=true, default-windows-preview-to-open=true, click-action='minimize'
    备选：左键也弹缩略图可设 click-action='previews'（或 'focus-or-previews'）；真正鼠标悬停弹出需改用 Dash to Panel。
[x] ~/popular-fonts 安装这些字体 @done(2026-06-19)
    复制到 ~/.local/share/fonts/popular-fonts/ 并 fc-cache 刷新；313 个字体（6 个重复基础字体已跳过）
[x] “文件”应用有个绿色1角标，不知道是什么情况 @done(2026-06-19)
    是 Ubuntu Dock 的通知计数徽章（show-icons-notifications-counter），对应一条未读系统通知，点开/清除后即消失
[x] vscode快捷键：复制行 alt+shift+up/down，删除行 ctrl+d，console.log ctrl+l(extension?) @done(2026-06-19)
    keybindings.json 改绑复制行/删除行；console.log 用 Turbo Console Log 扩展（默认 Ctrl+Alt+L）；见 docs/vscode-keybindings.md
[x] 复制文本/图片后，F3贴在桌面上，右键可重新复制，双击可销毁，拖动可移动，滚动可缩放 @done(2026-06-19)
[x] vscode无法输入中文 @done(2026-06-19)
    统一到 fcitx5（environment.d + im-config），需登出登入生效；见 docs/vscode-chinese-input.md
[x] 列出系统所有注册的热键，哪个应用使用的，显示有无冲突 @done(2026-06-19)
    见 list-hotkeys/（脚本 + hotkeys.md/json + 说明）