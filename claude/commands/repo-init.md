---
description: Initialize a new git repo with the main/ol two-branch structure, GitHub remote, and Overleaf integration. Fires on /repo-init.
argument-hint: ""
allowed-tools: Bash
---

Set up a new git repo with the scientific project standard two-branch structure:
- `main` — everything (LaTeX, data, notebooks, etc.)
- `ol` — LaTeX-relevant files only, synced to Overleaf as `master`

Run this from the project directory. Guide the user through each step interactively.

---

## Steps

### 1. Gather information

Ask the user for the following (can ask all at once):
- GitHub remote URL (e.g. `git@github.com:user/repo.git`)
- Overleaf project ID (the `<id>` from `https://git.overleaf.com/<id>`)
- Which files/dirs should sync to Overleaf (i.e. go in `.ol-sync`) — suggest `notes.tex`, `bibliography.bib`, `Figures/` as defaults, let user confirm or adjust

### 2. Initialize git and .gitignore

- `git init -b main`
- Create `.gitignore` with:
  - LaTeX build artifacts: `*.aux`, `*.bbl`, `*.blg`, `*.fdb_latexmk`, `*.fls`, `*.log`, `*.out`, `*.synctex.gz`, `*.toc`, `*.pdf`
  - Exception: `!Figures/*.pdf`
  - Python: `venv/`, `__pycache__/`, `*.pyc`

### 3. Create .ol-sync

Create `.ol-sync` at repo root listing the user-confirmed paths, with a comment header explaining the format.

### 4. Initial commit on main

- `git add .`
- `git commit -m "Initial commit"`

### 5. Add remotes

- `git remote add origin <github-url>`
- `git remote add overleaf https://git.overleaf.com/<id>`

### 6. Push main to GitHub

- `git push -u origin main`

### 7. Create ol branch

- `git checkout --orphan ol`
- `git rm -rf --cached . -q`
- Stage only the files listed in `.ol-sync` plus `.gitignore`
- `git commit -m "Initial ol branch — LaTeX files only"`

### 8. Rebase ol onto Overleaf's existing history

- `git fetch overleaf master`
- If Overleaf has commits: `git stash -u` (to clear untracked), `git rebase overleaf/master`
  - If conflicts arise: resolve by taking our version (`git checkout --ours`) for all files, then `git rebase --continue`
  - `git stash pop` after rebase
- If Overleaf is empty: skip rebase

### 9. Push ol to both remotes

- `git push -u origin ol`
- `git push overleaf ol:master`
- If Overleaf rejects (no force push): the rebase in step 8 should have put us on top — report the error if it still fails

### 10. Return to main

- `git checkout main`

### 11. Report

Summarize:
- GitHub repo URL
- Overleaf project URL (`https://www.overleaf.com/project/<id>`)
- Files on `ol` branch
- Reminder: use `/ol-sync push` to sync going forward
