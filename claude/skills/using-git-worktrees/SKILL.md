---
name: using-git-worktrees
description: Use when starting feature work that needs isolation from current workspace.
---

# Using Git Worktrees

Git worktrees create isolated workspaces sharing the same repository, allowing parallel branch work without switching.

## Directory Selection

Follow this priority order:

1. **Existing directory** — check for `.worktrees/` then `worktrees/`; if found, use it (`.worktrees/` wins if both exist)
2. **CLAUDE.md preference** — `grep -i "worktree" CLAUDE.md`
3. **Ask** if neither exists

## Safety: Verify gitignore

For project-local worktree directories, always verify before creating:

```bash
git check-ignore -q .worktrees
```

If not ignored: add to `.gitignore` and commit before proceeding. Prevents worktree contents from polluting git status.

Not needed for paths outside the repo.

## Creation

```bash
# Detect project name
project=$(basename "$(git rev-parse --show-toplevel)")

# Create worktree on a new branch
git worktree add .worktrees/<branch-name> -b <branch-name>
```

Then run project setup (e.g. `pip install -e .`, `poetry install`) and verify a clean baseline:

```bash
pytest   # or project-appropriate test command
```

If tests fail: report and ask whether to proceed.

## Report when ready

```
Worktree ready at <full-path>
Tests passing (N tests, 0 failures)
Ready to implement <feature>
```

## Red Flags

- Never create a project-local worktree without checking gitignore first
- Never skip baseline test verification
- Never proceed with failing tests without asking
- Follow directory priority — don't assume location
