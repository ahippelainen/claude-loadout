---
name: test-driven-development
description: Use when implementing a feature or a bugfix, before writing implementation code. Enforces test-first RED→GREEN→REFACTOR. Do NOT fire for throwaway prototypes, generated scaffolding, or pure config files.
---

# Test-Driven Development

Write the test first. Watch it fail. Write minimal code to pass. Repeat.

**Core principle:** If you didn't watch the test fail, you don't know if it tests the right thing.

## The Iron Law

```
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
```

Write code before the test? Delete it. Start over.

## Red-Green-Refactor

### RED — Write Failing Test

One minimal test showing what should happen. One behavior per test. Name describes behavior.

- Tests real behavior, not mock internals
- Fails for the intended reason (missing feature, not syntax error)

**Verify RED — mandatory:**
```bash
python -m pytest path/to/test.py::test_name -v
```
Test passes immediately? You're testing existing behavior — fix the test.

### GREEN — Minimal Code

Write the simplest code to pass the test. YAGNI — no speculative features.

**Verify GREEN — mandatory:** re-run same test, confirm it passes and nothing else broke.

### REFACTOR — Clean Up

After green only: remove duplication, improve names. Keep tests green throughout.

## When Stuck

| Problem | Solution |
|---------|----------|
| Don't know how to test | Write wished-for API first, work backward from assertion |
| Test too complicated | Design too complicated — simplify the interface |
| Must mock everything | Code too coupled — use dependency injection |
| Test setup huge | Extract fixtures; still complex means simplify design |

## Rationalizations to Reject

| Excuse | Reality |
|--------|---------|
| "Too simple to test" | Simple code breaks. Test takes 30 seconds. |
| "I'll test after" | Tests passing immediately prove nothing about correctness. |
| "Already manually tested" | No record, can't re-run. |
| "One more fix attempt" | Sunk cost. Keeping unverified code is technical debt. |
