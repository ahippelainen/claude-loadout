---
name: subagent-driven-development
description: Use when executing implementation plans with independent tasks in the current session
---

# Subagent-Driven Development

Execute a plan by dispatching a fresh subagent per task, with two-stage review after each: spec compliance first, then code quality.

**Why subagents:** Fresh context per task — no session pollution, no confusion from prior work. You construct exactly what each subagent needs. This also preserves your own context for coordination.

## When to Use

- You have an implementation plan with mostly-independent tasks
- You want to stay in the same session (vs. `executing-plans` which uses parallel sessions)
- Tasks are small enough that a subagent can complete one without architectural decisions

## Process

1. **Read the plan** — extract all tasks with full text upfront, create a todo list
2. **Per task:**
   a. Dispatch implementer subagent (`./implementer-prompt.md`) with full task text + context
   b. If subagent asks questions — answer fully before they proceed
   c. Implementer reports: DONE / DONE_WITH_CONCERNS / NEEDS_CONTEXT / BLOCKED
   d. Dispatch spec reviewer (`./spec-reviewer-prompt.md`) — verify built what was asked
   e. If spec issues found: implementer fixes, re-review until done
   f. Dispatch code quality reviewer — verify implementation is clean
   g. If quality issues found: implementer fixes, re-review until done
   h. Mark task complete
3. **After all tasks:** dispatch final reviewer across entire implementation, then use `finishing-a-development-branch`

**Order matters:** spec compliance must pass before code quality review starts.

## Handling Implementer Status

| Status | Action |
|--------|--------|
| DONE | Proceed to spec review |
| DONE_WITH_CONCERNS | Read concerns first; if about correctness, address before review |
| NEEDS_CONTEXT | Provide missing context, re-dispatch |
| BLOCKED | Diagnose: more context → re-dispatch same model; needs reasoning → upgrade model; too large → break into pieces; plan wrong → escalate to human |

Never ignore an escalation or retry the same model without changing something.

## Model Selection

- Maximum 1-2 files to edit, very clear spec → cheap model (Haiku)
- Multi-file with integration concerns → standard model (Sonnet)
- Architecture, design, review → most capable model (Opus 4.6)

## Prompt Templates

- `./implementer-prompt.md` — dispatch implementer
- `./spec-reviewer-prompt.md` — dispatch spec compliance reviewer
- (code quality: use a general-purpose reviewer subagent with the diff and task description)

## Red Flags

- Don't dispatch multiple implementers in parallel (conflicts)
- Don't let subagent read the plan file — paste the full task text
- Don't skip spec compliance and go straight to quality review
- Don't move to next task while any review has open issues
- Don't accept "close enough" — reviewer found issues = not done
