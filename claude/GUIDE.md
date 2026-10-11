# Claude Code setup: guide

How this setup is meant to be used. The full list of skills, agents, commands and hooks, with one line each, is the generated `INDEX.md`.

## What to reach for

| I want… | Mechanism |
|---|---|
| Something to happen on every tool event, no judgement needed | Hook (`hooks/`, wired in `settings.json`) |
| Behaviour that switches on by context or phrasing | Skill (`skills/<name>/SKILL.md`) |
| A pipeline I start by typing `/name` | Command (`commands/`) |
| An expert in a fresh context, in parallel or for review | Agent (`agents/`) |
| A rule for every session | `CLAUDE.md` |
| A fact that may change, remembered across sessions | Auto-memory (per project) |

When something should persist, `propose-persistence` picks the bucket and drafts it; it also runs a token audit of a session or triages an `/insights` report on request.

## Workflows

### Research (hep-th, holographic QCD, economics of inequality)

- **New project**: `/research-init` lays out `Data/ Images/ LLM/ Numerics/ Paper/ Papers/ Submissions/` (notes live in `Paper/`, Claude's files in `LLM/`) and `LLM/conventions.md`; in `~/Git` it also makes a git repo with a private remote, pushes ask-first.
- **Conventions**: each project keeps `LLM/conventions.md`; the physics agents read it, ask when something is unfixed, and record what gets established (`contexts/physics-conventions.md`). No agent carries default conventions.
- **Checking a derivation**: `physics-review` (fires on "check this derivation"; mode `verify` recomputes independently in a fresh context and reports agreements and disagreements, mode `gap-finding` lists what a coauthor would object to); `derivation-note` writes a fully explicit companion note compiled with the draft's preamble, never touching the draft; for long variations `fluctuation-analyst`, for radial ODEs and spectra `radial-ode-specialist`, for importing a formula from a paper `convention-translator`, for model building and the dictionary `holographist`.
- **Mathematica**: `mathematica-pro` for scripts and review, `mathematica-notebook` for `.nb` files. Runs go through `tools/wlrun <seconds> <file>` (KILL timeout, memory cap, licence retry, no surviving kernel); `rules/mathematica.md` (loaded when Mathematica files are touched) holds the traps met so far.
- **Economics models**: `academic-economist` referees a model idea or draft; `data-analyst` for the data work.
- **Literature**: `lit-sweep` (parallel strands, each source tagged, bibliography only from INSPIRE or Crossref via `skills/lit-sweep/inspire.py`); `/cite-check` for missing, unused and wrong bibliography entries.
- **Writing**: `academic-paper` (drafting, revision, referee responses), `draft-sections` (introduction, conclusions recap, appendices as text to rewrite), `academic-paper-reviewer` (simulated review), `academic-pipeline` (the three in sequence with checkpoints).
- **Submitting**: `journal-picker` → `journal-port` → `arxiv-package` → `share-to-github` for code and data.
- **The attended flow (physics)**: Claude works only in the project's `LLM/` (dated scripts, logs, caches, generated notebooks, draft text); everything outside is yours to check and promote into `Numerics/` and `Paper/` (`research-init`, section "Working in the project").
- **Autonomous programs (mathematics)**: `research-autonomous` sets up and runs a program that lives for weeks from a folder and a problem: `CHARTER.md` with [K]/[V]/[H] tags, ledgers IDEAS → CANDIDATES → VERIFIED (tiers V0–V3) / KILLED, task cards, fresh adversaries, nightly compute by cron, hourly watchdog, headless orchestrator rounds, daily literature watch, `roadmap/roadmap.py`, lecture and companion notes for your sign-off. Only V3 (you understood it end to end) is publishable.
- **Long unattended runs**: `autonomous-loop` (research nights) and `general-loop` (software builds) share `skills/autonomous-loop/rails.md`: a session cap across nesting, the orchestrator under `/goal` plus a check-in every 30 min (so a quota reset does not leave it idle), fresh agents per round, guard scripts, protected checks (`LOOP/protected.txt`, enforced by a hook) and independent verification before anything is called proved.

### Hobby coding (bots, tools, websites)

- Writing and review: `python-pro`; debugging: `systematic-debugging` and the `debugger` agent; test-first on request: `test-driven-development`.
- `/lint` (ruff), `/ship` (lint, test, commit, push if the repo's push policy allows).
- An external LLM's plan: `/external-plan review`, then `execute`, then `merge`.
- `security` before publishing a repo or when a key may have leaked; `architecture-reviewer` for a design; `ui-designer` for a design pass on a site or app; `quant-analyst` and `qual-analyst` for the trading projects.

### Maintaining the setup

- `/sync-dotfiles`: fold auto-commits into real commits, run `tools/check.py`, push.
- `/memory-audit` (monthly): stale, duplicated or misplaced memories across projects, and rules that belong in CLAUDE.md.
- `tools/check.py`: regenerates `INDEX.md` and reports bad frontmatter, dangling paths and missing hook targets; `install.sh` runs it too.
- Built in: `/doctor prompt-audit` for stale or contradictory instructions, `/insights` for a usage report.

## Safety rails

- **Pushes** (`hooks/bash-guard.py`): repos listed `free` in `push-policy` push freely; any other repo needs your explicit yes, recorded for that exact commit; `--no-verify` is refused.
- **Mathematica** (`hooks/bash-guard.py`): a Wolfram program started without `wlrun` or `timeout -s KILL` is refused. **Leftovers** (`hooks/stray-processes.py`): before Claude finishes, kernels and LaTeX runs it started, and orphaned ones, are listed for it to kill.
- **LaTeX** (`hooks/chktex.sh`): after each `.tex` edit, chktex's substantive warnings go back to Claude.
- **Loops** (`hooks/protect-checks.py`): while `LOOP/protected.txt` exists, the files it lists cannot be edited.
- **Dotfiles history**: `hooks/auto-commit-dotfiles.sh` commits each edited file locally and never pushes. No attribution trailers anywhere (`attribution` in settings).
- **Transcripts** are kept 365 days (`cleanupPeriodDays`), so past sessions stay available for audits.
- **Connectors**: the unused claude.ai Gmail, Calendar and Drive connectors are blocked (`deniedMcpServers`).
