---
description: Review an external LLM's update plan against the code, then execute the approved items with parallel worktree agents and merge them after reading every diff
argument-hint: "[review|execute|merge] [path to plan, default docs/UPDATES_PLAN.md]"
---

# External plan

**Input**: $ARGUMENTS. The first word picks the phase (default: `review`); the rest is the plan path.

Plan resolution: the given path, else `docs/UPDATES_PLAN.md`, else the newest `.md` under `docs/`; if none, ask for it. Read the whole plan first.

## review

Spawn one `general-purpose` subagent (model opus, read-only: Read, Grep, Glob, `git log/diff/show`) with the plan text and this brief: for every proposed change, read the code it refers to and answer, citing file:line,
- **Problem valid?** Yes / Partially / No, and is the impact claim calibrated;
- **Solution sound?** Yes / Partially / No, with a simpler or safer alternative if one exists, and any ordering dependency the plan ignores;
- **Recommendation:** Do now / Do later / Skip / Redesign.

It ends with a prioritized table (item, recommendation, risk of the change). Show the report unedited and stop.

## execute

1. Keep the items the review marked Do now / Do later; list the skipped ones; for Redesign items ask the user before anything else.
2. Group items by the files they touch: overlapping files in one group (sequential), disjoint files in separate groups (parallel). Print the partition before spawning.
3. One agent per group with `isolation: "worktree"`, `python-pro` for Python work, `debugger` for a bug with a known cause, `general-purpose` otherwise, model opus. The brief lists the items verbatim, the exhaustive list of files the agent may touch (stop and report if another file is needed), ordering constraints, and asks it to commit its work in the worktree, run the tests, and report the files changed.
4. Wait for the completion notifications; do not poll.

## merge

For each worktree: `git -C <worktree> log --oneline main..HEAD` and `git -C <worktree> diff main...HEAD`. Read every diff yourself: does it match the item, are there unrequested changes, stale imports after moved modules, new dependencies? Apply the clean groups to main, run the full test suite once on the combined result, and commit each logical unit with a `type: description` message. A group with problems is not applied; describe the problem and ask. Finish with: applied, skipped, pending (with reasons), test result, commit hashes.
