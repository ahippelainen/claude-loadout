# Hooks — Short Index

One-line reach-for guide. For full detail see `INDEX.md`.

## Global (always active)

| Hook | Reach for it when |
|---|---|
| `ralph/stop-hook.sh` | Stop-event hook that powers `/ralph-loop` — re-injects the prompt until completion or max-iterations. |
| `auto-commit-dotfiles.sh` | PostToolUse hook that auto-commits any edit inside `~/Git/dotfiles`, coalescing within 30s. |

## Project-local (not in dotfiles)

| Hook | Reach for it when |
|---|---|
| `lint-on-edit.sh` (poly_bot) | PostToolUse hook that runs ruff on edited Python files. |
