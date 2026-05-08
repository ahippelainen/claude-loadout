---
name: map-codebase
description: Explore a codebase with parallel agents and write structured docs to .planning/codebase/
argument-hint: "[optional: area to focus on, e.g. 'api' or 'auth']"
allowed-tools:
  - Read
  - Bash
  - Glob
  - Grep
  - Write
  - Agent
---

<objective>
Map an existing codebase by spawning 4 parallel Explore agents, each covering a different focus area.
Each agent writes its findings directly to `.planning/codebase/`. You collect confirmations only — not document contents — to keep context lean.

Output: 7 documents in `.planning/codebase/` covering stack, integrations, architecture, structure, conventions, testing, and concerns.
</objective>

<process>

## 1. Check existing map

```bash
ls .planning/codebase/ 2>/dev/null
```

If documents already exist, ask the user: refresh or skip?

## 2. Create output directory

```bash
mkdir -p .planning/codebase
```

## 3. Spawn 4 parallel agents

Focus area from $ARGUMENTS (optional — pass through to agents if provided).

**Agent 1 — tech**
Explore the codebase. Write two files:
- `.planning/codebase/STACK.md` — languages, frameworks, key libraries, versions
- `.planning/codebase/INTEGRATIONS.md` — external services, APIs, databases

**Agent 2 — architecture**
Explore the codebase. Write two files:
- `.planning/codebase/ARCHITECTURE.md` — high-level design, layers, data flow
- `.planning/codebase/STRUCTURE.md` — directory layout, module boundaries, entry points

**Agent 3 — quality**
Explore the codebase. Write two files:
- `.planning/codebase/CONVENTIONS.md` — coding style, naming patterns, linting config
- `.planning/codebase/TESTING.md` — test framework, coverage, test file locations

**Agent 4 — concerns**
Explore the codebase. Write one file:
- `.planning/codebase/CONCERNS.md` — tech debt, security issues, missing tests, TODOs

Spawn all 4 in a single parallel Agent call. Each agent should confirm by returning the list of files it wrote.

## 4. Verify output

```bash
ls -la .planning/codebase/
wc -l .planning/codebase/*.md
```

Report which documents exist and their line counts. Flag any missing ones.

## 5. Offer next steps

Suggest what to do with the map (e.g. start a planning session, identify refactor targets).

</process>

<success_criteria>
- [ ] All 7 documents written to .planning/codebase/
- [ ] Agents ran in parallel
- [ ] Missing documents flagged
</success_criteria>
