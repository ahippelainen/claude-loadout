---
description: Merge completed wave agents into main — inspect each worktree diff, fix stale imports, run tests, commit per agent. Use after parallel cleanup/rewrite agents finish.
argument-hint: "[commit-message-prefix]"
allowed-tools: Bash, Read, Edit, Glob, Grep
---

# Wave Merge

After parallel agents finish their worktree changes, integrate them into main safely.

## Steps

1. Find all worktrees with uncommitted changes:
   ```
   for wt in .claude/worktrees/*/; do git -C "$wt" status --short | head -3 && echo "$wt"; done
   ```

2. For each worktree with changes, inspect the diff:
   ```
   git -C <worktree> diff
   ```
   Check for: stale imports pointing to deleted modules, logic correctness, no unintended deletions.

3. Copy or apply changes to main working tree. Fix any stale imports (common after module-collapse waves).

4. Run full test suite:
   ```
   python -m pytest tests/ --ignore=tests/live 2>&1 | grep -E "passed|failed|error"
   ```
   All tests must pass before committing. Fix any breakage.

5. Stage and commit each logical unit separately:
   ```
   git add <files> && git commit -m "<type>: <description>"
   ```

6. Also check if agents wrote to the main working tree directly (git status on main) — commit those too.

## Notes

- Never trust agent summary alone — always read the actual diff.
- Agents often can't run git themselves; their changes land on disk uncommitted.
- Stale imports are the most common failure mode after module-collapse refactors.
