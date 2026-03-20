# PanePilot

Persistent tmux workspaces for terminal-native coding agents.

`PanePilot` gives agent CLIs a stable operating surface: start a session once,
detach from it, reattach later, inject tasks from scripts, and keep the session
alive across terminal disconnects. It is designed for real machines, not demo
shells.

By default the runtime command is configurable, so the same workflow can drive
`claude`, `codex`, `openclaw`, or any other terminal agent CLI.

## Why use it

Most coding agents behave like interactive terminal apps, but the actual work
you want from them is often long-running:

- keep a session alive while you disconnect or reboot your terminal
- send prompts without attaching to the pane
- resume the same workspace instead of starting from scratch
- schedule recurring prompts with cron
- keep logs and local state out of the git repo

PanePilot is the thin operational layer around that workflow.

## Features

- Persistent tmux-backed agent session
- Configurable agent command and working directory
- `send` and `send-file` task injection helpers
- Optional keepalive script with periodic compaction
- Optional nightly task automation
- User-local config instead of hardcoded personal paths

## Requirements

- `bash`
- `tmux`
- a terminal agent CLI on your `PATH`

## Quick Start

```bash
git clone https://github.com/Galaxy-0/panepilot.git
cd panepilot
cp config/panepilot.env.example config/panepilot.env
```

Edit `config/panepilot.env` and set at least:

- `PANEPILOT_AGENT_CMD`, for example `claude`, `codex`, or `openclaw`
- `PANEPILOT_WORK_DIR`, the workspace you want the agent to run in

Then start the session:

```bash
./bin/panepilot start
```

Common commands:

```bash
./bin/panepilot status
./bin/panepilot attach
./bin/panepilot send "Review the open TODOs in this repo."
./bin/panepilot send-file ./tasks/example-nightly.md
./bin/panepilot config
```

## Configuration

Local configuration lives in `config/panepilot.env` and is gitignored.

Example:

```bash
PANEPILOT_AGENT_CMD="codex"
PANEPILOT_WORK_DIR="$HOME/work/my-project"
PANEPILOT_SESSION="panepilot"
PANEPILOT_LOG_DIR="$HOME/.local/state/panepilot"
PANEPILOT_TASK_FILE="$HOME/work/my-project/tasks/nightly.md"
```

See `config/panepilot.env.example` for the full set of options.

## Optional Automation

Keep the session alive and compact the context every few hours:

```bash
0 * * * * /path/to/panepilot/scripts/keepalive.sh
```

Send a nightly task prompt from a file:

```bash
0 22 * * * /path/to/panepilot/scripts/tasks/nightly.sh
```

You can use `tasks/example-nightly.md` as a starting point and copy it to your
own `tasks/nightly.md`.

## Tmux Shortcuts

- `Ctrl+b d`: detach and leave the agent running
- `Ctrl+b [`: enter scroll mode
- `q`: exit scroll mode

## Demo

The repository includes a simple launch checklist and demo outline:

- `docs/publish-checklist.md`
- `docs/demo-script.md`

## Scope

PanePilot is intentionally small. It is not a workflow engine, scheduler, or
multi-agent orchestrator. The goal is a dependable single-agent workspace layer
that works with minimal moving parts.

## License

MIT
