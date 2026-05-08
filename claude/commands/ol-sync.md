---
description: Sync with Overleaf — pull collaborator edits from Overleaf, push main's collaborator-updated LaTeX files to ol/Overleaf, and bring any collaborator changes into main. Fires on /ol-sync.
argument-hint: "push"
allowed-tools: Bash
---

Sync this repo with Overleaf. The repo has two branches:
- `main` — everything (LaTeX, data, notebooks, etc.)
- `ol` — LaTeX-relevant files only, tracked by Overleaf as `master`

The list of files/dirs to sync is in `.ol-sync` at the repo root (one path per line, comments with `#` ignored).

---

## /ol-sync push

Pull any collaborator edits from Overleaf, bring `main`'s changes into `ol`, push to both remotes.

1. Verify you are on `main` and working tree is clean. If not, stop and report.
2. Read `.ol-sync` to get the list of paths to sync.
3. `git fetch overleaf master`
4. `git checkout ol`
5. `git merge overleaf/master --no-rebase` — if conflicts, stop and surface them, do not auto-resolve.
6. For each path in `.ol-sync`: `git checkout main -- <path>` (overwrites ol's version with main's)
7. If nothing changed (`git diff --cached` is empty), report "ol already up to date" and return to `main`.
8. `git add` the synced paths and commit: `"Sync from main <short hash of main HEAD>"`
9. `git push origin ol`
10. `git push overleaf ol:master`
11. If either push fails, stop and report — do not attempt auto-resolution.
12. `git checkout main`
13. For each path in `.ol-sync`: `git checkout ol -- <path>` (brings any collaborator edits into main)
14. If files changed, `git add` and commit: `"Merge collaborator edits from ol <short hash>"`
15. `git push origin main`
16. Report: commit hashes, which files changed, all push results.

---

If there are merge conflicts at any step, stop and surface them — do not attempt auto-resolution.
