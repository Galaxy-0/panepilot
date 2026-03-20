#!/usr/bin/env bash

SCRIPT_DIR=$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd -- "$SCRIPT_DIR/../.." && pwd)
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
PANEPILOT_LOG_DIR=${PANEPILOT_LOG_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/panepilot}
PANEPILOT_TASK_FILE=${PANEPILOT_TASK_FILE:-$REPO_ROOT/tasks/nightly.md}
PANEPILOT_COMPACT_INTERVAL_SECONDS=${PANEPILOT_COMPACT_INTERVAL_SECONDS:-21600}
PANEPILOT_COMPACT_COMMAND=${PANEPILOT_COMPACT_COMMAND:-/compact}
PANEPILOT_RECOVERY_MESSAGE=${PANEPILOT_RECOVERY_MESSAGE:-The session was restarted. Resume the previous task and summarize any missing context first.}

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
