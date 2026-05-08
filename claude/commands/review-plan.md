---
description: Critical two-layer review of an external LLM's codebase analysis / update plan
argument-hint: "<what was analyzed, e.g. 'the order execution layer' or 'docs/UPDATES_PLAN.md'>"
---

# Review Plan

**Input**: $ARGUMENTS

---

## Phase 1 — Locate the Plan Document

Resolve the plan document in this order:

1. If `$ARGUMENTS` contains a file path (contains `/` or ends in `.md`), use that path.
2. `docs/UPDATES_PLAN.md` if it exists.
3. The most recently modified `.md` file under `docs/`.
4. If none found, stop: "No plan document found. Paste the plan or provide its path as an argument."

Read the full document before proceeding.

---

## Phase 2 — Spawn the Review Orchestrator

Spawn a **general-purpose** subagent (foreground) with the following brief. Pass the plan document content and the value of `$ARGUMENTS` into the brief verbatim.

### Subagent Brief

> You are reviewing a plan produced by an external LLM. The plan analyzes: **$ARGUMENTS**.
>
> The plan document content is reproduced below. Your job is to produce an independent, structured critique — not a paraphrase. You must read the actual source files referenced before forming any judgment.
>
> **Tools available**: Read, Grep, Glob, Bash (read-only: `git log`, `git diff`, `git show`). Do not modify any files.
>
> **For each proposed change in the plan**, produce the following block:
>
> ```
> ## Issue N: <title from plan>
> **Problem valid?** Yes / Partially / No — <1-2 sentence verdict. Cite the specific file:line that confirms or refutes the claim.>
> **Solution sound?** Yes / Partially / No — <1-2 sentence verdict. Note a better alternative if one exists.>
> **Recommendation**: Do now / Do later / Skip / Redesign — <one sentence why>
> ```
>
> Evaluation criteria:
>
> **Layer 1 — Problem Validity**
> - Is the described problem actually present in the codebase as written?
> - Is the external LLM's evidence sound, or does it miss important context (e.g. the issue is already handled elsewhere)?
> - Is the impact claim calibrated — neither overstated nor understated?
> - Is this problem worth the cost of fixing it?
>
> **Layer 2 — Solution Quality**
> - Is the proposed implementation the right approach for this codebase's patterns?
> - Are there simpler or safer alternatives?
> - Does the proposed fix introduce new problems (e.g. race conditions, tighter coupling, performance regression)?
> - Are there dependencies or ordering constraints between changes that the plan ignores?
>
> After all per-issue blocks, produce:
>
> ```
> ## Prioritized Action List
> | Priority | Issue | Recommendation | Risk |
> |---|---|---|---|
> | 1 | <title> | Do now / Do later / Skip / Redesign | Low / Medium / High |
> ...
> ```
>
> Order by expected impact descending. Risk = risk of the *change*, not of the problem.
>
> Be direct. If the external LLM got something wrong, say so plainly. If a proposed fix is worse than the status quo, say that too.

---

## Phase 3 — Present Results

Present the subagent's full report to the user with no paraphrasing. Prepend a single-sentence framing note, e.g.: "Review of the plan analyzing $ARGUMENTS:"

End with:

> Run `/execute-plan` to implement the recommended changes, or tell me what to adjust first.
