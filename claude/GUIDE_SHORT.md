# Claude Code Setup — Short Guide

Fast reach-for reference. For context, workflows, and the full decision tree, see `GUIDE.md`. For per-plugin detail, see `INDEX.md` (or `INDEX_SHORT.md`) in each subfolder.

---

## Pick the mechanism

| I want to... | Use |
|---|---|
| Automate something deterministic on every tool event | **Hook** |
| Trigger behavior by phrasing or context (needs judgment) | **Skill** |
| Type `/name` to run a fixed pipeline | **Slash command** |
| Spin up an isolated expert with its own context | **Agent** (via Agent tool) |
| Persist a permanent rule | **CLAUDE.md** (project or global) |
| Remember a fact across sessions | **Auto-memory** |

---

## Skills — short

### Auto-firing

| Skill | Fires on |
|---|---|
| `physics-review` | derivation / sanity-check / pasted LaTeX |
| `test-driven-development` | new feature or bugfix |
| `systematic-debugging` | any bug, failure, or odd behavior |
| `verification-before-completion` | about to claim "done" or commit |
| `simplify-legacy` | "clean up", "rewrite", frustration with old code |
| `brainstorming` | any non-trivial feature |
| `propose-persistence` | repeated correction, "from now on", concrete token waste |
| `deep-research-academic` | "research X for a paper" + provided papers |
| `academic-paper` | "write/draft/revise paper" |
| `academic-paper-reviewer` | "peer review", "referee report" |
| `academic-pipeline` | "full paper workflow", research-to-publication |

### Explicit

`writing-skills`, `subagent-driven-development`, `executing-plans`, `finishing-a-development-branch`, `using-git-worktrees`, `token-audit`, `agentic-engineering`.

---

## Agents — short

| Domain | Go-to agent(s) |
|---|---|
| Python write / review | `python-pro` |
| Architecture blueprint | `code-architect` |
| Phased plan | `planner` |
| Test-first | `tdd-guide` |
| Simplify recent code | `code-simplifier` |
| Migrate / modernize | `legacy-modernizer` |
| One complex bug | `debugger` |
| Recurring errors / cascades | `error-analyst` |
| Swallowed exceptions, NaN, bad fallbacks | `silent-failure-hunter` |
| Type / data-model review | `type-design-analyzer` |
| Comment accuracy audit | `comment-analyzer` |
| Auth, secrets, OWASP, incidents | `security` |
| Profiling, load testing, observability | `performance-engineer` |
| EDA, stats, time series, Bayesian | `data-analyst` |
| Derivatives, portfolio, backtesting | `quant-analyst` |

---

## Commands — short

| Command | One-liner |
|---|---|
| `/ol-sync push` | push `main`'s LaTeX to `ol` + Overleaf, pull collaborator edits back |
| `/repo-init` | bootstrap `main`/`ol` two-branch LaTeX repo |
| `/lint` | ruff fix + format on changed Python |
| `/python-review` | full review via `python-pro` |
| `/test-coverage` | close pytest coverage gaps to 80%+ |
| `/ship` | lint → test → commit → push |
| `/sync-dotfiles` | commit + push `~/Git/dotfiles` |
| `/debug` | persistent debug session with state file |
| `/map-codebase` | 4-agent parallel codebase documentation |
| `/code-review` | local diff or GitHub PR review |
| `/insights-triage` | turn `/insights` output into plugins |
| `/review-plan` | critical review of an external LLM's update plan |
| `/execute-plan` | run an approved plan via parallel worktree subagents |
| `/wave-merge` | integrate completed worktrees into main |
| `/ralph-loop`, `/cancel-ralph` | self-feeding loop and its kill switch |

---

## Hooks — short

| Hook | Purpose |
|---|---|
| `auto-commit-dotfiles.sh` | auto-commit any edit inside `~/Git/dotfiles` (coalesced 30s) |
| `ralph/stop-hook.sh` | powers `/ralph-loop` — re-injects prompt on Stop |
| `lint-on-edit.sh` (poly_bot, project-local) | ruff on edited Python |

---

## Common flows (one-liners)

- **New hobby feature:** `brainstorming` → `writing-skills` (plan) → `test-driven-development` → `/ship`.
- **Hard bug:** `/debug <description>` → resume later with `/debug continue <slug>`.
- **Unfamiliar repo:** `/map-codebase` → read `.planning/codebase/*.md`.
- **External LLM plan:** `/review-plan` → `/execute-plan` → `/wave-merge`.
- **Paper from sources:** `deep-research-academic` → `academic-paper` → `academic-paper-reviewer` → revision.
- **LaTeX + Overleaf sync:** `/repo-init` once, `/ol-sync push` every round.
