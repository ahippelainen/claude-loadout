---
description: Parse a pasted /insights report and propose plugins (skills, commands, hooks, CLAUDE.md additions) worth creating. Two phases — suggest then implement on approval.
argument-hint: [paste insights JSON or report text, or leave blank if already in context]
---

# /insights-triage

Parse an `/insights` report and extract everything worth turning into a persistent plugin. Two phases: **suggest** (read-only), then **implement** what you approve.

**Input**: `$ARGUMENTS` (pasted report), or if blank, look for insights data already in the current conversation context.

---

## Phase 1 — ANALYZE

Read the insights report. Extract signals from these sections in order:

### 1a. Explicit plugin suggestions
From `suggestions.features_to_try`:
- Flag every recommended skill, hook, or command that isn't already installed.

### 1b. CLAUDE.md additions
From `suggestions.claude_md_additions`:
- Flag every behavioral rule proposed, noting which section it belongs in (project vs global CLAUDE.md).

### 1c. Friction → hooks
From `friction_analysis.categories`:
- For each recurring friction pattern, ask: could a hook have prevented this automatically (post-edit check, pre-commit validation, session-start reminder)?
- Flag concrete hook candidates only — not vague "be more careful" signals.

### 1d. Usage patterns → commands
From `suggestions.usage_patterns`:
- For each pattern the user repeats manually, ask: is this a slash command waiting to be written?
- Flag only patterns with a clear, repeatable trigger.

### 1e. Horizon opportunities → skills
From `on_the_horizon.opportunities`:
- For each autonomous workflow opportunity, ask: is this encodable as a skill?
- Flag if yes, with a draft trigger description.

### 1f. Validated workflows → skills
From `what_works.impressive_workflows`:
- These are things already working well. Flag any that aren't yet encoded as skills — encoding them makes them repeatable and less dependent on the user re-explaining context.

---

## Phase 1 — OUTPUT

Present a numbered triage table. No files written yet.

```
## Insights Triage — Proposals

### Skills
| # | Name (proposed) | Trigger | Source section |
|---|---|---|---|
| 1 | ... | fires when... | friction / horizon / ... |

### Commands
| # | Name | What it does | Source section |
|---|---|---|---|

### Hooks
| # | Event | What it runs | Source section |
|---|---|---|---|

### CLAUDE.md additions
| # | Rule summary | Target file | Section |
|---|---|---|---|
```

After the table:
```
Which items should I implement? List numbers (e.g. "1, 3, 5") or say "all".
Say "none" to stop.
```

Wait for user response before proceeding.

---

## Phase 2 — IMPLEMENT

For each approved item, implement in sequence (one at a time, confirm each is done before moving to next):

### Skill
1. Create directory: `~/Git/dotfiles/claude/skills/<name>/`
2. Write `SKILL.md` following the shape from `propose-persistence` skill conventions:
   - Frontmatter: `name`, `description` (specific trigger phrasing with fires-on / do-NOT-fire-on)
   - Mission statement paragraph
   - Numbered steps
3. Append entry to `~/Git/dotfiles/claude/skills/INDEX.md`
4. Run `~/Git/dotfiles/install.sh` to symlink

### Command
1. Write `~/Git/dotfiles/claude/commands/<name>.md` with frontmatter (`description`, `argument-hint`) and numbered phases
2. Append entry to `~/Git/dotfiles/claude/commands/INDEX.md`
3. Commands are symlinked via the commands directory symlink — no install.sh needed

### Hook
1. Write shell script to `~/Git/dotfiles/claude/hooks/<name>.sh`, `chmod +x`
2. Add the hook entry to `~/.claude/settings.json` under the appropriate event key
3. Append entry to `~/Git/dotfiles/claude/hooks/INDEX.md` (create if missing)

### CLAUDE.md addition
1. Read the target file (project or global)
2. Insert the rule into the appropriate section
3. Show the diff before writing — confirm with user if the insertion point is ambiguous

---

## Phase 2 — COMPLETION

After all approved items are implemented:
1. Run `/sync-dotfiles` to commit and push
2. Report: list each implemented item with its final file path, one line each
