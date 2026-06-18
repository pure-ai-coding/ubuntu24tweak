#!/bin/bash

# 任务栏图标点击最小化
# 适用于 Ubuntu 24.04 with GNOME

SCHEMA="org.gnome.shell.extensions.dash-to-dock"
KEY="click-action"

if ! gsettings writable "$SCHEMA" "$KEY" 2>/dev/null; then
    echo "错误: 无法访问 $SCHEMA (Dash-to-Dock 扩展未安装或冲突)"
    echo "如果使用 Dash-to-Panel，请运行:"
    echo "  gsettings set org.gnome.shell.extensions.dash-to-panel click-action 'minimize'"
    exit 1
fi

gsettings set "$SCHEMA" "$KEY" 'minimize'

echo "已设置: 点击任务栏图标 -> 最小化窗口"
echo "选项: 'minimize' (最小化) / 'minimize-or-previews' (最小化或预览) / 'previews' (仅预览)"
