# Commands — Short Index

One-line reach-for guide. For full detail see `INDEX.md`.

## LaTeX / Overleaf

| Command | Reach for it when |
|---|---|
| `/ol-sync push` | Pushing `main`'s LaTeX to `ol` and Overleaf, pulling collaborator edits back. |
| `/repo-init` | Bootstrapping a new LaTeX repo with the `main`/`ol` two-branch structure. |

## Python

| Command | Reach for it when |
|---|---|
| `/lint` | Ruff fix + format on changed `.py` files — no tests, no commit. |
| `/python-review` | Full review via `python-pro` agent on changed Python. |
| `/test-coverage` | Find gaps below 80% and generate missing pytest tests. |

## Git & Shipping

| Command | Reach for it when |
|---|---|
| `/ship` | Lint → test → commit → push (with live-trading safety check). |
| `/sync-dotfiles` | Commit + push `~/Git/dotfiles`. |

## Debugging & Exploration

| Command | Reach for it when |
|---|---|
| `/debug` | Persistent debugging session with a state file that survives context resets. |
| `/map-codebase` | Unfamiliar codebase — 4 parallel Explore agents write docs to `.planning/codebase/`. |

## Code Review

| Command | Reach for it when |
|---|---|
| `/code-review` | Local diff review (no args) or GitHub PR review (PR number/URL). |

## Dotfiles

| Command | Reach for it when |
|---|---|
| `/insights-triage` | Turn `/insights` output into skills/commands/hooks/CLAUDE.md additions. |

## Plan Execution (codebase updates)

| Command | Reach for it when |
|---|---|
| `/review-plan` | Critically reviewing an external LLM's update plan against real source. |
| `/execute-plan` | Executing an approved plan via parallel worktree subagents. |
| `/wave-merge` | Integrating completed worktrees back to main after a fan-out run. |

## Long-running Loops

| Command | Reach for it when |
|---|---|
| `/ralph-loop` | Running a prompt in a self-feeding loop until a completion promise fires. |
| `/cancel-ralph` | Killing the active Ralph loop. |
