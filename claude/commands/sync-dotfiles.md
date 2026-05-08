---
description: Pull, commit, and push ~/Git/dotfiles — keeps local and remote in sync
allowed-tools: Bash(git -C $HOME/Git/dotfiles:*)
---

Sync the dotfiles repo.

Steps:
1. `git -C "$HOME/Git/dotfiles" fetch origin` — fetch remote state.
2. `git -C "$HOME/Git/dotfiles" status --short` — show uncommitted changes.
3. If there are uncommitted changes: `git -C "$HOME/Git/dotfiles" diff` — read them, then `git -C "$HOME/Git/dotfiles" add -A` and commit with a one-line message naming what changed (e.g. "Add /ship command", "Update CLAUDE.md tone rules"). No Claude co-author trailer.
4. `git -C "$HOME/Git/dotfiles" rebase origin/main` — replay any local commits on top of remote (handles both fast-forward and diverged cases). If rebase conflicts arise, abort with `git -C "$HOME/Git/dotfiles" rebase --abort`, report the conflict, and stop.
5. `git -C "$HOME/Git/dotfiles" push` — push result to origin.
6. Report final state in one line: commit hash and message.

Do not touch any other repo. Do not run linters — dotfiles is markdown and shell.
