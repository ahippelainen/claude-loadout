---
paths:
  - "**/*.wl"
  - "**/*.wls"
  - "**/*.m"
  - "**/*.nb"
---

# Mathematica: lessons from the author's projects

- Run scripts only as `~/Git/dotfiles/claude/tools/wlrun <seconds> <file>` or under `timeout -s KILL`; a plain `timeout` sends SIGTERM, which a busy kernel ignores. At most about 10 minutes per run (the author's rule); cache symbolic results in `Data/` with `DumpSave` or `Put`.
- One licence seat: kernels strictly one at a time. "The product exited because of a license error" means another kernel holds the seat; wait and retry (wlrun does), never start a second one.
- `wolframscript` exits 0 after a parse error. Never trust the exit code: print explicit checkpoints and check the log for `::` messages.
- Script mode: `%` out-references do not work (notebook `.m` exports use them; rewrite as named assignments), and bare expressions print nothing (use `Print`).
- Silent-zero traps, where derivatives vanish without an error:
  - a replacement `f -> Function[{t, z, r}, body]` whose body calls helpers needs `Evaluate[body]`;
  - building the `Function` inside another function alpha-renames the formals (`t$`), so code that later injects `t, z` misses them; construct it as `Function @@ {{t, z, r}, body}`.
  After any such construction, check one derivative by hand or numerically.
- Rule surgery can silently fail to fire: `ruleList /. HoldPattern[Rule[lhs, _]] :> new` may match nothing and leave the list unchanged. Locate by position (`Position[First /@ ruleList, lhs]`, `ReplacePart`) and check `fixed =!= original` before trusting a rerun.
- Never write `*)` inside a `(* … *)` comment; it ends the comment early.
- Keep numeric arrays packed (`Developer`PackedArrayQ`); unpacked arrays made inner loops 10–50 times slower in one project.
- `UsingFrontEnd` can hang at exit; after a front-end conversion, check that no kernel is left and kill it by PID after looking at its arguments.
- In tensor code, write the index placement of every contraction in a comment; a wrong contraction index gives plausible-looking wrong components.
