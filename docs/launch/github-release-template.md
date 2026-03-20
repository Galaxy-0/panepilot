# Release Template

## Summary

PanePilot is a tmux workspace layer for terminal-native coding agents.

## Highlights

- persistent tmux-backed agent sessions
- health and readiness checks
- conditional recovery for unhealthy sessions
- task injection and pane capture commands
- verified runtime profiles for Codex and OpenClaw

## Good first things to try

1. Copy `config/panepilot.env.example` to `config/panepilot.env`
2. Set `PANEPILOT_AGENT_CMD`
3. Set `PANEPILOT_WORK_DIR`
4. Start with `./bin/panepilot start`
5. Check `./bin/panepilot doctor`
