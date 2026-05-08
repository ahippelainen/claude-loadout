# Skills Index

## Science / Academic

| Skill | Trigger | Description |
|---|---|---|
| `physics-review` | Auto on "check derivation", "sanity-check", "review this section", pasted LaTeX for correctness | Rigorous review of physics and math content. Enforces no silent approximations, explicit convention declarations, dimensional and index checks on every expression, and a four-level confidence labeling system (Confirmed / Likely correct / Uncertain / Do not know). Output structure: summary of claim → checks passed → concerns with confidence levels → suggested next step. Scope: AdS/CFT, holography, GR, QFT, hep-th. Does NOT fire for LaTeX formatting or bibliography work. |
| `deep-research-academic` | Explicit, or auto on "research X for paper" when papers are provided | Stage 1 of the academic writing pipeline. Takes provided papers (`.tex`, `.pdf`, `.txt`, arXiv IDs) and produces a structured Schema 1 handoff for `academic-paper`. Process: extract metadata and central results from each paper → verify every BibTeX entry against INSPIRE-HEP via WebSearch (never from memory; unverified entries flagged `UNVERIFIED`) → synthesize research landscape (full mode) → output Research Question, Key References, Bibliography, Coverage Assessment. Two modes: `full` (new paper project) and `quick` (bibliography only). |
| `academic-paper` | Auto on "write paper", "draft paper", "paper outline", "write abstract", "revise paper", "parse reviews" | Stage 2 of the academic writing pipeline. Structured paper writing for theoretical physics and quantitative interdisciplinary science. Default output: RevTeX4-2 LaTeX + BibTeX. Target journals: JHEP, PTEP, SciPost Physics, PRD, PRE, PRL. Citation preference: INSPIRE-HEP. Modes: full, plan, outline, revision, revision-coach, abstract, lit-review, citation-check, format-convert. Does NOT fire for pure literature survey or reviewing someone else's paper. |
| `academic-paper-reviewer` | Auto on "review paper", "peer review", "referee report", "critique this paper", "simulate review" | Simulates multi-perspective peer review. Five independent reviewer personas: EIC + 3 peer reviewers + Devil's Advocate. Auto-identifies field (hep-th, econophysics, statistical physics, etc.) and configures reviewers accordingly. Modes: full, re-review, quick, methodology-focus, guided. READ-ONLY — reviewers examine and report in separate documents; never modify the manuscript. Does NOT fire for writing or revising. |
| `academic-pipeline` | Auto on "academic pipeline", "research to paper", "full paper workflow", "end-to-end paper" | Lightweight orchestrator for the full research-to-publication workflow: deep-research-academic → academic-paper → academic-paper-reviewer → revision → re-review → finalize. Detects current stage, dispatches the right skill, manages transitions, enforces checkpoints. Does no substantive work itself. Do NOT use for single-step tasks — invoke individual skills directly. |

---

## Implementation Workflow

| Skill | Trigger | Description |
|---|---|---|
| `brainstorming` | Explicit, or auto before any non-trivial feature | HARD-GATE: no code before design approval. Five-step process: explore project context → ask clarifying questions one at a time → propose 2–3 approaches with trade-offs → present design and get approval → invoke `writing-skills` to produce a plan. Terminal state is always `writing-skills`. Does not write code. |
| `writing-skills` | Explicit | Two parts in one skill. **Part 1 — Plans:** produce concrete TDD-driven implementation plans with exact file paths, complete code blocks, and no placeholders; includes self-review checklist for spec coverage and name consistency. **Part 2 — Skills:** guidance for creating new Claude skills — SKILL.md structure, frontmatter rules, the CSO (Claude Search Optimization) rule that descriptions must state triggering conditions only and never summarize workflow, and file organization conventions. |
| `test-driven-development` | Auto on new features or bugfixes | Enforces RED→GREEN→REFACTOR. Iron Law: no production code without a failing test first. Requires watching the test fail for the right reason before writing implementation. Mandatory verification at each stage via `pytest`. Git checkpoints at each phase. Python patterns included. Does NOT fire for prototypes or config files. |
| `subagent-driven-development` | Explicit | Executes an implementation plan by dispatching a fresh subagent per task (no session context pollution). Two-stage review per task: spec compliance first (did the implementer build exactly what was asked?), then code quality. Implementer reports one of four statuses: DONE / DONE_WITH_CONCERNS / NEEDS_CONTEXT / BLOCKED — each has a defined handling path. Model routing by task complexity (Haiku → Sonnet → Opus). Ends with `finishing-a-development-branch`. |
| `executing-plans` | Explicit | Load a written plan, review it critically, execute tasks step by step with verifications, stop and ask when blocked. Ends by invoking `finishing-a-development-branch`. Prefer `subagent-driven-development` if subagents are available. |
| `finishing-a-development-branch` | Explicit, called by subagent-driven-development and executing-plans | End-of-branch workflow. Verifies tests pass, then presents exactly four options: merge locally / push + create PR / keep as-is / discard. Handles each path including worktree cleanup. Requires typed "discard" confirmation before destroying work. |
| `using-git-worktrees` | Explicit, called before plan execution | Creates an isolated git worktree for feature work. Priority: use existing `.worktrees/` or `worktrees/` directory → check CLAUDE.md preference → ask. Safety: always verify the directory is in `.gitignore` before creating a project-local worktree. Runs project setup and baseline tests; reports ready only if baseline is clean. |

---

## Debugging and Quality

| Skill | Trigger | Description |
|---|---|---|
| `systematic-debugging` | Auto on any bug, test failure, or unexpected behavior | Four-phase process: (1) root cause investigation — read errors, reproduce, check recent changes, add diagnostic logging at component boundaries; (2) pattern analysis — find working comparisons, list every difference; (3) single hypothesis + minimal test; (4) implement fix and verify. Hard rule: no fixes before Phase 1 complete. After 3 failed fixes, stop and question the architecture rather than attempting a 4th. Supporting files: `root-cause-tracing.md` (backward call-chain tracing), `defense-in-depth.md` (multi-layer validation). |
| `verification-before-completion` | Auto before any completion claim, commit, or PR | Iron Law: no completion claim without fresh verification evidence in the same message. Five-step gate: identify the proving command → run it → read full output → verify → then claim. Table of what each common claim actually requires (tests pass, build succeeds, bug fixed, agent completed, requirements met). Red flags: "should", "probably", trusting agent reports without checking the diff. |

---

## Dotfiles Self-Improvement

| Skill | Trigger | Description |
|---|---|---|
| `propose-persistence` | Auto on strong signals (repeated correction, "from now on", 3× manual ritual, concrete token waste); explicit on "should we save this?" | Triage layer for deciding what deserves to outlive the current session. Six buckets: skill (context-triggered behavior) / hook (automated tool-event action) / slash command (manual pipeline) / project CLAUDE.md (project-specific fact) / global CLAUDE.md (always-on rule) / auto-memory (ephemeral fact for future sessions). Produces one concrete proposal per signal: what was noticed, which bucket, full draft content ready to approve. Does not propose multiple items at once. Does not nag if skipped. |
| `token-audit` | Explicit only — fires on "token audit", "audit this session", "where did we waste tokens" | Retrospective review of the current session for structural token waste. Scans for: repeated file reads, raw tool output in main context that should have been a subagent summary, manual rituals that could be hooks or commands, over/under-delegation, chatty narration. Produces the top 3 highest-leverage findings with estimated cost and a concrete fix draft for each. Hands off to `propose-persistence` for implementation. Does NOT auto-fire. |
| `writing-skills` | Explicit | (See Implementation Workflow above — also covers skill authoring.) |

---

## Code Maintenance

| Skill | Trigger | Description |
|---|---|---|
| `simplify-legacy` | Auto on "clean up", "rewrite", "simplify", "this was LLM-written", or expressed frustration with existing patterns | Rewrite mode: existing patterns are suspect, not sacred. Rules: delete abstractions that exist only from confusion, inline single-call wrappers, strip defensive handling for conditions that can't occur, delete unused shims and dead branches. Before cutting: grep all call sites, check test coverage, skim git log for hidden constraints. State the deletion plan before removing >20 lines. Scope stays tight — only what the user pointed at. |
| `agentic-engineering` | Explicit | Operating principles for AI-heavy engineering workflows. Eval-first: define capability and regression evals before executing, re-run after. Task decomposition: 15-minute units, each independently verifiable with a single dominant risk. Model routing: Haiku for boilerplate/narrow edits, Sonnet for implementation, Opus for architecture/root-cause. Session strategy: fresh session after major phase transitions, compact after milestones. Review focus for AI-generated code: invariants, error boundaries, security assumptions, hidden coupling. |
