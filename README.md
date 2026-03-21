# PanePilot

[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

Workspace management for terminal-native coding agents and agent teams.

PanePilot gives agent CLIs a stable operating surface: start a workspace once,
detach from it, reattach later, inject tasks from scripts, inspect runtime
health, and recover sessions when they drift.

It is designed for real machines, not demo shells.

![PanePilot demo](docs/assets/panepilot-demo.svg)

## One-line Pitch

PanePilot is a workspace manager for terminal-native coding agents.

## Why it exists

Most coding agents behave like interactive terminal apps, but real usage is
closer to workspace management than one-off terminal sessions:

- keep a session alive while you disconnect
- send prompts without attaching to the pane
- keep one agent pinned to one workspace
- manage multiple workspaces across repos
- understand which workspace is healthy, blocked, or broken
- recover the session if the agent exits
- schedule recurring prompts with cron
- keep logs and local state out of the repo

PanePilot is the control layer around that workflow.

## Why not just tmux?

Plain tmux gives you persistence, but not workspace management.

PanePilot adds:

- runtime-aware health checks
- ready detection
- conditional recovery instead of blind restarts
- runtime profiles for different agent CLIs
- a stable command surface for status, capture, logs, and task injection
- a path toward managing multiple agent workspaces as one system

If your answer is "I can already do this in tmux", that is true for the first
10 minutes. PanePilot exists for the third day of managing the same agent
workspace, or the fifth workspace on the same machine.

## Current Product Shape

Today, PanePilot is strongest as:

- a single-agent workspace manager
- an operator surface for long-running terminal agent sessions
- a base layer for future multi-agent workspace coordination

It is not yet a full team control plane, but that is the direction.

## What it supports

PanePilot is runtime-agnostic. If the agent exposes a terminal command, you can
run it inside the managed tmux session.

Common examples:

- `claude`
- `codex`
- `openclaw`
- custom wrapper scripts such as `bin/my-agent`

Validated profiles currently included:

| Runtime | Profile | Validation status |
| --- | --- | --- |
| Codex | `examples/codex.env` | verified |
| OpenClaw | `examples/openclaw.env` | verified |
| Claude | `examples/claude.env` | template only |

See `docs/runtimes.md` for runtime-specific notes.

## Quick Start

```bash
git clone https://github.com/Galaxy-0/panepilot.git
cd panepilot
cp config/panepilot.env.example config/panepilot.env
```

Edit `config/panepilot.env` and set at least:

- `PANEPILOT_AGENT_CMD`, for example `codex`
- `PANEPILOT_WORK_DIR`, the workspace you want the agent to run in

If your agent needs local API credentials, also set:

- `PANEPILOT_AGENT_ENV_FILE`, for example `"$HOME/.codex/crs_oai.env"`

Then start the session:

```bash
./bin/panepilot start
```

Common commands:

```bash
./bin/panepilot status
./bin/panepilot health
./bin/panepilot list
./bin/panepilot doctor
./bin/panepilot restart-if-unhealthy
./bin/panepilot wait-ready 20
./bin/panepilot attach
./bin/panepilot capture 80
./bin/panepilot logs keepalive 50
./bin/panepilot send "Review the open TODOs in this repo."
./bin/panepilot send-file ./tasks/example-nightly.md
./bin/panepilot config
```

## What it looks like

```text
$ ./bin/panepilot start
Started session: panepilot
Attach with: ./bin/panepilot attach

$ ./bin/panepilot send "Summarize the open TODOs in this repo."
Sent task to panepilot

$ ./bin/panepilot doctor
check_tmux=ok
check_agent_command=ok
session_state=ready
doctor=ok
```

## Configuration

Local configuration lives in `config/panepilot.env` and is gitignored.

Example:

```bash
PANEPILOT_AGENT_CMD="codex"
PANEPILOT_AGENT_ENV_FILE="$HOME/.codex/crs_oai.env"
PANEPILOT_PROCESS_REGEX="^(node|codex)$"
PANEPILOT_READY_REGEX="OpenAI Codex|Use /skills|100% left"
PANEPILOT_ERROR_REGEX="Missing environment variable"
PANEPILOT_WORK_DIR="$HOME/work/my-project"
PANEPILOT_SESSION="panepilot"
PANEPILOT_LOG_DIR="$HOME/.local/state/panepilot"
PANEPILOT_TASK_FILE="$HOME/work/my-project/tasks/nightly.md"
```

See:

- `config/panepilot.env.example`
- `examples/codex.env`
- `examples/claude.env`
- `examples/openclaw.env`
- `docs/runtimes.md`

Useful operational commands:

- `./bin/panepilot health` for the current runtime state
- `./bin/panepilot list` to inspect managed tmux sessions
- `./bin/panepilot doctor` to validate config, runtime command, env file, and session state
- `./bin/panepilot restart-if-unhealthy` to recover only when state is not healthy
- `./bin/panepilot wait-ready 20` to block until the pane becomes ready
- `./bin/panepilot capture 120` to inspect the current pane buffer
- `./bin/panepilot logs assistant 50` to tail PanePilot logs
- `./bin/panepilot logs keepalive 50` to inspect restart behavior

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

## FAQ

### Is this only for one agent?

Right now, one PanePilot config manages one primary workspace well. You can run
multiple workspaces by using different config files or tmux session names, but
first-class multi-workspace and team flows are still ahead on the roadmap.

### Is this a replacement for a workflow engine?

No. PanePilot is intentionally focused on workspace management, not abstract
workflow orchestration.

### Is this trying to replace subagents?

No. Subagents are short-lived task delegation. PanePilot is about persistent
workspaces and, over time, persistent agent team coordination.

### Does it require tmux expertise?

Not much. You still benefit from knowing basic tmux keys, but the day-to-day
control surface is `./bin/panepilot`, not raw tmux commands.

### What if my agent startup output is different?

Tune:

- `PANEPILOT_PROCESS_REGEX`
- `PANEPILOT_READY_REGEX`
- `PANEPILOT_ERROR_REGEX`

## Product Direction

Short version:

- now: single-agent workspace manager
- next: multi-workspace manager
- later: agent team workspace control plane

See [ROADMAP.md](ROADMAP.md).

## Launch Assets

- `docs/demo-script.md`
- `docs/launch-post.md`
- `docs/launch/x-post.md`
- `docs/launch/reddit-post.md`
- `docs/launch/hn-post.md`

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT
