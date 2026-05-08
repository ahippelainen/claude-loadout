---
name: debug
description: Systematic debugging with scientific method — gather symptoms, form hypotheses, track state in a file
argument-hint: "[issue description] or [list | continue <slug>]"
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
  - Grep
  - Agent
---

<objective>
Debug issues using the scientific method: gather symptoms, hypothesize, test, eliminate.
Tracks state in `.planning/debug/<slug>.md` so sessions survive context resets.

Subcommands:
- `list` — show active debug sessions
- `continue <slug>` — resume a session
- (default) — start a new session from description
</objective>

<process>

## list

```bash
ls .planning/debug/*.md 2>/dev/null | grep -v resolved
```

For each file, print: slug, status, hypothesis, next_action. Stop.

## continue <slug>

Read `.planning/debug/<slug>.md`. Print current hypothesis and next_action to orient yourself, then proceed directly to the investigate/fix loop (Step 3).

## New session

### 1. Gather symptoms

Ask the user:
1. What should happen?
2. What actually happens?
3. Any error messages?
4. When did this start — did it ever work?
5. How do you reproduce it?

Generate slug from description: lowercase, spaces→hyphens, strip non-alphanumeric, max 30 chars.

### 2. Create session file

`mkdir -p .planning/debug` then write `.planning/debug/<slug>.md`:

```
---
status: investigating
trigger: <verbatim description>
created: <date>
---

## Symptoms
<gathered answers>

## Current Focus
hypothesis: (none yet)
next_action: gather initial evidence

## Evidence
(empty)

## Eliminated
(empty)
```

### 3. Investigate / fix loop

Use the `debugger` agent (subagent_type: debugger) for investigation. Pass it:
- the session file path
- the symptoms
- current hypothesis and evidence

After each agent return:
- Update the session file with new evidence, eliminated hypotheses, updated focus
- If root cause found: implement fix, verify, update status to `resolved`, move file to `.planning/debug/resolved/`
- If still investigating: surface hypothesis + next_action to user, ask whether to continue

</process>

<success_criteria>
- [ ] Symptoms gathered before any investigation
- [ ] Session file created and kept up to date
- [ ] Each iteration updates hypothesis and evidence
- [ ] Session resolved or saved for later continuation
</success_criteria>
