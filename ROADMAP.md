# Roadmap

## Product Position

PanePilot is not another coding agent. It is the workspace management layer
around the terminal-native coding agents you already use.

Current product framing:

- today: single-agent workspace manager
- next: multi-workspace manager
- later: agent team workspace control plane

This matters because the long-term product is not "better tmux wrappers". The
product is persistent agent workspace management, with team coordination as the
upper bound.

## Current Status

PanePilot is already beyond personal scripts and into early usable product
territory.

Implemented today:

- persistent tmux-backed agent workspaces
- task injection and file-based task injection
- pane capture and log inspection
- health checks and ready detection
- conditional recovery and keepalive
- runtime profiles for Codex and OpenClaw
- template profile for Claude
- operator commands like `list`, `doctor`, and `restart-if-unhealthy`

Current weakness:

- multi-workspace management is still primitive
- setup is still more manual than product-grade
- state heuristics are useful but not yet deep
- team workflows are not first-class yet

## Phase 1: Make Single-Workspace Management Excellent

Goal:
Make PanePilot the best way to run one long-lived terminal agent workspace on a
real machine.

Status:
Mostly completed, but still worth tightening.

Focus:

- stronger unhealthy-state heuristics
- cleaner recovery behavior
- more runtime validation
- lower setup friction

Success criteria:

- users trust `health`, `doctor`, and `keepalive`
- first-run setup is straightforward
- Codex, OpenClaw, and Claude all have credible runtime guidance

## Phase 2: Multi-Workspace Management

Goal:
Make it practical to manage several agent workspaces across repos, runtimes, and
roles from one machine.

Why this matters:

The real pain begins when a user has more than one agent workspace. That is
where tmux alone stops being enough.

Deliverables:

- named configs or profile selection
- explicit `--config` support on the main entrypoint
- better `list` output with workspace metadata
- commands for selecting, inspecting, and switching active workspaces
- clear distinction between repo, runtime, session, and role

Success criteria:

- a user can manage multiple agent workspaces without manual env juggling
- `list` becomes a real dashboard, not just a raw session dump

## Phase 3: Workspace Roles

Goal:
Turn workspaces into role-bearing units such as researcher, implementer,
reviewer, or release agent.

Why this matters:

This is the bridge from "multiple sessions" to "agent team".

Deliverables:

- role metadata per workspace
- role-aware examples and configs
- clearer workspace labels in listing and diagnostics
- conventions for persistent specialist workspaces

Success criteria:

- a user can say "this workspace is my reviewer" and PanePilot can represent it
- multi-workspace operation starts to feel like managing a team, not random panes

## Phase 4: Handoff And Coordination

Goal:
Support simple but explicit coordination between persistent workspaces.

Why this matters:

Subagents solve short-lived delegation. Teams need visible handoff and shared
coordination over time.

Deliverables:

- task handoff primitives
- shared context or handoff notes
- explicit transfer between workspaces
- visible status for "assigned", "working", "blocked", and "done"

Success criteria:

- users can move work intentionally between workspaces
- coordination becomes inspectable instead of ad hoc terminal behavior

## Phase 5: Team Control Plane

Goal:
Evolve from workspace manager to agent team workspace control plane.

This does not mean building a giant orchestration platform. It means adding the
minimum coordination surface required for persistent teams of terminal-native
agents.

Deliverables:

- team-level overview
- team role topology
- recent events across workspaces
- better debugging of coordination failures
- clearer operator control over human-directed teams

Success criteria:

- PanePilot becomes the place a human uses to supervise agent workspaces
- the product is no longer perceived as just a tmux helper

## Near-Term Execution Order

1. Multi-workspace configs and profile selection
2. Better list/status output for many workspaces
3. Lower-friction setup and runtime initialization
4. Role-bearing workspaces
5. Handoff primitives

## Explicitly Not The Goal

- replacing tmux
- becoming a hosted orchestration platform
- pretending every agent runtime behaves the same
- building fully autonomous multi-agent systems as the first move

PanePilot should stay grounded in human-supervised, terminal-native workflows.
