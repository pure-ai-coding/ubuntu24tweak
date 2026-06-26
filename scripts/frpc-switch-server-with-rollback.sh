#!/usr/bin/env bash
set -euo pipefail

old_server="${1:-${OLD_FRPC_SERVER:-}}"
new_server="${2:-${NEW_FRPC_SERVER:-}}"
server_port="${3:-${FRPC_SERVER_PORT:-}}"
ssh_user="${4:-${FRPC_SSH_USER:-}}"
ssh_port="${5:-${FRPC_SSH_PORT:-}}"

config="${FRPC_CONFIG:-$HOME/.config/frp/frpc.toml}"
log_dir="${XDG_CACHE_HOME:-$HOME/.cache}/ubuntu24tweak"
mkdir -p "$log_dir"
log_file="$log_dir/frpc-switch-$(date +%Y%m%d-%H%M%S).log"
backup="${config}.bak.$(date +%Y%m%d-%H%M%S)"

exec > >(tee -a "$log_file") 2>&1

log() {
  printf '[%s] %s\n' "$(date '+%F %T')" "$*"
}

usage() {
  cat <<'EOF'
Usage:
  frpc-switch-server-with-rollback.sh OLD_SERVER NEW_SERVER FRP_PORT SSH_USER SSH_PORT

Or set:
  OLD_FRPC_SERVER NEW_FRPC_SERVER FRPC_SERVER_PORT FRPC_SSH_USER FRPC_SSH_PORT
EOF
}

set_server() {
  local server="$1"
  perl -0pi -e 's/^serverAddr\s*=\s*".*"/serverAddr = "'"$server"'"/m' "$config"
}

rollback() {
  log "Rolling back frpc config to $old_server"
  set_server "$old_server"
  systemctl --user restart frpc
  sleep 2
  systemctl --user is-active frpc || true
}

require_file() {
  if [[ ! -f "$1" ]]; then
    log "Missing required file: $1"
    exit 1
  fi
}

wait_for_frpc_success() {
  local since="$1"
  local deadline=$((SECONDS + 20))
  while (( SECONDS < deadline )); do
    if journalctl --user -u frpc --since "$since" --no-pager \
      | grep -qE 'login to server success|start proxy success'; then
      return 0
    fi
    sleep 1
  done
  return 1
}

test_ssh_tunnel() {
  local output
  set +e
  output=$(
    ssh \
      -p "$ssh_port" \
      -o BatchMode=yes \
      -o PasswordAuthentication=no \
      -o KbdInteractiveAuthentication=no \
      -o ConnectTimeout=8 \
      -o ConnectionAttempts=1 \
      -o StrictHostKeyChecking=accept-new \
      "${ssh_user}@${new_server}" true 2>&1
  )
  local rc=$?
  set -e

  printf '%s\n' "$output"

  if (( rc == 0 )); then
    return 0
  fi

  if grep -qE 'Permission denied|Authentications that can continue' <<<"$output"; then
    return 0
  fi

  return 1
}

main() {
  require_file "$config"

  if [[ -z "$old_server" || -z "$new_server" || -z "$server_port" || -z "$ssh_user" || -z "$ssh_port" ]]; then
    usage
    exit 2
  fi

  log "Log file: $log_file"
  log "Config: $config"
  log "Switching frpc server: $old_server -> $new_server"
  log "FRP server port: $server_port; SSH tunnel port: $ssh_port"

  cp -a "$config" "$backup"
  log "Backup created: $backup"

  if ! grep -qE '^serverAddr\s*=\s*"'"$old_server"'"' "$config"; then
    log "Current serverAddr is not $old_server; refusing to continue."
    exit 1
  fi

  set_server "$new_server"

  local since
  since="$(date '+%F %T')"
  log "Restarting user frpc service"
  systemctl --user restart frpc

  if ! systemctl --user is-active --quiet frpc; then
    log "frpc is not active after restart."
    rollback
    exit 1
  fi

  if ! wait_for_frpc_success "$since"; then
    log "frpc did not report successful login/proxy startup in time."
    journalctl --user -u frpc --since "$since" --no-pager || true
    rollback
    exit 1
  fi

  log "frpc reported successful startup against $new_server"

  if test_ssh_tunnel; then
    log "SSH tunnel test succeeded or reached authentication stage."
    log "Keeping new frpc server: $new_server"
    exit 0
  fi

  log "SSH tunnel test failed."
  rollback
  exit 1
}

main "$@"
