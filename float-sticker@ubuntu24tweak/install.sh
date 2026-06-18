#!/bin/bash
set -e

EXT_DIR="$HOME/.local/share/gnome-shell/extensions/float-sticker@ubuntu24tweak"
SRC_DIR="$(dirname "$0")"

echo "==> Installing Float Sticker extension..."

rm -rf "$EXT_DIR"
mkdir -p "$EXT_DIR"

cp "$SRC_DIR/metadata.json" "$EXT_DIR/"
cp "$SRC_DIR/extension.js" "$EXT_DIR/"
cp -r "$SRC_DIR/schemas" "$EXT_DIR/"

glib-compile-schemas "$EXT_DIR/schemas/"

echo "==> Done. Restart GNOME Shell to activate (Alt+F2 → r, or logout/login)."
echo "==> Shortcut: F3 (change in Settings → Keyboard → Keyboard Shortcuts)"
