# Claude Code Setup Guide

Personal reference for this Claude Code configuration. When in doubt: look here first, then check the INDEX.md in the relevant subfolder for full descriptions.

---

## Directory layout

```
~/Git/dotfiles/claude/
├── GUIDE.md          ← you are here
├── CLAUDE.md         ← global behavioral rules (always loaded)
├── commands/         ← slash commands (/name triggers these)
│   └── INDEX.md
├── skills/           ← description-triggered or explicit behavior modules
│   └── INDEX.md
├── agents/           ← spawnable subagents (via Agent tool or commands)
│   └── INDEX.md
├── hooks/            ← automated shell actions on tool events
│   └── INDEX.md
├── rules/            ← coding standards (common/, python/)
└── contexts/         ← domain context files
```

`~/.claude/` symlinks into this repo — editing here is live immediately.

---

## What to reach for

### "I want Claude to do X automatically"
→ **Hook** — no model judgment needed (e.g. run linter after every edit)
→ **Skill with auto-trigger** — judgment needed (e.g. enforce TDD on new features)
→ **CLAUDE.md rule** — simple behavioral preference (e.g. "no docstrings")

### "I want to invoke X explicitly"
→ **Slash command** — multi-step pipeline you type often (`/ship`, `/debug`)
→ **Skill** — mode of behavior to activate (`brainstorming`, `simplify-legacy`)
→ **Agent** via Agent tool — isolated subagent with its own context window

### "I want to remember something across sessions"
→ **Auto-memory** (`~/.claude/projects/.../memory/`) — session facts that change
→ **CLAUDE.md** — permanent behavioral rules

### "I want to create new plugins"
→ `/insights-triage` — parses `/insights` output and proposes what to build
→ `propose-persistence` skill — fires when conversation signals something worth encoding
→ `writing-skills` skill — guidance for authoring new skills and plans
→ `brainstorming` skill — design before implementation

---

## Workflows

### Hobby coding (poly_bot, bots, scripts)

**New feature:**
```
brainstorming skill (design) → writing-skills skill (plan) → code with test-driven-development → /ship
```

**Hard bug:**
```
/debug [description] → follow checkpoint prompts (sessions survive context resets)
```

**Unfamiliar codebase:**
```
/map-codebase → produces .planning/codebase/{STACK,INTEGRATIONS,ARCHITECTURE,STRUCTURE,CONVENTIONS,TESTING,CONCERNS}.md
```

**Large autonomous task (multi-step plan):**
```
subagent-driven-development skill → fresh subagent per task → two-stage review → finishing-a-development-branch
```

### Science work (hep-th, LaTeX papers)

**Physics derivation check:**
Say "check this derivation", "sanity check", or paste LaTeX → `physics-review` skill auto-fires.
Returns: summary of claim → checks passed → concerns with confidence levels (Confirmed / Likely correct / Uncertain / Do not know) → suggested next step.

**Literature search + bibliography:**
```
deep-research-academic skill → INSPIRE-HEP verified BibTeX → Schema 1 handoff
```
Never produces BibTeX from memory — every entry verified against INSPIRE-HEP or flagged UNVERIFIED.

**New LaTeX project with Overleaf:**
```
/repo-init → two-branch structure (main + ol) + GitHub + Overleaf remotes
/ol-sync push → sync main's LaTeX files to ol and Overleaf, pull collaborator edits back
```

---

## Skills reference

### Auto-firing (no explicit invocation needed)

| Skill | Fires when |
|---|---|
| `physics-review` | "check derivation", "sanity check", pasted LaTeX for correctness |
| `test-driven-development` | Writing new features or fixing bugs |
| `systematic-debugging` | Any bug, test failure, or unexpected behavior |
| `verification-before-completion` | About to claim work is done, commit, or create PR |
| `simplify-legacy` | "clean up", "rewrite", "simplify", expressed frustration with existing code |
| `propose-persistence` | Repeated correction, "from now on", 3× manual ritual, concrete token waste |
| `brainstorming` | Before any non-trivial feature |
| `deep-research-academic` | "research X for a paper" when papers are provided |
| `academic-paper` | "write / draft / revise paper" |
| `academic-paper-reviewer` | "peer review", "referee report" |
| `academic-pipeline` | "full paper workflow", research-to-publication |

### Explicit invocation

| Skill | When to reach for it |
|---|---|
| `writing-skills` | Writing an implementation plan, or authoring a new skill |
| `subagent-driven-development` | Executing a plan with per-task fresh subagents |
| `executing-plans` | Executing a plan step-by-step in the same session |
| `finishing-a-development-branch` | Branch complete — merge, PR, or discard |
| `using-git-worktrees` | Isolated feature branch with safety checks |
| `token-audit` | Session getting expensive; find and fix structural waste |
| `agentic-engineering` | Building multi-agent systems, eval-first design, model routing |

---

## Agents reference

Full descriptions in `agents/INDEX.md`. Quick routing guide:

**Python code work:**
`python-pro` (write/review), `tdd-guide` (test-first), `code-architect` (blueprint), `planner` (phased plan)

**Refactoring and cleanup:**
`code-simplifier` (clarity), `legacy-modernizer` (incremental migration)

**Debugging:**
`debugger` (individual bug, scientific method), `error-analyst` (recurring patterns, cascades), `silent-failure-hunter` (swallowed exceptions, NaN propagation)

**Code quality:**
`python-pro` (full review), `type-design-analyzer` (invariants, pydantic v2), `comment-analyzer` (accuracy and staleness)

**Security:**
`security` (OWASP, secrets, infra hardening, incident response)

**Performance:**
`performance-engineer` (profiling, load testing, observability)

**Data / quant:**
`data-analyst` (EDA, statistics, time series, Bayesian), `quant-analyst` (derivatives, backtesting, portfolio)

---

## Commands reference

Full descriptions in `commands/INDEX.md`. Quick reference:

| Command | One-liner |
|---|---|
| `/ship` | lint → test → commit → push |
| `/sync-dotfiles` | commit + push ~/Git/dotfiles |
| `/lint` | ruff fix + format on changed Python files |
| `/python-review` | full review via python-pro agent |
| `/test-coverage` | find gaps, generate missing pytest tests to 80%+ |
| `/ol-sync push` | sync main's LaTeX → ol → Overleaf, pull collaborator edits back |
| `/repo-init` | two-branch repo + GitHub + Overleaf setup |
| `/debug` | persistent debugging session with state file |
| `/map-codebase` | 4-agent parallel codebase documentation |
| `/code-review` | local diff review or GitHub PR review |
| `/insights-triage` | parse /insights report → propose + implement plugins |

---

## Hooks reference

| Hook | Event | What it does |
|---|---|---|
| `auto-commit-dotfiles.sh` | PostToolUse (Edit/Write) | Auto-commits any write to `~/Git/dotfiles`; coalesces within 30s |
| `ralph/stop-hook.sh` | Stop | If `.claude/ralph-loop.local.md` exists: blocks session exit and re-injects the prompt for next iteration |

**Ralph loop**: The long-running task mechanism. Activated by `/ralph-loop [description]`. Intercepts session stop and feeds the same prompt back. Runs until Claude outputs `<promise>TEXT</promise>` matching `--completion-promise TEXT`, or `--max-iterations N` is reached. Cancel with `/cancel-ralph`. State file: `.claude/ralph-loop.local.md` in the project root.

---

## Adding new plugins

| Want to add... | Where it goes | How |
|---|---|---|
| Triggered behavior needing judgment | `skills/` | `writing-skills` skill |
| Automated tool-event action | `hooks/` | shell script + `settings.json` entry |
| Multi-step pipeline you type explicitly | `commands/` | `.md` file with frontmatter |
| Project-specific fact | project `CLAUDE.md` | edit directly |
| Permanent behavioral preference | `~/.claude/CLAUDE.md` | edit directly |
| Session fact for future recall | auto-memory | `propose-persistence` skill |

The `propose-persistence` skill fires automatically on strong signals and surfaces one concrete proposal at a time. `/insights-triage` does the same from a `/insights` report.
