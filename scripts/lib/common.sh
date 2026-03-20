#!/usr/bin/env bash

COMMON_LIB_DIR=$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd -- "$COMMON_LIB_DIR/../.." && pwd)
CONFIG_FILE="${PANEPILOT_CONFIG_FILE:-$REPO_ROOT/config/panepilot.env}"

if [[ -f "$CONFIG_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$CONFIG_FILE"
  set +a
fi

PANEPILOT_SESSION=${PANEPILOT_SESSION:-panepilot}
PANEPILOT_WORK_DIR=${PANEPILOT_WORK_DIR:-$REPO_ROOT}
PANEPILOT_AGENT_CMD=${PANEPILOT_AGENT_CMD:-claude}
PANEPILOT_AGENT_ENV_FILE=${PANEPILOT_AGENT_ENV_FILE:-}
PANEPILOT_AGENT_PRELUDE=${PANEPILOT_AGENT_PRELUDE:-}
PANEPILOT_AGENT_SHELL=${PANEPILOT_AGENT_SHELL:-bash}
PANEPILOT_PROCESS_REGEX=${PANEPILOT_PROCESS_REGEX:-}
PANEPILOT_READY_REGEX=${PANEPILOT_READY_REGEX:-}
PANEPILOT_ERROR_REGEX=${PANEPILOT_ERROR_REGEX:-}
PANEPILOT_WAIT_FOR_READY=${PANEPILOT_WAIT_FOR_READY:-1}
PANEPILOT_READY_TIMEOUT_SECONDS=${PANEPILOT_READY_TIMEOUT_SECONDS:-20}
PANEPILOT_READY_POLL_INTERVAL_SECONDS=${PANEPILOT_READY_POLL_INTERVAL_SECONDS:-1}
PANEPILOT_LOG_DIR=${PANEPILOT_LOG_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/panepilot}
PANEPILOT_TASK_FILE=${PANEPILOT_TASK_FILE:-$REPO_ROOT/tasks/nightly.md}
PANEPILOT_COMPACT_INTERVAL_SECONDS=${PANEPILOT_COMPACT_INTERVAL_SECONDS:-21600}
PANEPILOT_COMPACT_COMMAND=${PANEPILOT_COMPACT_COMMAND:-/compact}
PANEPILOT_RECOVERY_MESSAGE=${PANEPILOT_RECOVERY_MESSAGE:-The session was restarted. Resume the previous task and summarize any missing context first.}
PANEPILOT_CAPTURE_LINES=${PANEPILOT_CAPTURE_LINES:-120}

panepilot_log_path() {
  printf '%s/%s.log\n' "$PANEPILOT_LOG_DIR" "$1"
}

ensure_panepilot_dirs() {
  mkdir -p "$PANEPILOT_LOG_DIR"
}

panepilot_log() {
  local logfile="$1"
  shift
  ensure_panepilot_dirs
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$logfile"
}

require_command() {
  local name="$1"
  if ! command -v "$name" >/dev/null 2>&1; then
    printf 'Missing required command: %s\n' "$name" >&2
    exit 1
  fi
}

require_readable_file() {
  local file="$1"
  if [[ ! -r "$file" ]]; then
    printf 'Missing readable file: %s\n' "$file" >&2
    exit 1
  fi
}

panepilot_agent_program() {
  local words=()
  read -r -a words <<< "$PANEPILOT_AGENT_CMD"
  printf '%s\n' "${words[0]:-}"
}

panepilot_agent_launch_command() {
  local script=""

  if [[ -n "$PANEPILOT_AGENT_ENV_FILE" ]]; then
    script+="source $(printf '%q' "$PANEPILOT_AGENT_ENV_FILE") && "
  fi

  if [[ -n "$PANEPILOT_AGENT_PRELUDE" ]]; then
    script+="$PANEPILOT_AGENT_PRELUDE && "
  fi

  if [[ -z "$script" ]]; then
    printf '%s\n' "$PANEPILOT_AGENT_CMD"
    return 0
  fi

  script+="exec $PANEPILOT_AGENT_CMD"
  printf '%q -lc %q\n' "$PANEPILOT_AGENT_SHELL" "$script"
}

panepilot_has_session() {
  tmux has-session -t "$PANEPILOT_SESSION" 2>/dev/null
}

panepilot_pane_target() {
  printf '%s:0\n' "$PANEPILOT_SESSION"
}

panepilot_session_option() {
  local session="$1"
  local option="$2"
  tmux show-options -t "$session" -vq "$option" 2>/dev/null || true
}

panepilot_set_session_option() {
  local session="$1"
  local option="$2"
  local value="$3"
  tmux set-option -t "$session" -q "$option" "$value"
}

panepilot_pane_dead() {
  tmux display-message -p -t "$(panepilot_pane_target)" '#{pane_dead}'
}

panepilot_pane_current_command() {
  tmux display-message -p -t "$(panepilot_pane_target)" '#{pane_current_command}'
}

panepilot_pane_start_command() {
  tmux display-message -p -t "$(panepilot_pane_target)" '#{pane_start_command}'
}

panepilot_capture_output() {
  local lines="${1:-$PANEPILOT_CAPTURE_LINES}"
  tmux capture-pane -pt "$(panepilot_pane_target)" -S "-$lines"
}

panepilot_matches_regex() {
  local value="$1"
  local regex="$2"

  if [[ -z "$regex" ]]; then
    return 1
  fi

  [[ "$value" =~ $regex ]]
}

panepilot_process_matches() {
  local current_command
  current_command=$(panepilot_pane_current_command)

  if [[ -z "$PANEPILOT_PROCESS_REGEX" ]]; then
    return 0
  fi

  panepilot_matches_regex "$current_command" "$PANEPILOT_PROCESS_REGEX"
}

panepilot_health_state() {
  if ! panepilot_has_session; then
    printf 'stopped\n'
    return 0
  fi

  if [[ "$(panepilot_pane_dead)" == "1" ]]; then
    printf 'dead\n'
    return 0
  fi

  if ! panepilot_process_matches; then
    printf 'process_mismatch\n'
    return 0
  fi

  local capture
  capture=$(panepilot_capture_output "$PANEPILOT_CAPTURE_LINES")

  if panepilot_matches_regex "$capture" "$PANEPILOT_ERROR_REGEX"; then
    printf 'error\n'
    return 0
  fi

  if [[ -n "$PANEPILOT_READY_REGEX" ]]; then
    if panepilot_matches_regex "$capture" "$PANEPILOT_READY_REGEX"; then
      printf 'ready\n'
    else
      printf 'starting\n'
    fi
    return 0
  fi

  printf 'running\n'
}

panepilot_state_is_healthy() {
  local state="$1"
  [[ "$state" == "ready" || "$state" == "running" ]]
}

panepilot_mark_session_metadata() {
  local session="$1"
  panepilot_set_session_option "$session" "@panepilot_managed" "1"
  panepilot_set_session_option "$session" "@panepilot_work_dir" "$PANEPILOT_WORK_DIR"
  panepilot_set_session_option "$session" "@panepilot_agent_cmd" "$PANEPILOT_AGENT_CMD"
  panepilot_set_session_option "$session" "@panepilot_process_regex" "$PANEPILOT_PROCESS_REGEX"
  panepilot_set_session_option "$session" "@panepilot_ready_regex" "$PANEPILOT_READY_REGEX"
  panepilot_set_session_option "$session" "@panepilot_error_regex" "$PANEPILOT_ERROR_REGEX"
  panepilot_set_session_option "$session" "@panepilot_config_file" "$CONFIG_FILE"
}

panepilot_session_capture_output() {
  local session="$1"
  local lines="${2:-$PANEPILOT_CAPTURE_LINES}"
  tmux capture-pane -pt "${session}:0" -S "-$lines"
}

panepilot_session_health_state() {
  local session="$1"

  if ! tmux has-session -t "$session" 2>/dev/null; then
    printf 'stopped\n'
    return 0
  fi

  local pane_dead current_command capture process_regex ready_regex error_regex
  pane_dead=$(tmux display-message -p -t "${session}:0" '#{pane_dead}')
  current_command=$(tmux display-message -p -t "${session}:0" '#{pane_current_command}')
  process_regex=$(panepilot_session_option "$session" "@panepilot_process_regex")
  ready_regex=$(panepilot_session_option "$session" "@panepilot_ready_regex")
  error_regex=$(panepilot_session_option "$session" "@panepilot_error_regex")

  if [[ "$pane_dead" == "1" ]]; then
    printf 'dead\n'
    return 0
  fi

  if [[ -n "$process_regex" ]] && ! [[ "$current_command" =~ $process_regex ]]; then
    printf 'process_mismatch\n'
    return 0
  fi

  capture=$(panepilot_session_capture_output "$session" "$PANEPILOT_CAPTURE_LINES")

  if [[ -n "$error_regex" ]] && [[ "$capture" =~ $error_regex ]]; then
    printf 'error\n'
    return 0
  fi

  if [[ -n "$ready_regex" ]]; then
    if [[ "$capture" =~ $ready_regex ]]; then
      printf 'ready\n'
    else
      printf 'starting\n'
    fi
    return 0
  fi

  printf 'running\n'
}

panepilot_list_managed_sessions() {
  local session
  tmux list-sessions -F '#{session_name}' 2>/dev/null | while read -r session; do
    if [[ "$(panepilot_session_option "$session" "@panepilot_managed")" != "1" ]]; then
      continue
    fi

    local state current_command work_dir
    state=$(panepilot_session_health_state "$session")
    current_command=$(tmux display-message -p -t "${session}:0" '#{pane_current_command}')
    work_dir=$(panepilot_session_option "$session" "@panepilot_work_dir")
    printf '%s\t%s\t%s\t%s\n' "$session" "$state" "$current_command" "$work_dir"
  done
}
