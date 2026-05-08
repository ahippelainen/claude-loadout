# Root Cause Tracing

Bugs often manifest far from their source. Fix at the symptom and the bug returns via a different path.

**Core principle:** Trace backward through the call chain until you find the original trigger, then fix there.

## Process

1. **Observe the symptom** — what failed, where, what value was wrong
2. **Find the immediate cause** — what code directly produced the bad state
3. **Ask: what called this with that value?** — trace one level up
4. **Keep tracing** — repeat until you reach the origin of the bad value
5. **Fix at the source** — not where the error was raised

## When you can't trace manually

Add diagnostic instrumentation at each component boundary:
- Log what enters the component
- Log what exits the component
- Run once to gather evidence
- Then analyze where the chain breaks

## After finding root cause

Add validation at multiple layers (see `defense-in-depth.md`) — makes the bug structurally impossible rather than just patched.
