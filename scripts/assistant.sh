#!/bin/bash
# research-assistant.sh - 研究助手管理脚本
# 管理一个持久化的 Claude Code 交互会话

SESSION="research-assistant"
WORK_DIR="$HOME/Project/GalaxyAI/TODO"
LOG_FILE="$HOME/logs/assistant.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 启动助手（如果没有运行）
start() {
    if tmux has-session -t "$SESSION" 2>/dev/null; then
        echo "✅ 助手已在运行"
        echo "   使用 '$0 attach' 进入会话"
    else
        echo "🚀 启动研究助手..."
        tmux new-session -d -s "$SESSION" -c "$WORK_DIR" "claude"
        sleep 2
        echo "✅ 助手已启动"
        echo "   使用 '$0 attach' 进入会话"
        log "助手启动"
    fi
}

# 停止助手
stop() {
    if tmux has-session -t "$SESSION" 2>/dev/null; then
        tmux kill-session -t "$SESSION"
        echo "⏹️ 助手已停止"
        log "助手停止"
    else
        echo "助手未运行"
    fi
}

# 接入会话
attach() {
    if tmux has-session -t "$SESSION" 2>/dev/null; then
        tmux attach -t "$SESSION"
    else
        echo "❌ 助手未运行，先使用 '$0 start' 启动"
    fi
}

# 查看状态
status() {
    if tmux has-session -t "$SESSION" 2>/dev/null; then
        echo "✅ 助手运行中"
        echo "   会话: $SESSION"
        echo "   使用 '$0 attach' 进入"
    else
        echo "⏹️ 助手未运行"
        echo "   使用 '$0 start' 启动"
    fi
}

# 发送任务给助手（不进入会话）
send() {
    if ! tmux has-session -t "$SESSION" 2>/dev/null; then
        echo "❌ 助手未运行，先启动..."
        start
        sleep 3
    fi

    local message="$*"
    if [ -z "$message" ]; then
        echo "用法: $0 send <任务内容>"
        exit 1
    fi

    # 发送消息到 Claude
    tmux send-keys -t "$SESSION" "$message" Enter
    echo "📤 已发送任务: $message"
    log "发送任务: $message"
}

# 发送文件中的任务
send-file() {
    local file="$1"
    if [ ! -f "$file" ]; then
        echo "❌ 文件不存在: $file"
        exit 1
    fi

    local content=$(cat "$file")
    send "$content"
}

# 帮助信息
help() {
    cat << EOF
🔬 研究助手管理器

用法: $0 <命令>

命令:
  start       启动助手（在 tmux 中运行 Claude Code）
  stop        停止助手
  attach      进入助手会话（交互对话）
  status      查看助手状态
  send <msg>  发送任务给助手（不进入会话）
  send-file   从文件发送任务
  help        显示此帮助

示例:
  $0 start                        # 启动助手
  $0 attach                       # 进入对话
  $0 send "分析今天的论文"          # 发送任务
  $0 send-file ~/tasks/today.md   # 从文件发送

快捷键（在 tmux 会话内）:
  Ctrl+b, d   分离会话（后台运行）
  Ctrl+b, [   进入滚动模式（查看历史）
  q           退出滚动模式
EOF
}

# 主入口
case "$1" in
    start)   start ;;
    stop)    stop ;;
    attach)  attach ;;
    status)  status ;;
    send)    shift; send "$@" ;;
    send-file) send-file "$2" ;;
    help|--help|-h) help ;;
    *)
        if [ -z "$1" ]; then
            status
        else
            echo "未知命令: $1"
            echo "使用 '$0 help' 查看帮助"
        fi
        ;;
esac
