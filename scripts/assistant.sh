#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib/common.sh"

LOG_FILE=$(panepilot_log_path assistant)
SELF_CMD=${PANEPILOT_ENTRYPOINT:-$0}

wait_ready() {
  require_command tmux

  local timeout="${1:-$PANEPILOT_READY_TIMEOUT_SECONDS}"
  local started_at now state
  started_at=$(date +%s)

  while true; do
    state=$(panepilot_health_state)
    if panepilot_state_is_healthy "$state"; then
      printf 'state=%s\n' "$state"
      return 0
    fi

    if [[ "$state" == "stopped" || "$state" == "dead" || "$state" == "error" ]]; then
      printf 'state=%s\n' "$state" >&2
      return 1
    fi

    now=$(date +%s)
    if (( now - started_at >= timeout )); then
      printf 'Timed out waiting for ready state after %ss (last_state=%s)\n' "$timeout" "$state" >&2
      return 1
    fi

    sleep "$PANEPILOT_READY_POLL_INTERVAL_SECONDS"
  done
}

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
  panepilot_mark_session_metadata "$PANEPILOT_SESSION"
  sleep 2

  if [[ "$PANEPILOT_WAIT_FOR_READY" == "1" ]]; then
    wait_ready "$PANEPILOT_READY_TIMEOUT_SECONDS" >/dev/null
  fi

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

restart_if_unhealthy() {
  local state
  state=$(panepilot_health_state)

  if panepilot_state_is_healthy "$state"; then
    printf 'Session already healthy: %s (%s)\n' "$PANEPILOT_SESSION" "$state"
    return 0
  fi

  printf 'Restarting unhealthy session: %s (%s)\n' "$PANEPILOT_SESSION" "$state"
  stop >/dev/null 2>&1 || true
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

  local state
  state=$(panepilot_health_state)

  if panepilot_has_session; then
    printf '%s\n' "$state"
    printf 'session=%s\n' "$PANEPILOT_SESSION"
    printf 'work_dir=%s\n' "$PANEPILOT_WORK_DIR"
    printf 'agent_cmd=%s\n' "$PANEPILOT_AGENT_CMD"
    if [[ -n "$PANEPILOT_AGENT_ENV_FILE" ]]; then
      printf 'agent_env_file=%s\n' "$PANEPILOT_AGENT_ENV_FILE"
    fi
    if [[ -n "$PANEPILOT_PROCESS_REGEX" ]]; then
      printf 'process_regex=%s\n' "$PANEPILOT_PROCESS_REGEX"
    fi
    if [[ -n "$PANEPILOT_READY_REGEX" ]]; then
      printf 'ready_regex=%s\n' "$PANEPILOT_READY_REGEX"
    fi
    if [[ -n "$PANEPILOT_ERROR_REGEX" ]]; then
      printf 'error_regex=%s\n' "$PANEPILOT_ERROR_REGEX"
    fi
    printf 'current_command=%s\n' "$(panepilot_pane_current_command)"
    printf 'log_dir=%s\n' "$PANEPILOT_LOG_DIR"
  else
    printf '%s\n' "$state"
    printf 'session=%s\n' "$PANEPILOT_SESSION"
  fi
}

health() {
  require_command tmux

  local state
  state=$(panepilot_health_state)
  printf 'state=%s\n' "$state"
  printf 'session=%s\n' "$PANEPILOT_SESSION"

  if ! panepilot_has_session; then
    return 0
  fi

  printf 'pane_dead=%s\n' "$(panepilot_pane_dead)"
  printf 'current_command=%s\n' "$(panepilot_pane_current_command)"
  printf 'start_command=%s\n' "$(panepilot_pane_start_command)"
}

list_sessions() {
  require_command tmux

  printf 'session\tstate\tcurrent_command\twork_dir\n'
  panepilot_list_managed_sessions

  if panepilot_has_session && [[ "$(panepilot_session_option "$PANEPILOT_SESSION" "@panepilot_managed")" != "1" ]]; then
    printf '%s\t%s\t%s\t%s\n' \
      "$PANEPILOT_SESSION" \
      "$(panepilot_health_state)" \
      "$(panepilot_pane_current_command)" \
      "$PANEPILOT_WORK_DIR"
  fi
}

doctor() {
  local failures=0
  local agent_program state

  printf 'config_file=%s\n' "$CONFIG_FILE"

  if command -v tmux >/dev/null 2>&1; then
    printf 'check_tmux=ok\n'
  else
    printf 'check_tmux=missing\n'
    failures=$((failures + 1))
  fi

  if [[ -f "$CONFIG_FILE" ]]; then
    printf 'check_config_file=ok\n'
  else
    printf 'check_config_file=missing\n'
    failures=$((failures + 1))
  fi

  if [[ -d "$PANEPILOT_WORK_DIR" ]]; then
    printf 'check_work_dir=ok\n'
  else
    printf 'check_work_dir=missing\n'
    failures=$((failures + 1))
  fi

  agent_program=$(panepilot_agent_program)
  if [[ -n "$agent_program" ]] && command -v "$agent_program" >/dev/null 2>&1; then
    printf 'check_agent_command=ok\n'
  else
    printf 'check_agent_command=missing\n'
    failures=$((failures + 1))
  fi

  if [[ -n "$PANEPILOT_AGENT_ENV_FILE" ]]; then
    if [[ -r "$PANEPILOT_AGENT_ENV_FILE" ]]; then
      printf 'check_agent_env_file=ok\n'
    else
      printf 'check_agent_env_file=missing\n'
      failures=$((failures + 1))
    fi
  else
    printf 'check_agent_env_file=not_set\n'
  fi

  state=$(panepilot_health_state)
  printf 'session_state=%s\n' "$state"
  if panepilot_state_is_healthy "$state"; then
    printf 'check_session_health=ok\n'
  else
    printf 'check_session_health=fail\n'
    failures=$((failures + 1))
  fi
  if panepilot_has_session; then
    printf 'current_command=%s\n' "$(panepilot_pane_current_command)"
  fi

  if (( failures > 0 )); then
    printf 'doctor=fail (%s issue(s))\n' "$failures" >&2
    return 1
  fi

  printf 'doctor=ok\n'
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
process_regex=$PANEPILOT_PROCESS_REGEX
ready_regex=$PANEPILOT_READY_REGEX
error_regex=$PANEPILOT_ERROR_REGEX
wait_for_ready=$PANEPILOT_WAIT_FOR_READY
ready_timeout_seconds=$PANEPILOT_READY_TIMEOUT_SECONDS
ready_poll_interval_seconds=$PANEPILOT_READY_POLL_INTERVAL_SECONDS
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
  restart-if-unhealthy
  attach
  status
  health
  list
  doctor
  wait-ready [seconds]
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
  restart-if-unhealthy) restart_if_unhealthy ;;
  attach) attach ;;
  status) status ;;
  health) health ;;
  list) list_sessions ;;
  doctor) doctor ;;
  wait-ready) shift; wait_ready "${1:-}" ;;
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
