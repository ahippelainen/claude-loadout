---
description: Lint, test, commit, and push the current working tree
argument-hint: "[optional: commit message]"
---

Ship the current working tree.

Pre-check: if the repo trades live, confirm there are no uncommitted changes to preflight or safeguard files and no `LIVE_TRADING_ENABLED=true` in staged content.

1. `git status --short`. Nothing changed: say "nothing to ship" and stop.
2. Run the project's lint and format; unfixable issues stop the ship.
3. Run the project's fast test suite; failures stop the ship.
4. Read the diff. Stage the changed files that belong to this change by name (`git add -- <paths>`); list untracked files and ask before adding any. Never `git add -A`: it has committed venvs before.
5. Commit with $ARGUMENTS as the message, or a `type: description` one-liner from the diff. No attribution trailers.
6. Push only if the repo is `free` in `~/Git/dotfiles/claude/push-policy`; otherwise ask first. Surface a failed push as is.
7. Report the commit hash, the message, and whether the push happened.

Stop at the first failing step and report it.
