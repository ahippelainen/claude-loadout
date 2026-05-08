---
name: writing-skills
description: Use when writing or editing existing skills.
---

# Writing Skills

## What is a Skill?

A reusable reference guide for a proven technique, pattern, or workflow. Skills help future Claude instances find and apply effective approaches.

**Skills are:** Reusable techniques, patterns, reference guides  
**Skills are not:** Narratives about how you solved a problem once, project-specific conventions (those go in CLAUDE.md)

## When to Create a Skill

Create when:
- The technique wasn't intuitively obvious
- You'd reference it again across different projects
- The pattern applies broadly

Don't create for:
- One-off solutions
- Standard practices well-documented elsewhere
- Project-specific conventions

## SKILL.md Structure

```markdown
---
name: skill-name-with-hyphens
description: Use when [specific triggering conditions and symptoms]
---

# Skill Name

[Core principle in 1-2 sentences]

## When to Use
[Bullet list of symptoms and situations; when NOT to use]

## [Core content — process, patterns, reference]

## Red Flags / Common Mistakes
```

## Frontmatter Rules

- `name`: letters, numbers, hyphens only
- `description`: start with "Use when…", describe triggering conditions only — **never summarize the workflow**. If the description summarizes what the skill does, Claude may follow the description instead of reading the full content.
- Max 1024 characters total in frontmatter

**Good descriptions:**
```yaml
# Triggering conditions only
description: Use when executing implementation plans with independent tasks in the current session
description: Use when implementing any feature or bugfix, before writing implementation code
```

**Bad descriptions:**
```yaml
# Summarizes workflow — Claude will shortcut past the skill body
description: Use when executing plans - dispatches subagent per task with code review between tasks
```

## File Organization

```
skills/
  skill-name/
    SKILL.md              # Main content (required)
    supporting-file.*     # Only for heavy reference (100+ lines) or reusable scripts
```

Keep everything inline unless a supporting file is genuinely reusable. One skill, one directory, flat namespace.

## Keywords for Discoverability

Use words Claude would search for:
- Error messages and symptoms verbatim
- Synonyms: "timeout/hang/freeze", "cleanup/teardown"
- Tool names, commands, file types relevant to the skill
