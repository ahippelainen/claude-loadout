---
name: simplify-legacy
description: Use this skill when the user asks to clean up, simplify, rewrite, or refactor legacy code — especially when they describe it as "bad", "tangled", "over-abstracted", "defensive", "bad-LLM code", or express frustration with existing patterns they want removed rather than preserved. Fires on phrases like "rewrite this", "clean this up", "simplify this module", "this was written by an earlier LLM", "kill the boilerplate". Do NOT fire for small bug fixes or routine edits where preservation is the default.
---

# Simplify legacy code

The user has opted into a rewrite, not a patch. The baseline assumption is
inverted from normal refactoring: existing patterns are *suspect*, not
sacred. Much of the code you're looking at was written by a weaker model
and encodes confusion as structure.

## Rules of engagement

1. **Do not preserve bad patterns out of politeness.** If a layer of
   abstraction exists only because the original author got confused, delete
   it. If a function wraps a single call with no added value, inline it.
   If a class has one method, it should probably be a function.

2. **Strip defensive handling for conditions that cannot occur.** Internal
   code should trust its callers. Remove unnecessary validation. Validation belongs at system boundaries (user input,
   external APIs), not in internal plumbing.

3. **Delete unused shims, legacy re-exports, `// backwards compat`
   comments, `_unused_`-prefixed vars, and dead branches.** If you are
   certain something is unused (verified by search, not assumed), delete
   it fully. Do not leave tombstones.

4. **Do not silently propagate existing patterns.** If the file you're
   rewriting uses an idiom that looks wrong, do not copy it into your
   replacement just because it was there. Either verify it is deliberate
   (read the call sites, check the git history if needed) or replace it
   with the straightforward version.

5. **Three similar lines beat a premature abstraction.** If you find
   yourself extracting a helper to cover 2-3 cases, don't. Repeat the code.
   Abstractions earn their place by covering 5+ real cases, not by
   anticipating hypothetical ones.

## Before you start cutting

Read enough of the surrounding code to know the blast radius of the
rewrite. Specifically:

- Grep for every call site of the functions/classes you intend to change
  or delete. If a name is referenced from outside the file, deleting it
  is a public API change — flag it to the user before acting.
- Check whether tests cover the code you're rewriting. If they do, run
  them before and after so the diff of test results is meaningful.
- Skim the commit history on the file (`git log --oneline -- <file>`) to
  see whether recent commits hint at constraints you can't see from the
  code alone.

## State your plan before deleting

Before a rewrite that removes more than ~20 lines or touches more than
one function, state in one or two sentences:

- what you are about to delete,
- what you are about to replace it with,
- any behavior change the user should know about (even "none" is fine).

This gives the user a chance to redirect before the destructive action.
Do *not* ask permission for every small cleanup — only for removals that
could plausibly be load-bearing.

## When in doubt, ask

If you genuinely cannot tell whether a piece of code is load-bearing or
vestigial — don't guess, ask one specific question. "Is `LegacyAdapter`
still needed, or can I delete it along with the three call sites in
`old_runner.py`?" beats silently deleting and hoping.

## What this skill does NOT authorize

- Rewriting code the user did not point at.
- Refactoring across module boundaries without being asked.
- "Improving" naming conventions project-wide.
- Changing public APIs without flagging.

Scope stays tight: the user named a target, work on that target.
