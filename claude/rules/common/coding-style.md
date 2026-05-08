# Coding Style

## Core Principles

### KISS (Keep It Simple)

- Prefer the simplest solution that works
- Avoid premature optimization
- Optimize for clarity over cleverness

### DRY (Don't Repeat Yourself)

- Extract repeated logic into shared functions or utilities
- Avoid copy-paste implementation drift
- Introduce abstractions when repetition is real, not speculative

### YAGNI (You Aren't Gonna Need It)

- Do not build features or abstractions before they are needed
- Avoid speculative generality
- Start simple, then refactor when the pressure is real

## File Organization

MANY SMALL FILES > FEW LARGE FILES:
- High cohesion, low coupling
- Extract utilities from large modules
- Organize by feature/domain, not by type

## Input Validation

ALWAYS validate at system boundaries:
- Validate all user input before processing
- Never trust external data (API responses, user input, file content)

Prefer early returns over nested conditionals once the logic starts stacking.

Split large functions into focused pieces with clear responsibilities.