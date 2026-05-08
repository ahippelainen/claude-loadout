# Commands Index

## LaTeX / Overleaf

| Command | Trigger | Description |
|---|---|---|
| `/ol-sync` | Explicit, argument: `push` | Syncs `main` ↔ `ol` ↔ Overleaf. The repo has two branches: `main` (everything) and `ol` (LaTeX-only, tracked by Overleaf as `master`). The list of paths to sync lives in `.ol-sync` at the repo root. **`/ol-sync push`**: fetch Overleaf's `master` → checkout `ol` → merge Overleaf changes (stop on conflicts, never auto-resolve) → overwrite `ol` with each path from `.ol-sync` taken from `main` → commit → push to both `origin ol` and `overleaf master` → return to `main` → cherry-pick any collaborator edits back into `main` → push `main`. Reports commit hashes and which files changed. |
| `/repo-init` | Explicit, run from new project directory | Interactive setup of the standard two-branch repo structure. Asks for: GitHub remote URL, Overleaf project ID, and which files/dirs belong in `.ol-sync`. Then: `git init -b main`, creates `.gitignore` (LaTeX artifacts, Python cache, Figures/*.pdf exception), creates `.ol-sync`, initial commit, adds `origin` and `overleaf` remotes, pushes `main`, creates orphan `ol` branch with only the synced files, rebases onto Overleaf's existing history (resolves conflicts by taking our version), pushes `ol` to both remotes, returns to `main`. Reports final state and reminds to use `/ol-sync push` going forward. |

---

## Python

| Command | Trigger | Description |
|---|---|---|
| `/lint` | Explicit, optional path argument | Runs ruff on changed Python files (or a given path). Steps: find modified `.py` files via `git status` → `ruff check --fix` → `ruff format` → `ruff check` again to surface anything that couldn't be auto-fixed. Lists remaining issues as `file:line — rule — message`. Does not run tests, commit, or push. |
| `/python-review` | Explicit, optional path argument | Dispatches the `python-pro` agent for a full review of changed `.py` files (or a given path). The agent runs mypy, ruff, black --check, bandit, and pip-audit, then grades findings: CRITICAL (SQL injection, command injection, eval on input, hardcoded secrets, yaml.load, bare except), HIGH (missing type hints, mutable defaults, blocking calls in async, N+1 queries), MEDIUM (PEP 8, None comparison, print vs logging). Blocks on CRITICAL or HIGH. |
| `/test-coverage` | Explicit, optional path argument | Runs `pytest --cov=. --cov-report=term-missing`, lists files below 80% coverage sorted worst-first, then generates missing tests in priority order: happy path → error paths → edge cases → branch coverage. Rules: follow existing test naming conventions, use `pytest.approx` for numerical assertions, each test independent. Re-runs coverage after to verify improvement. Reports before/after table. |

---

## Git & Shipping

| Command | Trigger | Description |
|---|---|---|
| `/ship` | Explicit, optional commit message argument | Lint → test → commit → push in one step. Pre-check for live-trading repos (poly_bot): confirms no `LIVE_TRADING_ENABLED=true` in staged content. Steps: `git status` → run ruff (Python projects) → run `pytest` (stops on failure, does not commit failing code) → read diff → `git add -A` → commit with `$ARGUMENTS` or a generated one-liner → `git push`. Stops at the first failure and surfaces it. No Claude co-author trailer. |
| `/sync-dotfiles` | Explicit | Commits and pushes `~/Git/dotfiles`. Steps: fetch origin → show uncommitted changes → if any, diff then commit with a descriptive one-liner → rebase onto `origin/main` (abort and report on conflicts) → push. Reports final commit hash and message. Does not run linters. |

---

## Debugging & Exploration

| Command | Trigger | Description |
|---|---|---|
| `/debug` | Explicit, argument: issue description, `list`, or `continue <slug>` | Persistent debugging session backed by a state file at `.planning/debug/<slug>.md`. **New session**: gathers symptoms (expected vs actual, error messages, reproducibility) → creates session file → dispatches `debugger` agent → updates file with evidence and eliminated hypotheses after each iteration → marks resolved when root cause found. **`list`**: shows active sessions with current hypothesis and next action. **`continue <slug>`**: resumes from saved state. Sessions survive context resets. |
| `/map-codebase` | Explicit, optional focus area argument | Spawns 4 parallel Explore agents to document an unfamiliar codebase. Each agent writes directly to `.planning/codebase/`: Agent 1 → `STACK.md` + `INTEGRATIONS.md`; Agent 2 → `ARCHITECTURE.md` + `STRUCTURE.md`; Agent 3 → `CONVENTIONS.md` + `TESTING.md`; Agent 4 → `CONCERNS.md`. Checks for existing map first and asks whether to refresh. Reports which documents were written and their sizes. |

---

## Code Review

| Command | Trigger | Description |
|---|---|---|
| `/code-review` | Explicit, optional PR number/URL argument | Two modes. **Local** (no argument): reviews uncommitted changes — checks for hardcoded credentials, nesting > 4 levels, missing error handling, TODO/FIXME. Blocks on CRITICAL or HIGH. **PR mode** (PR number or URL): fetches diff via `gh pr diff`, reads full file contents at head revision, applies a 6-category checklist (Correctness, Type Safety, Pattern Compliance, Performance, Completeness, Maintainability), runs available validators (pytest for Python), decides APPROVE / REQUEST CHANGES / BLOCK, writes review artifact to `.claude/PRPs/reviews/pr-<N>-review.md`, and posts the review to GitHub via `gh pr review`. |

---

## Dotfiles

| Command | Trigger | Description |
|---|---|---|
| `/insights-triage` | Explicit, paste insights report as argument or have it in context | Two-phase workflow for turning `/insights` report output into persistent plugins. **Phase 1 (read-only)**: extracts signals from the report — explicit plugin suggestions, CLAUDE.md additions, friction patterns → hook candidates, repeated manual patterns → command candidates, validated workflows → skill candidates. Presents a numbered triage table and waits for approval. **Phase 2 (implement)**: for each approved item, creates the skill/command/hook/CLAUDE.md addition following dotfiles conventions, then calls `/sync-dotfiles` to commit everything. |

---

## Trading Bot / Codebase Review

| Command | Trigger | Description |
|---|---|---|
| `/review-plan` | Explicit, argument: what was analyzed (or path to plan doc) | Two-layer critical review of an external LLM's update/analysis plan. Locates the plan document (checks `$ARGUMENTS` path → `docs/UPDATES_PLAN.md` → most recent `.md` in `docs/`), then spawns a general-purpose subagent that reads the actual source files and evaluates each proposed change on two axes: **Problem Validity** (is the problem real, is the evidence sound, is the impact calibrated?) and **Solution Quality** (right approach, simpler alternatives, new problems introduced, ordering constraints). Output: per-issue verdict blocks (Problem valid? / Solution sound? / Recommendation) plus a prioritized action list with risk ratings. Ends by prompting `/execute-plan`. |
| `/execute-plan` | Explicit, optional path to plan doc | Executes an approved update plan using parallel worktree subagents. Locates the plan (same priority logic as `/review-plan`). If a `/review-plan` report is in context, filters out "Skip" items and prompts for confirmation on "Redesign" items. Partitions remaining items by file overlap (disjoint → parallel groups, overlapping → same agent), prints the partition before spawning. Spawns one worktree subagent per group using the specialist type matching the change (python-pro, debugger, code-architect, general-purpose). Each agent receives: exact items to implement, exhaustive list of files it may touch, ordering constraints, and instructions to run `pytest -x -q` and not add unnecessary comments. After all agents finish, reviews each worktree's `git diff main...HEAD` directly (not via subagent), checks for unintended changes, then applies clean diffs and commits. Reports applied/skipped/pending items, test results, and commit hash. |
| `/wave-merge` | Explicit, optional commit-message-prefix argument | Integration step after parallel agent worktrees finish — use with `/execute-plan` or other fan-out workflows. Iterates over `.claude/worktrees/*/` with uncommitted changes, inspects each diff, fixes stale imports after the refactor, runs tests, and commits per agent. Surfaces conflicts instead of auto-resolving. |

---

## Long-running Loops

| Command | Trigger | Description |
|---|---|---|
| `/ralph-loop` | Explicit, argument: prompt text, optional `--max-iterations N` and `--completion-promise TEXT` | Starts a Ralph Wiggum loop in the current session: after each Stop, the stop-hook blocks exit and re-injects the prompt for another iteration. State lives in `.claude/ralph-loop.local.md` in the project root. Loop terminates on `--max-iterations` reached or when Claude emits `<promise>TEXT</promise>` matching `--completion-promise`. Pairs with `/cancel-ralph`. |
| `/cancel-ralph` | Explicit | Cancels the active Ralph loop by deleting `.claude/ralph-loop.local.md`. Safe to run even if no loop is active. |

---

## Adding new commands

Place `.md` files with YAML frontmatter (`description`, `argument-hint`) in this directory and add a row to the appropriate section above.
