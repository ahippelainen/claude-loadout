# Hooks Index

## Global hooks (always active)

| Hook | Event | Purpose |
|---|---|---|
| `ralph/stop-hook.sh` | Stop | If `.claude/ralph-loop.local.md` exists: block exit, feed prompt back for next iteration |
| `auto-commit-dotfiles.sh` | PostToolUse (Edit/Write) | Auto-commit writes to `~/Git/dotfiles`; coalesces within 30s |

## Project-local hooks (not in dotfiles)

| Hook | Event | Project | Purpose |
|---|---|---|---|
| `lint-on-edit.sh` | PostToolUse (Edit/Write) | poly_bot | Run ruff on edited Python files |

## Ralph loop state

Ralph loop is activated by `/ralph-loop` command. State file: `.claude/ralph-loop.local.md` in project root.
Loop runs until: `--max-iterations N` reached, or Claude outputs `<promise>TEXT</promise>` matching `--completion-promise TEXT`.
Cancel anytime with `/cancel-ralph`.
