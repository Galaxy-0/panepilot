# Runtime Profiles

PanePilot is runtime-agnostic, but some CLIs benefit from a tuned profile for
process checks, ready detection, or local credential loading.

## Verified on this machine

### Codex

Use:

```bash
cp examples/codex.env config/panepilot.env
```

Why this profile exists:

- `codex` often needs local API credentials from `~/.codex/crs_oai.env`
- the visible runtime process is `node`, not `codex`
- the pane output includes a stable startup banner that PanePilot can treat as
  `ready`

### OpenClaw

Use:

```bash
cp examples/openclaw.env config/panepilot.env
```

Why this profile exists:

- the interactive terminal surface is `openclaw tui`
- the runtime process is `openclaw`
- the TUI prints stable gateway/session text that PanePilot can treat as
  `ready`

## Template only

### Claude

The repository includes `examples/claude.env` as a starting point, but this
runtime was not available on the current machine during validation.

Recommended first step:

```bash
cp examples/claude.env config/panepilot.env
./bin/panepilot start
./bin/panepilot health
./bin/panepilot capture 120
```

If Claude's startup banner differs on your system, tune:

- `PANEPILOT_PROCESS_REGEX`
- `PANEPILOT_READY_REGEX`
- `PANEPILOT_ERROR_REGEX`
