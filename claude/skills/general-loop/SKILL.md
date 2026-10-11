---
name: general-loop
description: Use when orchestrating a multi-wave software build with worker subagents, attended or unattended — "general loop", "dev loop", "build loop", "orchestrate this build", "send agents to code this", or "run overnight", "burn my usage", "until usage runs out", "I'm going to sleep" when the deliverable is a working repo. Do NOT use for research, analysis or numerical-computation loops ("research loop", "orchestrate the research", results or notes as the deliverable): that is autonomous-loop (or research-autonomous for a program that lives for weeks). Not for a single coding task or a change small enough to do inline.
---

# General Loop

**Load first:** read `~/Git/dotfiles/claude/skills/autonomous-loop/rails.md` in full at the start of every general-loop. Budget, context, guards, protected checks, verification and commit/push rails apply attended or not; its setup (§0) and staying-alive (§2) sections apply whenever the owner is away. This file adds only what is specific to builds.

Spec-as-contract + small verified waves + orchestrator-reviews-every-diff. The orchestrator plans, briefs, reviews, patches and commits; worker agents write the code. Proven in run #1 (voteforlunch, night of 2026-08-23→24: empty repo → deployment-ready Django/PostGIS app in 5 build waves + a design pass + an adversarial final review; ~106 tests green in CI; zero critical findings at the end; 15 commits).

## When to Use

- Building or substantially extending a codebase via subagents, attended or overnight.
- NOT for: research/analysis runs (autonomous-loop); a single task (dispatch one agent); changes small enough to do inline.

## Phase 0 — the contract

No code until the design docs are finished and adversarially reviewed:

1. Finalize the spec docs. Close every open decision or explicitly assign it; record rejected
   alternatives and deferred ideas in the docs so nothing is re-litigated by an agent.
2. Dispatch an **architecture-review agent over the docs themselves** before any code. Tell it
   what you already found so it hunts elsewhere. Run #1's reviewer returned 45 real defects —
   including code sketches inside the docs that could not run (a cookie helper nothing
   consumed, a polling fragment that deleted its own attributes) and an ORM lookup that
   compiled to the exact seq-scan the same doc warned against.
3. Fold findings in, commit. From here the docs win over any brief: every agent is told
   "READ the docs FIRST; where this brief and the docs conflict, the docs win."
4. Write `LOOP/protected.txt` (rails §5): the test files, fixtures and the expected-failure
   count file (below) that the build is judged by.

The test: a coding agent must never have to guess. Every guess an agent makes silently is a
defect you find later.

## The wave loop

1. Slice work into waves ≈ one agent-session each, ordered by the build-order in the docs.
   Parallel waves ONLY on provably disjoint file sets (down to individual files, not dirs),
   and never more live agents than the cap in rails §1.
2. Brief per the template below; launch in background; overlap your own work with agent latency.
3. On report: **verify every claim yourself** — re-run the verification commands, read the
   critical files fully (anything touching security, money, or a stated invariant), skim the
   rest. Patch small defects inline; bounce structural ones back to the same agent via
   SendMessage while its context is still small, otherwise brief a fresh agent (rails §3).
4. Commit per wave by explicit path (rails §7). Push, where push-policy allows, so remote CI
   verifies what the local box can't.
5. Update owner-facing docs/memory; launch the next wave(s).

## The brief template (what made the workers behave)

- **READ FIRST:** contract docs by section number; the existing files it builds on; "the docs
  win over this brief".
- **Deliverables** as a numbered list of concrete files with per-file content requirements.
- **SCOPE LIMIT** naming known blockers ("do NOT create X — it needs lib Y, absent; verified:
  <exact error>") so the agent doesn't burn its session rediscovering them.
- **VERIFY:** exact commands + "paste evidence in your report" + the protected-checks and
  honest-abort clause of rails §5.
- **HARD CONSTRAINTS:** "Touch ONLY: <file list>"; no README/markdown files; comments only for
  non-obvious WHY; no defensive handling for impossible states; no features beyond the list;
  never run git; explicit network allowlist; `model`, wall-clock and turn caps, subagent slots
  (default 0) per rails §1.
- **FINAL REPORT format:** files created; verbatim verification tails; "ambiguities resolved,
  one line each"; "deviations from docs/brief with one-line reasons".

The ambiguity/deviation lines are where the value concentrates: run #1's agents surfaced a
tally-signature flaw (unrated candidates would vanish instead of scoring 0), a varchar(8)
column that fit the test country but would abort a planet-scale load, and Django's
`cache.incr()` silently resetting TTLs — all in those two report sections.

## Verification topology

- Tier the tests: pure-logic (no DB, runs anywhere), integration (marked), environment-bound
  (marked, e.g. `postgis`). The local gate is the fast tier; the marked tiers run where their
  environment exists.
- **What the local box can't run, CI runs.** Wire tests-on-every-push with service containers
  before you need them. Run #1 had no local Docker or Postgres all night; CI's PostGIS was the
  only real database, and the loop never once blocked on the missing dependency.
- Find a cheap local approximation for fast iteration (run #1: a 3-line sqlite stub patching
  `geo_db_type`) and record its **expected-failure count**. "Exactly 8 expected failures" is a
  checkable invariant — a 9 means the last change broke something real.

## Function, then design

Ship the UI ugly-but-tested first. Then a **design-only pass** restricted to templates/styles,
briefed with a hard behavioral-contract list: every id, class, attribute, and exact string
that tests or client behavior depend on — enumerated by the functional implementer in its
report ("for the design pass — behaviour depends on these") and pasted into the design brief
verbatim. Run #1's design pass restyled every page and broke nothing, proven by the same suite.

## Final adversarial review

One fresh-context agent, whole repo vs the contract docs, advisory-only: trace each stated
invariant to enforcing code (file:line) or declare it unenforced; actively construct bypass
attempts; audit posture claims (privacy, security) against what the code actually persists;
end with ranked findings + a deployability verdict. Orchestrator fixes, re-verifies, final CI.
Run #1: no criticals, 14 real findings — the best one caught the codebase violating its own
written privacy contract (plaintext IPs at rest in a cache table whose rows outlive the
rate-limit window).

## Unattended operation

Rails §0, §2 and §8 in full (permission probe, `/goal` plus recurring check-in, guards, LOOP/
state with a regenerated MORNING.md). Additionally:

- **Abort criteria** (rails §0) for builds: critical failure, repeated CI red, any
  external-service anomaly → stop dispatching, switch to damage analysis.
- End report structure, in this order: what happened / what the owner must do next / how to
  proceed.

## Red Flags

- A brief missing "Touch ONLY", VERIFY commands, or the report format — that is where agent
  wilding comes from, not from the model.
- Two concurrent agents whose file sets intersect at even one file.
- Committing on an agent's pasted test output without re-running it.
- A wave building on an unreviewed previous wave.
- A design pass launched while functional CI is red.
- The orchestrator writing feature code inline "because it's quick" (small review patches are
  orchestrator work; features are not).
