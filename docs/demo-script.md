# Demo Script

Use this flow for a short launch video or GIF.

## Demo goal

Show that a coding agent can survive terminal disconnects, receive work
asynchronously, and remain scriptable.

## Suggested flow

1. Open a clean terminal in a sample project.
2. Show `cp config/panepilot.env.example config/panepilot.env`.
3. Show `./bin/panepilot start`.
4. Show `./bin/panepilot status`.
5. Attach briefly with `./bin/panepilot attach`.
6. Detach with `Ctrl+b d`.
7. Send a task from outside the session:
   `./bin/panepilot send "Summarize the open TODOs in this repo."`
8. Show `tmux ls` or reattach to prove the session stayed alive.
9. Show `./scripts/keepalive.sh` and explain scheduled automation.

## Recording notes

- Keep the demo under 45 seconds.
- Use a real repository, not an empty folder.
- Prefer one concrete coding task over generic chat prompts.
