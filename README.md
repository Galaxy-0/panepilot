# PanePilot

[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

Persistent tmux workspaces for terminal-native coding agents.

PanePilot gives agent CLIs a stable operating surface: start a session once,
detach from it, reattach later, inject tasks from scripts, and keep the session
alive across terminal disconnects.

It is designed for real machines, not demo shells.

![PanePilot demo](docs/assets/panepilot-demo.svg)

## Why it exists

Most coding agents behave like interactive terminal apps, but real usage is
often longer-running than one terminal tab:

- keep a session alive while you disconnect
- send prompts without attaching to the pane
- keep one agent pinned to one workspace
- recover the session if the agent exits
- schedule recurring prompts with cron
- keep logs and local state out of the repo

PanePilot is the thin operational layer around that workflow.

## What it supports

PanePilot is runtime-agnostic. If the agent exposes a terminal command, you can
run it inside the managed tmux session.

Common examples:

- `claude`
- `codex`
- `openclaw`
- custom wrapper scripts such as `bin/my-agent`

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

$ ./bin/panepilot status
running
session=panepilot
work_dir=/home/me/work/my-project
agent_cmd=codex
log_dir=/home/me/.local/state/panepilot
```

## Configuration

Local configuration lives in `config/panepilot.env` and is gitignored.

Example:

```bash
PANEPILOT_AGENT_CMD="codex"
PANEPILOT_AGENT_ENV_FILE="$HOME/.codex/crs_oai.env"
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

Useful operational commands:

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

## How it is different

PanePilot is not:

- a workflow engine
- a scheduler platform
- a multi-agent orchestrator
- a hosted SaaS

PanePilot is:

- one durable agent session
- one real working directory
- one simple control surface around tmux

## Demo And Launch Notes

- `docs/demo-script.md`
- `docs/publish-checklist.md`
- `docs/launch-post.md`

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT
