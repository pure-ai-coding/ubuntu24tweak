#!/usr/bin/env bash
set -euo pipefail

PKG="aic8800d80fdrvpackage"
POSTINST="/var/lib/dpkg/info/${PKG}.postinst"

if [[ "${EUID}" -ne 0 ]]; then
    exec sudo "$0" "$@"
fi

if [[ ! -e "$POSTINST" ]]; then
    echo "Missing dpkg maintainer script: $POSTINST" >&2
    exit 1
fi

KVER="$(uname -r)"
MODDIR="/lib/modules/${KVER}/kernel/drivers/net/wireless/aic8800"
LOAD_FW="${MODDIR}/aic_load_fw.ko"
FDRV="${MODDIR}/aic8800_fdrv.ko"

if [[ ! -e "$LOAD_FW" || ! -e "$FDRV" ]]; then
    echo "AIC8800 modules are not installed under $MODDIR." >&2
    echo "Run scripts/mercury-aic8800-rebuild-install.sh first." >&2
    exit 1
fi

if ! modinfo "$FDRV" 2>/dev/null | grep -qi 'v2357p014B'; then
    echo "Installed aic8800_fdrv.ko does not contain alias 2357:014b." >&2
    echo "Run scripts/mercury-aic8800-rebuild-install.sh first." >&2
    exit 1
fi

backup="${POSTINST}.bak.$(date +%Y%m%d%H%M%S)"
cp -a "$POSTINST" "$backup"
echo "Backed up original postinst to $backup"

cat >"$POSTINST" <<'EOF'
#!/bin/bash
set -e

# The vendor postinst uses insmod and fails when modules are already loaded:
#   insmod: ERROR: could not insert module ...: File exists
# Keep this script idempotent so dpkg can finish configuring the package.
KVER="$(uname -r)"
depmod -a "$KVER" || true
modprobe cfg80211 || true
modprobe aic_load_fw || true
modprobe aic8800_fdrv || true
exit 0
EOF
chmod 0755 "$POSTINST"

dpkg --configure "$PKG"

echo
dpkg -s "$PKG" | sed -n '1,20p'
echo
lsmod | grep -E '(^aic_load_fw|^aic8800_fdrv|^cfg80211)' || true
echo
nmcli device status 2>/dev/null || true
