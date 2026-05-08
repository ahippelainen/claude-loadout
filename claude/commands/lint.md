---
description: Auto-fix and format Python code with ruff, report any remaining issues
argument-hint: "[optional: path to lint, defaults to changed files]"
allowed-tools: Bash(ruff check:*), Bash(ruff format:*), Bash(git status:*), Bash(git diff:*)
---

Run the project's linters on $ARGUMENTS (if given) or on the files changed
in this working tree (if not).

Steps:
1. If $ARGUMENTS is empty, use `git status --porcelain` to find modified and
   untracked Python files. If no Python files have changed, say so and stop.
2. Run `ruff check --fix <targets>` to auto-fix what can be auto-fixed.
3. Run `ruff format <targets>`.
4. Run `ruff check <targets>` one more time to catch anything that couldn't
   be auto-fixed.
5. If there are remaining issues, list them tersely (file:line — rule — message) and stop. Do not attempt to fix them yourself — I want to see them.
6. If everything is clean, say so in one line and stop.

Do not run tests, do not commit, do not push. Just lint.