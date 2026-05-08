---
description: Execute a reviewed update plan using parallel worktree subagents, one per disjoint file group
argument-hint: "[optional: path to plan document]"
---

# Execute Plan

**Input**: $ARGUMENTS

---

## Phase 1 — Locate the Plan Document

Resolve in this order:

1. If `$ARGUMENTS` is a file path, use it.
2. `docs/UPDATES_PLAN.md` if it exists.
3. Most recently modified `.md` file under `docs/`.
4. If none found, stop: "No plan document found. Provide the path as an argument."

Read the full document.

---

## Phase 2 — Filter Against Review Artifact

If a `/review-plan` report exists in the current context:

- **Skip** all items the review marked "Skip". List them as skipped.
- **Flag** all items marked "Redesign": print them, explain the concern from the review, and ask the user: "These items were flagged for redesign — implement as-is, skip, or provide revised instructions?" Wait for the response before proceeding.

Carry forward only items marked "Do now" or "Do later" (treat both as approved for execution unless the user says otherwise).

---

## Phase 3 — Partition Into Groups

Group the approved items by file overlap:

- Items that touch overlapping files → same group (will run sequentially within one agent).
- Items that touch entirely disjoint files → separate groups (will run in parallel across agents).

To determine which files each item touches, read the plan's description of the change and grep for referenced filenames. When in doubt, assign to the same group.

Print the partition to the user before spawning anything:

```
Deploying N agents:
  Group A (files: foo.py, bar.py): items 1, 3
  Group B (files: baz.py): item 2
  ...
```

Do not proceed until this is printed.

---

## Phase 4 — Spawn Agents

Spawn one subagent per group. Choose the agent type:

| Change type | Agent type |
|---|---|
| Python trading logic, strategy, execution, order management | `python-pro` |
| Bug fix with clear root cause | `debugger` |
| Architectural refactor (multiple files, interface changes) | `code-architect` if available, else `general-purpose` |
| Multiple interacting files without clear specialist fit | `general-purpose` |
| Default | `python-pro` |

Use `isolation: "worktree"` for every agent.

Each agent brief must contain all of the following — fill in the specifics per group:

> **Your assignment**: Implement the following items from the plan:
> - Item N: <copy the full item description from the plan>
> - Item M: <...>
>
> **Files you may touch**: <exhaustive list>. Do NOT modify any file not on this list. If you discover that a fix requires touching an unlisted file, stop and report it rather than making the change.
>
> **Ordering constraints**: <list any within-group dependencies, e.g. "implement item N before item M because M depends on N's interface change"; or "none">
>
> **After making changes**:
> 1. Run `python -m pytest tests/ -x -q` and report the result.
> 2. Do not add comments unless the WHY is genuinely non-obvious to a reader who can see the code.
> 3. Report exactly which files you changed and what you did to each.

Spawn all groups in parallel using `run_in_background: true`. You will be notified automatically when each completes. Do not poll or sleep — just wait for the notifications, then proceed to Phase 5.

---

## Phase 5 — Review Diffs (you, not a subagent)

For each agent's worktree, run:

```bash
git diff main...HEAD -- <files this agent touched>
```

Check each diff yourself:

- Does the change match what the plan asked for?
- Are there unintended modifications (refactors, renames, added comments not requested)?
- Is the logic correct on inspection?
- Are there new imports or dependencies that weren't in the plan?

List any issues found per group. If a diff is clean, mark it clean.

---

## Phase 6 — Apply and Commit

**If all diffs are clean and tests passed:**

Cherry-pick or apply each group's changes into the main working tree. Run `python -m pytest tests/ -x -q` once more on the combined result. Commit with a message that enumerates what was changed and why (use the plan's intent, not a generic message). Report the commit hash.

**If any diff has problems:**

Do not apply that group's changes. Describe the problem precisely and ask: "Group X has the following issue: <description>. Apply the clean groups and skip this one, or adjust and retry?"

---

## Phase 7 — Final Report

```
Executed N items from plan.
  Applied:  <list of items>
  Skipped:  <list, with reason>
  Pending:  <list, with reason if blocked>

Tests: <pass / fail — N passed, M failed>
Commit: <hash> — <message>
```
