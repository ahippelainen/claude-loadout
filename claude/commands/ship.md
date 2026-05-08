---
description: Lint, test, commit, and push the current working tree
argument-hint: "[optional: commit message]"
---

Ship the current working tree.

Pre-check:
- If this repo touches live trading (e.g. poly_bot), confirm there are no uncommitted changes to preflight / safeguard files, and no env vars with `LIVE_TRADING_ENABLED=true` in staged content.

Steps:
1. `git status --short` — show what's changed.
2. If nothing is changed, say "nothing to ship" and stop.
3. Run the project's lint and format. If lint reports unfixable issues, stop and surface them.
4. Run the project's fast test suite. If tests fail, stop and surface them. Do not commit failing code.
5. Read the diff to understand what changed.
6. `git add -A`.
7. Commit. Message: use $ARGUMENTS if provided, otherwise write a concise one-liner based on the diff. No Claude co-author trailer.
8. `git push`. If the push fails (no upstream, auth, etc.), surface the error — do not try fancy recovery.
9. Report: final commit hash, one-line message, and whether push succeeded.

If any step fails, stop at that step and report. Do not skip ahead.
