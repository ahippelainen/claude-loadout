---
name: propose-persistence
description: Picks the right place to persist something from the conversation (skill, hook, command, global CLAUDE.md, auto-memory) and drafts it. Fires when the user says "from now on", "always", "never", "make this a rule", "anything worth saving?", after a second correction on the same point, or on a clear repeated manual ritual. Explicit modes - "token audit" (review this session for waste) and "/insights triage" (turn an /insights report into proposals). Do NOT fire on a single correction, vague frustration or routine task context.
---

# Propose persistence

Something in the conversation may deserve to outlive the session. Pick the right bucket, draft the real content, and propose it in one short message.

## When

Only on one of these; otherwise stay silent:
- the user corrected the same thing twice, or said "from now on / always / never";
- the user confirmed a non-obvious approach ("yes, keep doing that");
- the same multi-step manual ritual ran a third time;
- the user asked for it, or invoked one of the modes below.

## Buckets

| Signal | Bucket | Location |
|---|---|---|
| Behaviour that fires on specific phrasing or context | Skill | `~/Git/dotfiles/claude/skills/<name>/SKILL.md` |
| Deterministic action on a tool event | Hook | `~/Git/dotfiles/claude/hooks/` + `settings.json` |
| Pipeline the user starts by typing `/name` | Command | `~/Git/dotfiles/claude/commands/<name>.md` |
| Rule for every session | Global CLAUDE.md | `~/Git/dotfiles/claude/CLAUDE.md` |
| Fact that may change (project state, a decision) | Auto-memory | `~/.claude/projects/<project>/memory/` + `MEMORY.md` |

Everything except memory lives in the dotfiles, never in a project repo. Prefer a skill over CLAUDE.md when the rule only matters in some contexts; a hook over a skill when no judgement is needed.

## Draft and propose

Write the actual content, not a sketch: the full SKILL.md or command with frontmatter, the hook script plus its settings.json block, the exact CLAUDE.md lines, or the memory file plus its index line. Then one message: what was noticed (one sentence), where it goes, the draft, "Save, edit or skip?". One proposal per message; do not re-propose something the user skipped.

## After approval

Write it. For a new or renamed skill, agent, command or hook, also regenerate the index (`python3 ~/Git/dotfiles/claude/tools/check.py`) and run `~/Git/dotfiles/install.sh`, since links are made per item and a new skill is invisible until then. Confirm in one line with the file path.

## Mode: token audit (explicit request only)

Review this session for waste and propose the three highest-value structural fixes. Look for: files read repeatedly; large raw output in the main context where a subagent summary would have done; a manual ritual typed three or more times; a check run by hand that a hook could run; always-loaded instructions that did not apply; five or more sequential calls where one search agent would have answered; an agent spawned for a single read. For each: what happened (one sentence, pointing at the moment), a rough cost labelled as an estimate, the fix and its bucket. Then ask which to apply and proceed as above.

## Mode: /insights triage

`/insights` writes an HTML report (the user may also paste its text). Read it and extract: features it suggests that are not installed; proposed CLAUDE.md rules; friction a hook could prevent; repeated patterns that deserve a command; working workflows not yet encoded as skills. Present one numbered table of proposals (bucket, what, source section), ask which to implement, then implement the approved ones one at a time as above.
