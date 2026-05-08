---
name: propose-persistence
description: Use this skill when you notice a signal that something from the current conversation should be persisted — OR when the user explicitly asks "anything worth saving?", "should we add a skill for this?", "propose persistence", "make this a rule". AUTO-FIRE on strong user-given signals only. DO NOT auto-fire on vague frustration, single corrections, or routine task context.
---

# Propose persistence

You are acting as a triage layer: something just happened in the
conversation that *might* deserve to outlive this session, and your job
is to pick the right bucket, draft the content, and surface it as a
single concise proposal.

## Step 1: decide if anything should be persisted at all

Bias toward silence. A proposal is worth making only if one of these
is true:

- The user has just corrected you twice on the same thing in this session.
- The user said something structurally like "from now on X", "always X",
  "never X".
- The user just validated a non-obvious approach you chose ("yes exactly,
  keep doing that").
- You just completed the same multi-step manual ritual for the third
  time in this session and it wasn't obviously a one-off.
- The user explicitly asked for persistence.
- **Token-waste lens** — you notice a concrete, specific pattern that
  is burning context for no reason. Examples that qualify:
  - Same file has been read 3+ times this session → propose pinning
    the relevant fact into CLAUDE.md or a memory entry.
  - User typed the same multi-step shell ritual 3+ times → propose a
    slash command.
  - A large raw tool output (>2k tokens) was dumped into main context
    when an `Explore` subagent summary would have sufficed → propose
    "next time, use Explore for this" as a feedback memory.
  - User manually ran ruff / tests / a formatter that a PostToolUse
    hook could automate → propose a hook.
  - A CLAUDE.md section is bloated and rarely fires → propose moving
    it into a description-triggered skill.
  Only fire on *concrete* instances you can point to. Do not
  speculate about hypothetical waste.

If none of these, do nothing. Do not proactively comb the session for
opportunities.

## Step 2: pick the right bucket

Match the signal to exactly one of the six persistence mechanisms.
Picking the right one is the whole job — a good suggestion in the wrong
bucket is still a bad suggestion.

| Signal shape | Bucket | File location |
|---|---|---|
| Behavioral rule triggered by specific phrasing | Skill | `~/Git/dotfiles/claude/skills/<name>/SKILL.md` |
| Automated action on tool events (every edit, every commit) | Hook | `~/Git/dotfiles/claude/hooks/<name>.sh` + settings.json |
| Multi-step pipeline the user types by hand | Slash command | `~/Git/dotfiles/claude/commands/<name>.md` |
| Project-specific fact or convention | Project CLAUDE.md | `<project>/CLAUDE.md` |
| Global user preference or rule | Global CLAUDE.md | `~/Git/dotfiles/claude/CLAUDE.md` |
| Ephemeral-ish fact to recall in future conversations | Auto-memory | `~/.claude/projects/.../memory/<file>.md` |

### Rules of thumb for disambiguation

- **Skill vs CLAUDE.md:** if the rule should fire in specific contexts
  triggered by phrasing, use a skill (description-triggered, loads on
  demand). If the rule should apply to every single turn of every
  session, use CLAUDE.md. Prefer skill when in doubt.

- **Hook vs skill:** if the action is deterministic and should fire
  without the model's involvement, use a hook. If the action requires
  judgment, use a skill.

- **Command vs skill:** if the user explicitly types `/name` to start
  it, it's a command. If the user just talks and the behavior should
  activate implicitly, it's a skill.

- **Auto-memory vs CLAUDE.md:** auto-memory is for facts that may
  change (current project state, who's doing what). CLAUDE.md is for
  rules that won't change. A deadline is memory. A tone preference is
  CLAUDE.md.

## Step 3: draft the content

Write the actual proposed content. Not a placeholder, not "something
like …" — the real file or edit. The user should be able to approve
it with one word.

### Skill draft shape

```markdown
---
name: <kebab-case>
description: <specific trigger phrasing, including "fires on…" and "do NOT fire on…">
---

# <Title>

<One-paragraph mission statement.>

## <Section with the actual rules>

1. <rule>
2. <rule>
...
```

### Hook draft shape

A shell script path under `~/Git/dotfiles/claude/hooks/` plus the JSON
block to add to settings.json. Include the `matcher` and the full
command.

### Command draft shape

Full markdown file with frontmatter (`description`, `argument-hint`,
`allowed-tools`) and numbered steps, following the pattern of existing
commands in `~/Git/dotfiles/claude/commands/`.

### CLAUDE.md addition shape

The exact lines to add, with enough surrounding context that the user
can see where they'd go.

### Auto-memory draft shape

The frontmatter + body for the memory file, plus the one-line index
entry for `MEMORY.md`. Follow the structure from the global auto-memory
guidance (Why / How to apply lines for feedback and project types).

## Step 4: surface the proposal

One message, following this structure:

1. **What I noticed** (one sentence).
2. **Where it belongs** (bucket + file path).
3. **Draft** (the full content, in a code block).
4. **Ask:** "Save this, edit, or skip?"

Do not pad the proposal with justification beyond one sentence. The user
is smart; if the draft is good, they'll approve. If it isn't, they'll
edit. Walls of explanation are noise.

## Step 5: write it if approved

If the user says yes / save / do it:

- Write the file via the appropriate tool.
- If it's a hook, also update settings.json to wire it in, and `chmod
  +x` the script.
- If it's auto-memory, update both the memory file AND the MEMORY.md
  index.
- If it's a command or skill under dotfiles, the auto-sync hook will
  handle the commit. Do not run `/sync-dotfiles` manually.
- Confirm completion in one line. State the final file path.

## What this skill does NOT do

- Does not propose persistence for things the user has not indicated
  they care about.
- Does not propose multiple items in one message. One signal, one
  proposal. If multiple are genuinely worth it, surface them
  sequentially across turns, not as a list.
- Does not rewrite existing skills/commands/hooks unless asked.
- Does not nag. If the user skipped a proposal once, do not re-surface
  the same proposal later in the session.
