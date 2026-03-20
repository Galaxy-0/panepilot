# Contributing

## Development

- Keep the project small and runtime-agnostic.
- Prefer shell scripts with minimal external dependencies.
- Avoid hardcoding personal paths, usernames, or machine-specific state.

## Local Checks

Run syntax checks before opening a PR:

```bash
bash -n bin/panepilot scripts/assistant.sh scripts/keepalive.sh scripts/tasks/nightly.sh scripts/lib/common.sh
```

If `shellcheck` is installed, run:

```bash
shellcheck bin/panepilot scripts/assistant.sh scripts/keepalive.sh scripts/tasks/nightly.sh scripts/lib/common.sh
```

## Scope

Good contributions:

- installation improvements
- better runtime examples
- tmux reliability fixes
- documentation that reduces setup friction

Out of scope:

- turning PanePilot into a full orchestrator
- agent-specific lock-in
- large framework abstractions for a small shell tool
