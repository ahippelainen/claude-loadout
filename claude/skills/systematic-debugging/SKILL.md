---
name: systematic-debugging
description: Use when encountering any bug, test failure, or unexpected behavior, before proposing fixes
---

# Systematic Debugging

Random fixes waste time and create new bugs. Quick patches mask underlying issues.

**Core principle:** Find root cause before attempting any fix. Symptom fixes are failure.

## The Iron Law

```
NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST
```

If you haven't completed Phase 1, you cannot propose fixes.

## The Four Phases

### Phase 1: Root Cause Investigation

1. **Read error messages carefully** — stack traces, line numbers, exact error codes
2. **Reproduce consistently** — can you trigger it reliably? If not, gather more data
3. **Check recent changes** — git diff, new dependencies, config changes
4. **Gather evidence in multi-component systems** — add diagnostic logging at each boundary, run once, then analyze where the chain breaks
5. **Trace data flow** — see `root-cause-tracing.md` for the backward-tracing technique

### Phase 2: Pattern Analysis

1. Find working examples of similar code in the same codebase
2. Compare against reference implementations (read completely, not skimmed)
3. List every difference between working and broken, however small
4. Understand what dependencies and assumptions the broken code makes

### Phase 3: Hypothesis and Testing

1. State a single hypothesis: "I think X is the root cause because Y"
2. Make the smallest possible change to test it — one variable at a time
3. Did it work? Yes → Phase 4. No → form a new hypothesis. Don't stack fixes.

### Phase 4: Implementation

1. Create a failing test case (simplest possible reproduction)
2. Implement the single fix for the root cause
3. Verify the test passes and no other tests broke
4. **If the fix doesn't work:** count attempts. After 3 failed fixes, stop and question the architecture (see below)

### If 3+ Fixes Failed: Question Architecture

Each fix revealing a new problem in a different place is the signature of an architectural issue, not a bug. Stop fixing symptoms and discuss with the human whether the design needs to change.

## Red Flags — Return to Phase 1

- "Quick fix for now, investigate later"
- "Just try changing X and see"
- "Add multiple changes, run tests"
- "It's probably X, let me fix that" (without tracing)
- Proposing solutions before tracing data flow
- "One more fix attempt" after 2 failures

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "Issue seems simple" | Simple bugs have root causes too |
| "Emergency, no time" | Systematic is faster than thrashing |
| "I'll write test after" | Untested fixes don't stick |
| "Multiple fixes saves time" | Can't isolate what worked, creates new bugs |
| "One more attempt" (after 2+) | 3+ failures = architectural problem |

## Supporting Techniques

- `root-cause-tracing.md` — trace backward through call chain to original trigger
- `defense-in-depth.md` — add validation at multiple layers after finding root cause
