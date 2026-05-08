---
name: brainstorming
description: Use before any non-trivial feature or change — explores intent and design before touching code.
---

# Brainstorming Ideas Into Designs

Turn ideas into a clear design through focused dialogue before any implementation.

<HARD-GATE>
Do NOT write any code or take any implementation action until you have presented a design and the user has approved it.
</HARD-GATE>

## Process

1. **Explore project context** — read relevant files, recent commits
2. **Ask clarifying questions** — one at a time; understand purpose, constraints, success criteria
3. **Propose 2-3 approaches** — with trade-offs and your recommendation
4. **Present design** — scaled to complexity; get approval before proceeding
5. **Invoke writing-plans** — the only next step after approval

The terminal state is invoking `writing-plans`. Do not invoke any other skill.

## Guidelines

- One question per message — if a topic needs more exploration, break into multiple messages
- Prefer multiple-choice questions over open-ended when possible
- If the request spans multiple independent subsystems, flag it immediately and help decompose before designing any piece
- For each unit of design: what does it do, how is it used, what does it depend on?
- In existing codebases: explore structure first, follow existing patterns
- YAGNI ruthlessly — remove unnecessary features from all designs

## Key Principles

- **Simple projects still need a design** — it can be three sentences, but present it and get approval
- **Explore alternatives** — always propose 2-3 approaches before settling
- **Incremental validation** — present design sections, get approval after each
