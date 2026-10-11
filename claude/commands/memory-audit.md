---
description: Audit auto-memory across projects - stale facts, duplicates, rules that belong in CLAUDE.md or a skill, journals that belong in the repo - and propose edits; run monthly
argument-hint: "[project name, or all]"
---

# Memory audit

Scope: `~/.claude/projects/*/memory/` (one project if $ARGUMENTS names it, else all). Read-only until the user approves.

1. Inventory: per project, the number of memory files, the size of `MEMORY.md` (it is loaded only up to 200 lines / 25 KB), and memory folders whose project directory no longer exists (renamed or moved projects).
2. For each project, read `MEMORY.md` and sample the files, then classify:
   - **stale**: contradicted by the code, the repo or a newer memory; dated facts about state that has moved on;
   - **duplicate**: the same fact in several files or several projects;
   - **promote**: a rule stated in two or more projects' memories, or one marked as applying beyond the project → the global `~/Git/dotfiles/claude/CLAUDE.md`, a rules file or a skill (propose the exact lines);
   - **move to the repo**: long journals, audit logs and result ledgers that are project documentation rather than memory;
   - **keep**.
3. Present one table per project (file, class, one-line reason, proposed action), plus the cross-project promotions first.
4. Apply only what the user approves: edit or delete memory files, update each `MEMORY.md` index, and write promoted rules through `propose-persistence`. Corrected facts get the date in the file.
