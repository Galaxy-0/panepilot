#!/bin/bash
# nightly-task.sh - 夜间定时任务
# 被 cron 调用，向研究助手发送夜间研究任务

ASSISTANT="$HOME/scripts/research-assistant.sh"
TASKS_FILE="$HOME/Project/GalaxyAI/TODO/Daily/tonight-tasks.md"
LOG_FILE="$HOME/logs/nightly.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

log "========== 夜间任务开始 =========="

# 确保助手在运行
$ASSISTANT start

# 等待 Claude 完全启动
sleep 5

# 读取任务文件（如果存在）
if [ -f "$TASKS_FILE" ]; then
    TASK=$(cat "$TASKS_FILE")
    log "从文件读取任务"
else
    # 默认任务
    TASK="开始今晚的研究任务。请：
1. 搜索 AI agents 领域最新进展（最近一周）
2. 总结 3 个最重要的发现
3. 将报告保存到 Daily/reports/night-$(date +%Y-%m-%d).md
4. 完成后告诉我要点摘要"
    log "使用默认任务"
fi

# 发送任务
$ASSISTANT send "$TASK"

log "任务已发送"
log "========== 夜间任务结束 =========="
