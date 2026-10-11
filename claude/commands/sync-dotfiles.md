---
description: Fold auto-commits, check, and push ~/Git/dotfiles so local and remote stay in sync
---

Sync the dotfiles repo (`~/Git/dotfiles`, standing push approval in `claude/push-policy`).

1. `git -C ~/Git/dotfiles fetch origin` and `git -C ~/Git/dotfiles status --short`.
2. Uncommitted changes: read the diff, stage the files that belong together by name (`git add -- <paths>`), and commit with a `type: description` message. Untracked files you did not create in this session: list them and ask.
3. Fold the local `[auto-commit-dotfiles]` commits (those not on `origin/main`) into commits with real messages: `git reset --soft origin/main`, then commit by topic. Never rewrite commits already on `origin/main`.
4. `python3 ~/Git/dotfiles/claude/tools/check.py`: the index must be current and the check clean; fix what it reports.
5. If `origin/main` moved: `git rebase origin/main`; on conflict `git rebase --abort`, report and stop.
6. `git -C ~/Git/dotfiles push`, then report the pushed commits in one line each.

No attribution trailers. Do not touch any other repo.
