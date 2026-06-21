# FRP SSH tunnel

Goal: expose this machine's SSH service through a public relay server with FRP.

This document intentionally uses placeholders. Do not commit real domains, IPs,
passwords, tokens, or private keys.

## Topology

```text
external client -> <SERVER_DOMAIN>:<REMOTE_SSH_PORT> -> frps -> frpc -> 127.0.0.1:22
```

Current chosen shape:

- Server side: `frps` runs as a systemd service on `<SERVER_DOMAIN>`.
- Local side: `frpc` runs as a user systemd service.
- Local source IP may change; this is fine because `frpc` dials out to `frps`.
- Login method is password login first. Switch to SSH keys later.

## Server

`frps` is managed by:

```bash
systemctl status frps
systemctl restart frps
journalctl -u frps -f
```

The server security group/firewall must allow:

- `<FRPS_BIND_PORT>` for frpc connections
- `<REMOTE_SSH_PORT>` for external SSH clients

## Local machine

The local `frpc` user service is managed by:

```bash
systemctl --user status frpc
systemctl --user restart frpc
journalctl --user -u frpc -f
```

User lingering should be enabled so the user service can run without an active
desktop login:

```bash
loginctl show-user "$USER" -p Linger
```

Install and enable the local SSH server:

```bash
./scripts/frp-ssh-tunnel-local-prereq.sh
```

After that, connect from outside with:

```bash
ssh <LOCAL_USER>@<SERVER_DOMAIN> -p <REMOTE_SSH_PORT>
```

## Hardening checklist

- Use a strong local account password while password login is enabled.
- After key login works, set `PasswordAuthentication no`.
- Add FRP authentication token on both `frps` and `frpc`.
- Keep `<REMOTE_SSH_PORT>` non-standard.
