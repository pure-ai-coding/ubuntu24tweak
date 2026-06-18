#!/bin/bash
# 输入法快捷键改为 Windows 风格
# Ctrl+Space 切换中/英, Ctrl+Shift 切换输入法, 左右 Shift 临时切换中/英

CONFIG="$HOME/.config/fcitx5/config"

echo "=== 输入法快捷键优化 (fcitx5) ==="

if ! command -v fcitx5 &>/dev/null; then
    echo "错误: fcitx5 未安装"
    echo "请运行: sudo apt install fcitx5 fcitx5-chinese-addons"
    exit 1
fi

if [ ! -f "$CONFIG" ]; then
    echo "未找到 fcitx5 配置文件，请先运行 fcitx5 后再执行此脚本"
    exit 1
fi

cp "$CONFIG" "$CONFIG.bak.$(date +%Y%m%d%H%M%S)"

python3 <<'PYEOF'
import configparser, os

CONFIG = os.path.expanduser("~/.config/fcitx5/config")
conf = configparser.ConfigParser()
conf.optionxform = str
conf.read(CONFIG)

# [1] TriggerKeys: 只保留 Control+space (移除日文/韩文触发键)
sec = conf["Hotkey/TriggerKeys"]
for k in list(sec.keys()):
    if k != "0" and sec[k] in ("Zenkaku_Hankaku", "Hangul"):
        del sec[k]

# [2] Ctrl+Shift 切换输入法
conf["Hotkey/EnumerateForwardKeys"] = {"0": "Control+Shift_L"}
conf["Hotkey/EnumerateBackwardKeys"] = {"0": "Control+Shift_R"}
conf["Hotkey"]["EnumerateWithTriggerKeys"] = "False"

# [3] 左右 Shift 临时切换中/英 (按住时切换到第一个输入法)
conf["Hotkey/AltTriggerKeys"] = {"0": "Shift_L", "1": "Shift_R"}

with open(CONFIG, "w") as f:
    conf.write(f)

print("配置已写入:", CONFIG)
PYEOF

fcitx5-remote -r

cat <<'EOF'

=== 设置完成 ===
快捷键规则:
  Ctrl+Space        中/英切换
  Ctrl+Shift(左)    下一个输入法
  Ctrl+Shift(右)    上一个输入法
  按住 Shift        临时切换到英文，松开回到中文

配置备份: ~/.config/fcitx5/config.bak.*
如未生效，请注销后重新登录。
EOF
