#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  exec sudo -- "$0" "$@"
fi

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y openssh-server

install -d -m 0755 /etc/ssh/sshd_config.d
cat >/etc/ssh/sshd_config.d/50-ubuntu24tweak-password-login.conf <<'EOF'
# Temporary policy for the FRP SSH tunnel.
# Switch PasswordAuthentication to "no" after key-based login is ready.
PasswordAuthentication yes
KbdInteractiveAuthentication yes
UsePAM yes
EOF

systemctl enable --now ssh
systemctl restart ssh

ss -lntp | grep -E ':(22)\b' || true
systemctl --no-pager --full status ssh
