# Reddit Post Draft

Title:
I built a small tmux wrapper for long-running coding agent sessions

Body:

I kept running into the same problem with terminal coding agents:
they work well in one shell, but daily usage quickly turns into a pile of ad hoc tmux commands, restart scripts, and environment hacks.

So I pulled that layer into a small open-source tool called PanePilot.

What it does:

- starts a coding agent in a persistent tmux session
- lets you inject prompts without attaching
- checks whether the session is actually healthy, not just alive
- supports runtime-specific readiness checks
- includes verified profiles for Codex and OpenClaw

What it is not:

- not a hosted product
- not a workflow engine
- not trying to replace tmux

It is basically the operational layer I wanted between tmux and a terminal-native coding agent.

Repo:
https://github.com/Galaxy-0/panepilot
