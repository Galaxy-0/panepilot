#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(cd -- "$SCRIPT_DIR/../.." && pwd)
# shellcheck disable=SC1091
source "$ROOT_DIR/scripts/lib/common.sh"

PANEPILOT_SCRIPT="$ROOT_DIR/scripts/assistant.sh"
LOG_FILE=$(panepilot_log_path nightly)

main() {
  ensure_panepilot_dirs
  panepilot_log "$LOG_FILE" "nightly task start"

  "$PANEPILOT_SCRIPT" start
  sleep 5

  local task
  if [[ -f "$PANEPILOT_TASK_FILE" ]]; then
    task=$(<"$PANEPILOT_TASK_FILE")
    panepilot_log "$LOG_FILE" "loaded nightly task from $PANEPILOT_TASK_FILE"
  else
    task=$(cat <<'EOF'
Review the current workspace and produce a concise end-of-day summary.

1. Identify the most important unfinished work.
2. Propose the smallest useful next step.
3. List blockers, missing context, and files to inspect next.
EOF
)
    panepilot_log "$LOG_FILE" "using built-in nightly task"
  fi

  "$PANEPILOT_SCRIPT" send "$task"
  panepilot_log "$LOG_FILE" "nightly task sent"
}

main
