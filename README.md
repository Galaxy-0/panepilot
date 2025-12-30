# Claude Crew

A persistent Claude Code research assistant that runs in tmux, supporting automated tasks and manual interaction.

## Features

- **Persistent Session**: Claude Code runs in tmux, survives terminal disconnection
- **Dual Input**: Both manual interaction and automated task injection
- **Auto-Maintenance**: Periodic `/compact` to manage context, auto-restart on failure
- **Scheduled Tasks**: Cron integration for nightly research, morning briefs

## Quick Start

```bash
# Start the assistant
./scripts/assistant.sh start

# Attach to interact
./scripts/assistant.sh attach

# Detach (keep running): Ctrl+b, d

# Send task without entering session
./scripts/assistant.sh send "Search for latest AI papers"
```

## Installation

```bash
# Clone the repo
git clone https://github.com/YOUR_USERNAME/claude-crew.git
cd claude-crew

# Add alias to ~/.zshrc
echo 'alias crew="~/Project/GalaxyAI/claude-crew/scripts/assistant.sh"' >> ~/.zshrc
source ~/.zshrc

# Now use: crew start, crew attach, crew send "..."
```

## Scripts

| Script | Purpose | Usage |
|--------|---------|-------|
| `scripts/assistant.sh` | Main control script | Manual |
| `scripts/keepalive.sh` | Health check & compact | Cron (hourly) |
| `scripts/tasks/nightly.sh` | Nightly research task | Cron (22:00) |

## Cron Setup (Optional)

```bash
crontab -e

# Add:
0 * * * * /path/to/claude-crew/scripts/keepalive.sh
0 22 * * * /path/to/claude-crew/scripts/tasks/nightly.sh
```

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                     You (Supervisor)                 │
│                                                     │
│   Manual: crew attach    Auto: crew send "task"    │
└─────────────────────────┬───────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────┐
│                   tmux session                       │
│            (persistent, detachable)                 │
│                                                     │
│   ┌─────────────────────────────────────────────┐   │
│   │            Claude Code (interactive)         │   │
│   │                                             │   │
│   │   - Receives input from you or scripts      │   │
│   │   - Context auto-compacted every 6 hours    │   │
│   │   - Auto-restarts if crashed                │   │
│   └─────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘
```

## Commands

```bash
crew start        # Start assistant in tmux
crew stop         # Stop assistant
crew attach       # Enter interactive session
crew status       # Check if running
crew send "msg"   # Send task (no enter session)
crew send-file f  # Send task from file
crew help         # Show help
```

## Tmux Shortcuts (inside session)

| Shortcut | Action |
|----------|--------|
| `Ctrl+b, d` | Detach (keep running) |
| `Ctrl+b, [` | Scroll mode (view history) |
| `q` | Exit scroll mode |

## License

MIT
