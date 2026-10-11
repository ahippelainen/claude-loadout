---
name: research-init
description: Sets up a new research project, or tidies an existing one, with the author's standard layout - Data/ Images/ LLM/ Numerics/ Paper/ Papers/ Submissions/ and LLM/conventions.md. In Dropbox no git; in ~/Git a git repo with a private GitHub remote. Also describes how Claude works in such a project: everything it makes goes into LLM/, the author checks and promotes. Use on "new research project", "init a research project", "set up the folders for X", /research-init. Do NOT use for hobby software, or restructuring files inside an existing project beyond adding missing folders.
---

# Research project init

Input: the project name and where it lives. `~/Dropbox/<Name>` (synced, no git) or `~/Git/<Name>` (git, private remote). If the user gives only a name, ask which.

## Layout

```
<Name>/
  Data/          raw and derived data
  Images/        figures for notes and papers
  LLM/           Claude's working files: reports, scripts it wrote, conventions.md
  Numerics/      the author's code (Mathematica .m/.wl, Python)
  Paper/         the draft and the research notes
  Papers/        literature (PDFs, lit-sweep output)
  Submissions/   one folder per submission, <YYYY-MM>_<Journal>/ (journal-port)
```

## Steps

1. If the folder exists, list what is there and create only the missing folders; never move, rename or delete existing files.
2. Create the folders and `LLM/conventions.md`:
   ```
   # Conventions
   Each entry: the convention, where it was read (file:line) or "author, <date>", and the date last checked.
   Changed entries are struck through with the date, not deleted. Axes: ~/Git/dotfiles/claude/contexts/physics-conventions.md
   ```
   followed by the axes that apply to the project (for physics: signature, curvature, action normalization, radial coordinate and boundary, units, Fourier sign, gauge and generator normalization, field normalizations, kinematics), each marked "not fixed" until the author or the draft fixes it. For an economics project, the notation and the units of the model instead.
3. `~/Git/` projects only:
   - `git init -b main` and a `.gitignore` covering LaTeX build files (`*.aux *.log *.out *.toc *.fls *.fdb_latexmk *.synctex.gz *.blg`), `venv/`, `__pycache__/`, `.DS_Store`; ask whether `Data/` is too large to track.
   - A `.gitkeep` in each empty folder so the layout survives a clone.
   - Confirm the repo name with the user, then `gh repo create <user>/<name> --private --source . --remote origin`.
   - First commit `chore: project layout`. Leave the repo off `~/Git/dotfiles/claude/push-policy`, so pushes of unpublished work stay ask-first unless the author grants standing approval.
4. Report the created paths in one line each, and whether a remote exists.

## Working in the project (the owner-in-the-loop flow)

This is the attended physics flow; the fully autonomous one is `research-autonomous`.

- **Claude writes only in `LLM/`** (one exception: `lit-sweep` puts PDFs into `Papers/` after the author approves the split). Dated scripts `LLM/YYMMDD_<Topic>.wl` (or `.py`), each with a header comment saying what it computes, from what, and what it checks; logs `LLM/run_<topic>.log` beside them; caches in `LLM/Cache/`, data in `LLM/Data/`, figures in `LLM/Images/`; draft notes, letters and section proposals as `LLM/YYMMDD_<name>.tex`. A chain of runs is a script (`LLM/run_chain.sh`) with every step time-boxed and memory-capped; Mathematica runs go through `~/Git/dotfiles/claude/tools/wlrun`.
- **Everything outside `LLM/` is the author's** (`Numerics/`, `Paper/`, the notes and the draft, `Data/`, `Images/`). Claude edits there only when the author asks for that specific change. The author checks what Claude made and promotes it: a notebook generated headlessly from `LLM/notebook_sources/*_src.wl` (skill `mathematica-notebook`) moves into `Numerics/` once he has stepped through it; text moves into `Paper/` after he has rewritten or approved it.
- **New versions, not edits:** a changed computation is a new dated script; the old one stays as the record of what an earlier result was computed with.
- **Checks before the author spends time:** conventions from `LLM/conventions.md`; a result that reproduces a published number or equation where one exists; `physics-review` (mode `verify`) for an independent recomputation in a fresh context; `derivation-note` when a step needs to be readable on paper.
- **Overnight** runs on such a project use `autonomous-loop` with the same boundary: the loop's deliverables are files in `LLM/`, and its MORNING report says what no human has checked.

