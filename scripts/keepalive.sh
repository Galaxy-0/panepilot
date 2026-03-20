#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib/common.sh"

PANEPILOT_SCRIPT="$SCRIPT_DIR/assistant.sh"
LOG_FILE=$(panepilot_log_path keepalive)
LAST_COMPACT_FILE="$PANEPILOT_LOG_DIR/last-compact"

check_alive() {
  tmux has-session -t "$PANEPILOT_SESSION" 2>/dev/null
}

need_compact() {
  if [[ ! -f "$LAST_COMPACT_FILE" ]]; then
    return 0
  fi

  local last now diff
  last=$(<"$LAST_COMPACT_FILE")
  now=$(date +%s)
  diff=$((now - last))
  [[ "$diff" -gt "$PANEPILOT_COMPACT_INTERVAL_SECONDS" ]]
}

do_compact() {
  panepilot_log "$LOG_FILE" "sending compact command"
  tmux send-keys -t "$PANEPILOT_SESSION" "$PANEPILOT_COMPACT_COMMAND" Enter
  date +%s > "$LAST_COMPACT_FILE"
  sleep 10
}

main() {
  require_command tmux
  ensure_panepilot_dirs
  panepilot_log "$LOG_FILE" "keepalive check"

  if check_alive; then
    panepilot_log "$LOG_FILE" "session is alive"
    if need_compact; then
      do_compact
    fi
    return 0
  fi

  panepilot_log "$LOG_FILE" "session missing, restarting"
  "$PANEPILOT_SCRIPT" start
  sleep 5
  "$PANEPILOT_SCRIPT" send "$PANEPILOT_RECOVERY_MESSAGE"
}

main
