#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib/common.sh"

LOG_FILE=$(panepilot_log_path assistant)
SELF_CMD=${PANEPILOT_ENTRYPOINT:-$0}

start() {
  require_command tmux

  if tmux has-session -t "$PANEPILOT_SESSION" 2>/dev/null; then
    printf 'Session already running: %s\n' "$PANEPILOT_SESSION"
    return 0
  fi

  local agent_program
  agent_program=$(panepilot_agent_program)
  if [[ -z "$agent_program" ]] || ! command -v "$agent_program" >/dev/null 2>&1; then
    printf 'Agent command not found: %s\n' "$PANEPILOT_AGENT_CMD" >&2
    printf 'Set PANEPILOT_AGENT_CMD in %s\n' "$CONFIG_FILE" >&2
    exit 1
  fi

  if [[ -n "$PANEPILOT_AGENT_ENV_FILE" ]]; then
    require_readable_file "$PANEPILOT_AGENT_ENV_FILE"
  fi

  if [[ ! -d "$PANEPILOT_WORK_DIR" ]]; then
    printf 'Working directory does not exist: %s\n' "$PANEPILOT_WORK_DIR" >&2
    exit 1
  fi

  local launch_command
  launch_command=$(panepilot_agent_launch_command)
  ensure_panepilot_dirs
  tmux new-session -d -s "$PANEPILOT_SESSION" -c "$PANEPILOT_WORK_DIR" "$launch_command"
  sleep 2
  printf 'Started session: %s\n' "$PANEPILOT_SESSION"
  printf 'Attach with: %s attach\n' "$SELF_CMD"
  panepilot_log "$LOG_FILE" "started session"
}

stop() {
  require_command tmux

  if tmux has-session -t "$PANEPILOT_SESSION" 2>/dev/null; then
    tmux kill-session -t "$PANEPILOT_SESSION"
    printf 'Stopped session: %s\n' "$PANEPILOT_SESSION"
    panepilot_log "$LOG_FILE" "stopped session"
  else
    printf 'Session not running: %s\n' "$PANEPILOT_SESSION"
  fi
}

restart() {
  stop
  start
}

attach() {
  require_command tmux

  if tmux has-session -t "$PANEPILOT_SESSION" 2>/dev/null; then
    tmux attach -t "$PANEPILOT_SESSION"
  else
    printf 'Session not running. Start it first with: %s start\n' "$SELF_CMD" >&2
    exit 1
  fi
}

status() {
  require_command tmux

  if tmux has-session -t "$PANEPILOT_SESSION" 2>/dev/null; then
    printf 'running\n'
    printf 'session=%s\n' "$PANEPILOT_SESSION"
    printf 'work_dir=%s\n' "$PANEPILOT_WORK_DIR"
    printf 'agent_cmd=%s\n' "$PANEPILOT_AGENT_CMD"
    if [[ -n "$PANEPILOT_AGENT_ENV_FILE" ]]; then
      printf 'agent_env_file=%s\n' "$PANEPILOT_AGENT_ENV_FILE"
    fi
    printf 'log_dir=%s\n' "$PANEPILOT_LOG_DIR"
  else
    printf 'stopped\n'
    printf 'session=%s\n' "$PANEPILOT_SESSION"
  fi
}

send() {
  require_command tmux

  local message="${*:-}"
  if [[ -z "$message" ]]; then
    printf 'Usage: %s send <message>\n' "$SELF_CMD" >&2
    exit 1
  fi

  if ! tmux has-session -t "$PANEPILOT_SESSION" 2>/dev/null; then
    start
    sleep 3
  fi

  tmux send-keys -t "$PANEPILOT_SESSION" "$message" Enter
  printf 'Sent task to %s\n' "$PANEPILOT_SESSION"
  panepilot_log "$LOG_FILE" "sent task: $message"
}

capture() {
  require_command tmux

  local lines="${1:-$PANEPILOT_CAPTURE_LINES}"
  if ! tmux has-session -t "$PANEPILOT_SESSION" 2>/dev/null; then
    printf 'Session not running: %s\n' "$PANEPILOT_SESSION" >&2
    exit 1
  fi

  tmux capture-pane -pt "$PANEPILOT_SESSION:0" -S "-$lines"
}

logs() {
  local component="${1:-assistant}"
  local lines="${2:-40}"
  local logfile
  logfile=$(panepilot_log_path "$component")

  if [[ ! -f "$logfile" ]]; then
    printf 'Log file not found: %s\n' "$logfile" >&2
    exit 1
  fi

  tail -n "$lines" "$logfile"
}

send_file() {
  local file="${1:-}"
  if [[ -z "$file" ]]; then
    printf 'Usage: %s send-file <file>\n' "$SELF_CMD" >&2
    exit 1
  fi
  if [[ ! -f "$file" ]]; then
    printf 'Task file not found: %s\n' "$file" >&2
    exit 1
  fi

  local content
  content=$(<"$file")
  send "$content"
}

show_config() {
  cat <<EOF
config_file=$CONFIG_FILE
session=$PANEPILOT_SESSION
work_dir=$PANEPILOT_WORK_DIR
agent_cmd=$PANEPILOT_AGENT_CMD
agent_env_file=$PANEPILOT_AGENT_ENV_FILE
agent_prelude=$PANEPILOT_AGENT_PRELUDE
agent_shell=$PANEPILOT_AGENT_SHELL
log_dir=$PANEPILOT_LOG_DIR
task_file=$PANEPILOT_TASK_FILE
compact_interval_seconds=$PANEPILOT_COMPACT_INTERVAL_SECONDS
compact_command=$PANEPILOT_COMPACT_COMMAND
capture_lines=$PANEPILOT_CAPTURE_LINES
EOF
}

help() {
  cat <<EOF
Usage: $SELF_CMD <command>

Commands:
  start
  stop
  restart
  attach
  status
  capture [lines]
  logs [component] [lines]
  send <message>
  send-file <file>
  config
  help
EOF
}

case "${1:-}" in
  start) start ;;
  stop) stop ;;
  restart) restart ;;
  attach) attach ;;
  status) status ;;
  capture) shift; capture "${1:-}" ;;
  logs) shift; logs "${1:-}" "${2:-}" ;;
  send) shift; send "$@" ;;
  send-file) shift; send_file "${1:-}" ;;
  config) show_config ;;
  help|--help|-h) help ;;
  "") status ;;
  *)
    printf 'Unknown command: %s\n' "${1:-}" >&2
    help >&2
    exit 1
    ;;
esac
