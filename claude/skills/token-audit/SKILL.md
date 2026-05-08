---
name: token-audit
description: Use this skill ONLY when the user explicitly requests a retrospective review of the current session for token waste. Fire on phrases like "token audit", "audit this session", "where did we waste tokens", "review token usage", "what could we have done more efficiently". Do NOT auto-fire — this is a deliberate review the user asks for.
---

# Token audit

The user wants a retrospective: look back over the current conversation
and identify concrete places where context was wasted, then propose
specific structural fixes. This is not a general "how to save tokens"
lecture — it is a targeted review of *this* session.

## Step 1: scan the session for waste patterns

Walk the conversation from the top. Flag concrete instances of:

1. **Repeated reads / re-fetches.** Same file read more than once, or
   the same grep repeated with minor variations. Each repeat means a
   fact wasn't persisted somewhere it could be loaded once.
2. **Raw tool output in main context.** Large file reads, long grep
   results, or verbose command output that entered the main context
   when a subagent summary would have sufficed. Especially: codebase
   exploration done inline instead of via `Explore`.
3. **Manual rituals.** The user typed the same multi-step command
   sequence more than twice. Candidate for a slash command or hook.
4. **Manual tool runs that a hook could handle.** User ran
   ruff/tests/format by hand when a PostToolUse hook would fire
   automatically on edit.
5. **Over-broad CLAUDE.md.** Always-loaded instructions that didn't
   actually apply to this session's work. Candidate for moving into a
   description-triggered skill.
6. **Under-delegation.** Places where you did 5+ sequential tool calls
   to answer a question that an `Explore` agent could have returned
   in one summary.
7. **Over-delegation.** Places where you spawned an agent for a task
   that was a single `Read` or `Grep` away. Cold-start cost exceeded
   the savings.
8. **Chatty text between tool calls.** Long narration of what you
   were about to do, instead of just doing it.

## Step 2: pick the top 3

Do not list everything. Rank by estimated tokens saved and pick the
three highest-leverage items. One-off minor slips are not worth
surfacing — focus on patterns that will repeat across sessions if
left unfixed.

## Step 3: for each, draft a concrete fix

For each of the three, state:

1. **What happened** — one sentence, referencing a specific moment in
   the session. ("We read `foo.py` four times while exploring auth.")
2. **Estimated cost** — rough token count. Be honest; guess if you
   must but label it a guess.
3. **Proposed fix** — the actual persistence mechanism (skill, hook,
   slash command, CLAUDE.md line, memory entry) and a one-line draft
   of the content.
4. **Bucket** — which of the six persistence mechanisms this belongs
   in. Reuse the triage table from `propose-persistence` if needed.

## Step 4: surface as a single message

Structure:

```
## Token audit

**1. <title>**
What: <one sentence>
Cost: ~<N> tokens (estimate)
Fix: <bucket> — <one-line draft>

**2. …**

**3. …**

Want me to apply any of these?
```

Do not pad with general advice about token efficiency. Do not
apologize for past waste. The user wants actionable specifics.

## Step 5: apply if approved

If the user says "apply 1 and 3" or similar, hand off to
`propose-persistence` for each — it handles drafting and writing.
Do not duplicate that logic here.

## What this skill does NOT do

- Does not fire without an explicit request. No auto-audit.
- Does not grade the user's prompting style. Focus on structural
  fixes (skills/hooks/commands), not "you should have been terser".
- Does not propose fixes to past sessions you can't see. Stay within
  the current conversation.
- Does not overlap with `propose-persistence` during normal work.
  `propose-persistence` is passive (fires on signals during the flow);
  `token-audit` is deliberate (fires only on explicit request).
