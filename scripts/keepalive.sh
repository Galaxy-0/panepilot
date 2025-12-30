#!/bin/bash
# assistant-keepalive.sh - 助手保活 & 健康维护
# 建议每小时运行一次 (cron)

SESSION="research-assistant"
ASSISTANT="$HOME/scripts/research-assistant.sh"
LOG_FILE="$HOME/logs/keepalive.log"
LAST_COMPACT_FILE="/tmp/assistant-last-compact"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 检查会话是否存活
check_alive() {
    tmux has-session -t "$SESSION" 2>/dev/null
}

# 检查上次 compact 时间（每 6 小时 compact 一次）
need_compact() {
    if [ ! -f "$LAST_COMPACT_FILE" ]; then
        return 0  # 从未 compact，需要
    fi

    local last=$(cat "$LAST_COMPACT_FILE")
    local now=$(date +%s)
    local diff=$((now - last))
    local six_hours=$((6 * 60 * 60))

    [ $diff -gt $six_hours ]
}

# 执行 compact
do_compact() {
    log "执行 /compact 压缩上下文"
    tmux send-keys -t "$SESSION" "/compact" Enter
    date +%s > "$LAST_COMPACT_FILE"
    sleep 10  # 等待 compact 完成
}

# 主逻辑
log "========== 保活检查 =========="

if check_alive; then
    log "✅ 会话存活"

    # 检查是否需要 compact
    if need_compact; then
        log "⚠️ 上下文可能过大，执行 compact"
        do_compact
    fi
else
    log "❌ 会话已断开，重新启动"
    $ASSISTANT start
    sleep 5

    # 发送恢复消息
    $ASSISTANT send "我刚才重启了，请继续之前的工作。如果有未完成的任务，请告诉我。"
fi

log "========== 检查完成 =========="
