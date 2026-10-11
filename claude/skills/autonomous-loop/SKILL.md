---
name: autonomous-loop
description: Use when setting up, running, orchestrating or resuming an unattended or multi-hour research, analysis or numerical-computation loop driven by subagents — "research loop", "autonomous loop", "orchestrate the research", "burn my usage on this", "use all my usage", "keep working until usage runs out", "I'm going to sleep, keep working", "run overnight", "overnight run", "night run", "run until morning", or resuming from a LOOP/ state directory after a stall. Do NOT use for a research program that lives for weeks with cron-driven compute, ledgers and headless rounds (research-autonomous; its interactive orchestrator sessions still load these rails), or when the deliverable is a working codebase ("build loop", "dev loop", "orchestrate this build", "send agents to code this"): that is general-loop. Not for a single background task or an interactive session where the owner answers live.
---

# Autonomous Loop

**Load first:** read `~/Git/dotfiles/claude/skills/autonomous-loop/rails.md` in full before setting up or resuming. Its rails (budget, staying alive, context, guards, protected checks, verification, state, shutdown) bind every run; this file adds only what is specific to research runs.

An orchestrator session, file-based state in `LOOP/`, background subagents and scheduled check-ins, running unattended for hours. Quality over quantity: a smaller set of verified results beats broad unverified output. Behind it: run #1 (2026-08-10→11: 12 tasks, one usage-limit kill recovered), run #2 (08-11→12: 23 tasks, two self-inflicted OOM crashes fixed mid-run), HP, a holographic-QCD project (08-19→23: 59 reports, Phases 0–5; most verification rails come from its RETRO), and run Z (09-27→28, run without this skill; most budget and staying-alive rails come from its failures).

## When to use

- Multi-hour runs (owner asleep or away) whose deliverable is results: derivations, numerics, analyses, notes.
- Resuming such a run after a crash, a usage-limit stall or a session restart.
- NOT for: building a codebase (general-loop); a single background task (dispatch one agent); interactive sessions.

## Architecture

`LOOP/` as in rails §7. `ORCHESTRATION.md` holds the mission, deliverables, task-queue source, phase gates, the owner's binding contract (which of his files are untouchable, where new work goes) and the shutdown; a fresh session must be able to resume from it plus `STATE.md` alone.

The orchestrator never does heavy work inline. It reads state, integrates finished results, regenerates state files, commits by path, dispatches and ends its turn. Everything else happens in background subagents.

**Wake cycle** (one turn under `/goal`, triggered by an agent completion, a guard exit or a check-in):
1. `date`. Lock token not ours → one line, stop. Past `stop_at` or `LOOP/STOP` exists → shutdown (rails §8).
2. Read STATE; collect finished agents; a "done" counts only if its report file exists.
3. Integrate: CLAIMS grades, JOURNAL entry with the key numbers, RETRO on friction; orphan check after any kill.
4. Regenerate STATE.md and MORNING.md; commit by path (no git: skip).
5. Dispatch within the budget (rails §1): one kernel agent at a time, non-kernel agents alongside it; the adversarial QC pass over a phase's outputs before its prose is consolidated.
6. End with the USAGE line.

**Brief** (agents do not see the conversation): "read `LOOP/BRIEF.md` first" + task + file paths + acceptance criteria including the honest-abort clause (rails §5) + wall-clock and turn caps + subagent slots granted (default 0) + `model` + kernel priority yes/no + report path, created by the first tool call + "your final text is data for an orchestrator, not prose for a human". Physics briefs point at the project's `LLM/conventions.md` under the protocol in `~/Git/dotfiles/claude/contexts/physics-conventions.md`; the physics agents carry no convention defaults.

## Setup specific to research runs (after rails §0)

- **Handoff docs lie.** Inventory real paths and environments before trusting a spec: run #1's spec described a codebase that was never transferred, assumed a numpy that was not installed, and its older result tables had been generated with different parameters than its acceptance table.
- **The owner's notes and legacy artifacts are evidence, not authority** (HP, the owner: "they cannot be fully trusted. This is where we stalled the last time"). Derive from the action and the literature, then compare with the legacy files; where they disagree the derivation wins and the note gets an erratum. Never port a normalization, boundary condition or factor because a notebook made it: re-derive it or flag it INHERITED-UNVERIFIED.
- **Check harness:** a manifest (a missing manifest, or one with no runnable rows, is a FAIL); checks are append-only; every check prints `CHECK <name>: <result>`. A content-addressed cache may skip checks whose inputs are byte-identical to their last PASS, but a CACHED row is never gate evidence and the summary line states the cached count. An efficiency fix needs its own controls (HP: the first cache silently skipped checks that did depend on an edited package, because a space in the path broke word splitting).

## Research discipline

1. **Adversarial QC before prose consolidation**, with the disclosed positive control of rails §6. Run #1's QC broke two overclaimed headline statistics; running it in parallel with the prose pass forced mid-flight corrections. Aim QC at category errors, not digit-level discrepancies.
2. **Pair tasks for independent-method cross-validation** (analytic vs numeric, port vs reference) whose routes share no computational ancestry (rails §6). Run #1's pairs caught a wrong spec formula and a bug in the validated reference code.
3. **Re-derivation, not transcription**, wherever a result will be quoted in prose; re-running a check never caught the "right number, wrong story" class (HP: twelve defects). When a check's target was hand-copied from a document, QC re-copies it from the document, not from the check. Reconstructing a quantity from other quoted quantities tests internal consistency only (HP: it produced an erratum against a paper that was correct).
4. **Pair a literature/provenance agent with any task whose framing rests on a convention**, concurrently (it holds no kernel). Before correcting a comparison, read what the reference number *is*, not only what it is called (HP: a well-motivated fit-target "correction" would have injected a +6.9 % offset against the reference).
5. **A profile claim is a measurement claim.** Time one call before briefing an optimisation around a diagnosis (HP: a brief aimed at solves worth almost nothing; the code's own comment named the real hotspot). Before briefing around any diagnosis, ask which single measurement would falsify it and take it.
6. **Never infer that a warning is benign**; make someone measure it (HP: a flagged `LinearSolve::luc` solve turned out more accurate than the silent one).
7. **A symmetric error bar on an uncomputed systematic is not an error bar**; name an unbounded systematic as unbounded.
8. **Pre-register a prediction with its mechanism** before dispatching the task that measures it, so either outcome is reportable.
9. **Test the owner's instinct with a task before dismissing it** (HP: he named the boundary conditions as the suspect, and "this kind of a parameter does not exist", ahead of the evidence, and was right on both); say no, with the counterexample, when the logic fails (run Z: "sliding windows can't give every odd value").
10. A negative result on one variant is evidence about that variant only; spec and old-notebook numbers are reported-not-reproduced until re-run locally.
11. Deliverable prose keeps the owner's terse register; no agent's verbose drafts go into his notes (HP contract).

## Numeric and CAS rules (run #2, HP)

1. **Symbolic leakage is the CAS catastrophic failure class**: one `$Failed` flowing through `Max[]` into grid arithmetic swelled to GB scale. Numeric-input assertions (`VectorQ[..., NumericQ]`) at every numeric-evaluator boundary.
2. **Debug drivers inherit all production guards.** Both run #2 crashes came from a diagnostic that was the production loop minus its validity filter, `MemoryConstrained` and `Quiet`. Copy the production path, then modify.
3. **Triage messages by name**; a blanket `Quiet@Check` treated a benign, repaired warning as failure and cost 4× scan coverage.
4. **Silent-zero traps:** replacement rules as `f -> Function[{t,z,r}, Evaluate[body]]` (without `Evaluate` derivative cross-terms vanish); rule surgery through `HoldPattern` on a literal product silently no-ops, so use positional `ReplacePart` plus a "rule actually changed" check; a passing sibling case is not evidence for the failing one.
5. **Efficiency is correctness-level:** smoke-test, extrapolate, then launch (run #2: ~9 h of projected sweeps became ~1.1 h); factorize once (`LinearSolve[A]` returns a reusable solver); never rebuild an operator inside a loop over a parameter it does not depend on; exploit linearity in the source instead of re-solving; state the call count and dominant cost of every new hot path in the report (HP).
6. **Kernel logs settle blame:** run `journalctl -k | grep -i oom` before theorizing (run #2: the obvious culprit was innocent both times).
7. Record honest negatives (warm starts measured to save nothing) as results.

## Shutdown specifics

Rails §8, plus: rebuild owner-facing artifacts (notes PDF) if their sources changed; MORNING.md gives the verified-vs-unverified status of every number and says which work was done by a model other than the owner's default, so it can be re-checked.

## Red flags

- A brief without "read BRIEF.md", acceptance criteria with the honest-abort clause, caps, the report-first rule, or `model`.
- Dispatching before a probe subagent verified promptless operation in THIS session.
- Two running agents that can write the same file, or two holding a Wolfram kernel.
- Live sessions above the cap; an agent past its cap; a wait without a deadline.
- "PROVED" or "verified" on a claim at grade agent-claimed.
- A "done" whose report file does not exist.
- The orchestrator doing analysis or prose inline "because it's quick".
- Check-ins burning turns after the queue is empty: shut down.
