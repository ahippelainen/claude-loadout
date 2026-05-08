---
name: verification-before-completion
description: Use when about to claim work is complete, fixed, or passing, before committing or creating PRs.
---

# Verification Before Completion

**Core principle:** Evidence before claims, always.

## The Iron Law

```
NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE
```

If you haven't run the verification command in this message, you cannot claim it passes.

## The Gate

Before claiming any status or expressing satisfaction:

1. **Identify** — what command proves this claim?
2. **Run** — execute it fresh and completely
3. **Read** — full output, check exit code, count failures
4. **Verify** — does output confirm the claim?
5. **Only then** — make the claim

## Common Claims and What They Require

| Claim | Requires | Not sufficient |
|-------|----------|----------------|
| Tests pass | Test command output: 0 failures | Previous run, "should pass" |
| Linter clean | Linter output: 0 errors | Partial check, extrapolation |
| Build succeeds | Build command: exit 0 | Linter passing, logs look good |
| Bug fixed | Test original symptom: passes | Code changed, assumed fixed |
| Agent completed | VCS diff shows changes | Agent reports "success" |
| Requirements met | Line-by-line checklist | Tests passing |

## Red Flags — Stop

- Using "should", "probably", "seems to"
- About to commit/push/PR without running verification
- Trusting agent success reports without checking the diff
- Relying on partial verification ("linter passed" ≠ build passes)
- "Just this once"
