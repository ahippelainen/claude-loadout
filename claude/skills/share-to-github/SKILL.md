---
name: share-to-github
description: "Publishes a curated subset of a local project to a GitHub repository without ever attaching git to the working folder — you decide together exactly what to include, draft and hand back the README(s) and LICENSE for the author to edit, then push only the agreed files via a throwaway clone and disconnect. Triggers: share this on github, publish the code, put this project on github, make a repo for this, upload the code and data. Do NOT trigger for: routine git commit/push inside an already-tracked repo, or packaging a paper for arXiv (use arxiv-package)."
---

# share-to-github — curate, review, push, disconnect

Publishes selected files from a local project to a GitHub repo. Two design commitments make it safe:

- **The working folder is never linked to a remote.** All git happens in a throwaway clone in a temp directory; the project folder stays a plain directory with no `.git`. This is deliberate — it makes it impossible to accidentally push the whole messy working tree.
- **An explicit allowlist, copied by name.** Files are chosen deliberately and copied one set at a time. Never `cp -r` the project root; never `git add -A` a directory you haven't inventoried.

> **Repo history is permanent.** A wrong or sensitive file that lands in a commit stays in history even after deletion — the only real remedy is a brand-new repo. So every push is preceded by verification, and nothing is pushed the author hasn't seen listed.

## Phase 1 — Curate and write the meta-files (checkpoint before any push)

1. **Inventory the project.** Walk the tree. Produce an explicit **INCLUDE / EXCLUDE table**, one reason per entry. Default to EXCLUDE for: `venv/`/virtualenvs, `__pycache__/`, build artifacts (`*.aux *.log *.out *.toc *.synctex* *.blg *.bbl`), reviewer/scratch notes, the paper draft itself (link arXiv instead), `.env`/secrets, large *unused* data, redundant formats (e.g. ship `.nb` **or** `.m`, per author), and anything LLM-attributed or clearly a private working note.
2. **Licensing — code and data are separate.** Pick the code license by discussion (default MIT for research code). If data/assets are bundled, establish their provenance and license independently and **web-verify it** rather than assuming (e.g. World Bank PIP is CC-BY-4.0, not CC0). Bundled data under a share-alike/attribution license needs its own attribution + modification note.
3. **Draft the meta-files** — root `README.md`, any per-directory `README.md` (e.g. a data folder), and `LICENSE` — using **greppable placeholders** for anything unknown (`XXXX.XXXXX` for an arXiv ID, `<VERSION>` for tool versions). List every placeholder.
4. **Exposure scan on the include-set** (not the excluded files): grep for absolute paths, real emails, AI attribution ("Gemini/ChatGPT/Claude/LLM-generated"), `TODO`/`FIXME`/`XXX`, profanity or self-deprecating comments, and obvious secrets. Report hits; these are the things that make an author look careless in public.
5. **Stop.** Hand the meta-files and the INCLUDE/EXCLUDE table to the author to edit and approve. Do not proceed to push until they confirm.

## Phase 2 — Push via throwaway clone, then disconnect

Work entirely under a temp dir (the session scratchpad). Never run `git init` in the project folder.

1. **Confirm the remote and auth.** `git ls-remote <url>` to check reachability and whether the repo already has history. Confirm the SSH/HTTPS identity is the author's.
2. **If history exists, inspect it first.** Clone it; list files ever committed (`git log --all --name-only --diff-filter=A | sort -u`) so you build on the real state and catch anything already wrong (e.g. a prior truncated upload). If empty, clone gives you a bare working copy to fill.
3. **Build the tree by explicit named copies.** Create subfolders deliberately; `cp` each approved file/glob into place. Copy CSV/data directories by their contents, not by recursively copying the project.
4. **Verify the staged tree == the allowlist.** Diff the file list against the approved INCLUDE set. **Check sizes** to catch truncation and empty files (the classic failure is a large file arriving as 2 bytes). Re-run the exposure grep on the staged tree.
5. **Add a `.gitignore`** covering the junk classes so future edits stay clean.
6. **Commit and push.** A clear message; no Claude co-author trailer (matches this author's dotfiles convention). Pushing over git avoids the browser upload limit (25 MiB per file), so big directories go up in one commit; git pushes still warn above 50 MiB per file and GitHub blocks files above 100 MiB (docs.github.com, about large files, checked 2026-09-29), which need Git LFS or a release asset.
7. **Verify the pushed remote.** Re-list the remote tree (`git ls-tree -r --long origin/main` or a fresh clone) and confirm it matches the allowlist with correct sizes.
8. **Disconnect and confirm.** The temp clone can be discarded. Confirm the working folder still has **no `.git` and no remote** — it is untouched.

## Report

Give the author: the pushed file list with sizes, the repo URL, any placeholders still to fill in the READMEs, and a one-line confirmation that the local project folder was never linked to git.
