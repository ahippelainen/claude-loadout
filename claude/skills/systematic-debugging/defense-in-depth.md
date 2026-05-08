# Defense-in-Depth Validation

After fixing a bug caused by invalid data, validate at every layer the data passes through — not just the one place you found.

**Goal:** Make the bug structurally impossible, not just patched.

## The Four Layers

1. **Entry point** — reject invalid input at the API boundary (empty string, wrong type, nonexistent path)
2. **Business logic** — ensure data makes sense for this specific operation before proceeding
3. **Environment guard** — refuse dangerous operations in specific contexts (e.g. test environment, read-only mode)
4. **Debug instrumentation** — log context before the dangerous operation so future failures are traceable

## How to Apply

1. Trace the data flow (see `root-cause-tracing.md`) — where does the bad value originate, where is it used?
2. List every point the data passes through
3. Add a check at each layer
4. Test that each layer independently catches the bad value

Different layers catch different cases: different code paths bypass entry validation, mocks bypass business logic, edge cases need environment guards.
