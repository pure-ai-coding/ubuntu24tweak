# OpenClaw migration record

Date: 2026-06-26

## Scope

- Migrated OpenClaw from a remote root account to local user `ztj`.
- Copied runtime data to local home directories. Copied OpenClaw runtime data is not stored in this git repository.
- Copied:
  - remote `~/.openclaw/` -> local `~/.openclaw/`
  - remote `~/vault/` -> local `~/vault/`
  - remote `~/PDF/` -> local `~/PDF/`
- Excluded the remote `~/workspace` directory entirely because those projects are separately available from their upstream repositories.
- Excluded large OpenClaw workspace GitHub research clones from the OpenClaw data copy.

## Remote handling

- Stopped and disabled the remote root user `openclaw-gateway.service`.
- Verified the remote OpenClaw gateway service was inactive afterward.
- Verified the remote gateway port was not listening afterward.
- No server reboot was performed.
- The remote `openclaw --tui` command may still run manually because it is a CLI/TUI program; this does not mean the remote gateway service is active.

## Local setup

- Installed local `openclaw@2026.6.1`.
- Updated `agents.defaults.workspace` from the remote root path to the local path:
  - `~/.openclaw/workspace`
- Reinstalled and enabled the local OpenClaw plugins required by the migrated config:
  - `qqbot`
  - `brave`
  - `openclaw-weixin`
- Installed and started the local user systemd service `openclaw-gateway.service`.

## Verification

- Local copied sizes:
  - `~/.openclaw`: 487M, 10123 files
  - `~/vault`: 19M, 591 files
  - `~/PDF`: 9.0M, 10 files
- Local OpenClaw config validation passed.
- Local gateway status:
  - service enabled and running
  - version `2026.6.1`
  - listening on loopback port `18789`
  - connectivity probe OK
  - capability `admin-capable`
- Channel verification:
  - QQ Bot default: enabled, configured, running, connected
- User confirmed QQ is connected to the local OpenClaw instance.

## Post-migration path fix

- Fixed local migrated session metadata that still referenced the remote root session directory.
- Updated local session index and runtime path metadata from the remote root OpenClaw path to the local `~/.openclaw` path.
- Backups were written next to the edited local metadata files with timestamped `.bak.*` suffixes.
- Verification after the fix:
  - session metadata references to the remote root session directory: 0
  - `exec-approvals.json` references to the remote root OpenClaw path: 0
  - short TUI startup check: no `EACCES` and no remote root session path reference
  - QQ Bot default remained enabled, configured, running, and connected

## Notes

- Raw implementation logs and copied OpenClaw data remain outside this git repository.
- The copied runtime configuration may contain tokens, API keys, client secrets, and session/state data; those files must not be committed.
- Historical notes and archived session data may still contain old remote paths as archival content. Active OpenClaw workspace and session metadata were changed to local user paths.
- OpenClaw reports a non-blocking warning about migrated shared SQLite plugin metadata conflicts for `brave`, `openclaw-weixin`, and `qqbot`; the plugins are installed/enabled and the gateway is running.
