# Loop rails

Shared by `autonomous-loop` (research, analysis, numerics), `general-loop` (software builds) and the interactive orchestrator sessions of `research-autonomous` (which replaces the guard kit of §4 with its own). All three load this file; change a rail here, never in a SKILL.md. Each rule names the run that paid for it: runs #1/#2 (Aug 2026), HP (a holographic-QCD project, 19–23 Aug), voteforlunch (Aug), run R (8–9 Sep), run Z (27–28 Sep: 16 h 48 min, about a quarter of it productive orchestration; this skill was never loaded).

## 0. Before the owner leaves (in daylight; run #1 lost its first 75 min to this list not existing)

1. **Inventory:** interpreters and licences actually present, RAM/disk/cores, and what else runs on the machine (run #1 shared the box with an unrelated job all night; the owner may leave Mathematica notebooks open).
2. **STATE.md header:** `stop_at`, the budget of §1, the lock token of §2, the repo's line in push-policy (§7). `LOOP/protected.txt` written (§5).
3. **Permission probe.** Prompt stalls silently kill subagents, and the effective permission mode is per-session UI state, not settings-file state (a VSCode session ignored user-level `defaultMode: bypassPermissions` until its own auto mode was switched on). Dispatch a cheap probe subagent exercising Bash, Read, Write, Edit and WebFetch, plus one Edit to a path listed in `LOOP/protected.txt`, which must be refused; the owner confirms zero prompts on screen. Main-session behaviour does not predict subagent behaviour.
4. Guards started (§4), `/goal` set and the recurring check-in armed (§2).
5. **Abort criteria in writing:** what makes the loop stop dispatching and switch to damage analysis.

## 1. Budget and concurrency

- **The cap counts live LLM sessions**: every running subagent, every subagent it started, and every agent inside a running Workflow. The orchestrator is not counted. Default cap **3**; a number the owner gives overrides it (run R: "semi-sequentially", 1–2 agents on a smaller plan). run Z had no cap and its orchestrator counted only its own dispatches: 14–17 live sessions from 20:40 hit the usage limit at 21:42, 9–11 from 22:50 hit it at 00:09, while it told the owner "at most about 6".
- STATE.md keeps a live-sessions table (id, parent, started, wall-clock cap). An agent starts no subagents and no Workflows unless its brief grants N slots, which count against the cap (run Z: the orchestrator reported at 20:17 that no agent had started subagents; nesting later reached depth 3).
- Workflow agents cannot be messaged and a run cannot be resumed from another session (run Z). Use a Workflow only for fan-out whose partial results are cached, and set `model` in the script.
- Every dispatch names `model`: `opus`, or another model only when the owner has named it. At planning time tag each queue item `mechanical` or `frontier-only`, so a model change or an exhausted quota leaves an actionable list (HP).
- **Per-agent caps in every brief:** wall-clock (default 90 min) and turns (default 150); the brief may set others with a reason. At about 80 % of either, the agent finishes its report and stops. At each check-in the orchestrator compares elapsed time with the cap and TaskStops an agent more than 15 min over it, after checking its report file (run Z: two agents ran over 4 h until the owner noticed).
- **"Burn my usage", "use all my usage", "until usage runs out"** mean: keep working at the cap until `stop_at` or the owner stops it, resuming after every limit reset. Pace to the 5-hour window; never read it as maximum parallelism. run Z read it that way: both limits hit 1.4–1.9 h into full-throttle dispatch, Workflow run 1 lost all 5 agents (2.1 M tokens, zero results), and 4 h 41 min of quota after the 06:40 reset went unused.
- If a limit hits less than about 4 h into a window, lower the cap by one for the next window. Dispatch bursts right after a reset opens, not just before a known one closes (HP: 3 agents killed 8 min after dispatch).
- **A usage-limit kill is expected.** On resume: do not diagnose; mark the dead agents' tasks open; check for orphans (half-edits citing reports that were never written are reverted, since an undocumented decision is not a decision; child processes still running are inspected, then killed); claims found only in a dying message are unverified (§6).
- **Usage line** at the end of every check-in turn and in JOURNAL:
  `USAGE <HH:MM from date> live=<n>/<cap> [<ids>] limit-hits=<k> last-reset=<time|none> next-reset=<time|unknown> stop_at=<HH:MM>`
  Add remaining quota only if the session can actually see it; never estimate it.

## 2. Staying alive

- **The orchestrator runs under `/goal` with a bounded condition** that the checker can judge from the turn's output (the USAGE line supplies the time), for example
  `/goal Every task in LOOP/STATE.md is done, blocked, or aborted with a report saying why; LOOP/MORNING.md was regenerated after the last one finished; the guards are stopped. Or the local time is past <stop_at>, or 400 turns have passed.`
  Keep "aborted with a report saying why" in the condition, so an honest abort closes a task instead of making the goal look impossible. Per the documentation, `/goal` stops when met, when judged impossible, or on an error the owner must fix; it resumes after a usage-limit reset when the session waits to continue; it defers evaluation while subagents or background shells run and then does idle check-ins every 30 min. The guards of §4 are background shells, so the goal should not close before shutdown stops them [inferred from that behaviour].
- **Plus a recurring check-in that does not depend on `/goal`**, which can stop on its own judgement: CronCreate every 30 min (`*/30 * * * *`; up to 45 min is fine), or, when cron is unavailable, ScheduleWakeup 1800–2700 s re-armed at the end of every turn. Prefer the recurring cron, since a turn killed by the limit cannot re-arm a one-shot wake-up [inferred]. run Z armed nothing and idled 4 h 41 min after the reset; run R's 2-hourly cron resumed its run 1 h 33 min after the reset.
- **Check-in prompt**, adapted from run R's working one (fill the placeholders):
  ```
  Loop check-in for <project>, lock <TOKEN>. Run `date` first.
  If <LOOP>/STATE.md's ORCHESTRATOR LOCK is not <TOKEN>, do nothing and say so in one line.
  If everything is already done and the final report was delivered, do nothing and say so in one line.
  If <LOOP>/STOP exists, run the shutdown in ~/Git/dotfiles/claude/skills/autonomous-loop/rails.md §8.
  Otherwise run one wake cycle from <LOOP>/ORCHESTRATION.md: collect finished agents (their report files must exist), inspect and kill stray project processes, integrate, regenerate STATE.md and MORNING.md, dispatch within the budget of rails.md §1, and end with the USAGE line.
  ```
- **ORCHESTRATOR LOCK:** STATE.md carries `ORCHESTRATOR LOCK: <TOKEN> since <date>`, and the same token is in the check-in prompt. A session holding another token does nothing. HP: after a handoff, a leftover watcher re-invoked the old orchestrator, which resumed dispatching in parallel with the new one.
- **Kill switch:** the owner creates `LOOP/STOP`; the next turn runs §8.
- **Handoff to a new orchestrator session:** stop every session-owned background task (guards, Monitors, background shells, watchers), delete the recurring check-in, write a new lock token, and write `LOOP/CONTINUE.md` as a pasteable continuation prompt (run R: pasted verbatim as the next session's first message, and it worked).

## 3. Context

- **A fresh agent per chapter, section, round or task**, never one agent for a whole long deliverable. run Z's lecture-notes agent ran 337 turns to a 952 k-token context, was auto-compacted, and alone made 21 % of the session's cache reads.
- **Hand off when an agent's context becomes very large.** The threshold is liberal and job-dependent: a derivation that must hold a long chain may run longer than a bibliography pass. Any auto-compaction ("continued from a previous conversation") is a hard handoff point. The agent writes its handoff state into its report and stops; the orchestrator dispatches a fresh agent on that report. SendMessage continuation is for short fixes to an agent whose context is still small.
- **The orchestrator stays lean**: no heavy work inline, it reads the findings section of reports rather than whole logs, and it hands itself off (§2) when its own context is very large (run Z: 521 k before the owner said "your context is getting a bit heavy").

## 4. Guards

- **Guard kit** in `~/Git/dotfiles/claude/skills/autonomous-loop/guards/`, started at loop start with Bash `run_in_background`, each given a bounded life of (`stop_at` − now + 1 h); record the shell ids in STATE.md:
  ```
  G=~/Git/dotfiles/claude/skills/autonomous-loop/guards
  CWD_UNDER=<project> timeout <H>h bash $G/watchdog.sh <LOOP>/guards.log <project>/venv/bin/python wolframscript WolframKernel
  CWD_UNDER=<project> timeout <H>h bash $G/thermal_governor.sh <LOOP>/guards.log <project>/venv/bin/python WolframKernel
  CWD_UNDER=<project> bash $G/stall_alarm.sh <project>/venv/bin/python WolframKernel
  ```
  `watchdog.sh` kills matching processes older than 62 min and Claude shell wait-loops older than 20 min. `stall_alarm.sh` exits with one ALARM line when a busy run is over 45 min old or has written nothing for 30 min; the exit re-invokes the orchestrator, which handles it and re-arms it, with `IGNORE="<pid>"` for a run it accepts. `thermal_governor.sh` pauses the newest busy run at ≥ 90 °C and resumes at ≤ 80 °C. Thresholds are env variables (usage headers in the scripts). run Z wrote these mid-run (16:07–20:51), the governor only after the owner reported the fans; it then paused runs at 97, 95 and 91 °C. Its watchdog never logged a kill, so the kill rules are untested in a real run.
  Patterns are project-specific substrings of the command line, never a bare `python`. Without `CWD_UNDER`, `WolframKernel` also matches the owner's own notebook kernels.
- **Every wait has a deadline.** In order of preference: (1) run the job itself with `run_in_background`, whose exit is the notification; (2) `timeout <s> tail --pid=<pid> -f /dev/null`; (3) Monitor with an explicit deadline and a stated action at the deadline. Never `until ! pgrep -f <pattern>`: the waiting shell's own command line contains the pattern, so it matches itself forever (run Z: about 13 such loops, found only after the owner asked about the fans; one agent re-armed the same Monitor about 20 times). If a name lookup is unavoidable, use `pgrep -x <exact process name>`. A run past its expected time is a finding to diagnose, not a wait to extend (AIUBI: the orchestrator idled on a Monitor until the owner wrote "Still running, something possibly wrong").
- **Mathematica only through `~/Git/dotfiles/claude/tools/wlrun <seconds> <file>`** (KILL timeout, 3 GB cap, licence retry, no surviving kernel), **one kernel at a time** (one licence seat). Timeouts: spot ≤ 120 s, smoke ≤ 240 s, production chunk ≤ 600 s (the owner's rule: no Mathematica run over 10 min); longer work is chunked, cached and resumable. Only kernel work is serialized: literature, code reading, prose and design run concurrently with the kernel agent (HP). An agent without kernel priority front-loads its non-kernel work and launches no kernel until the orchestrator frees the seat.
- **Every other heavy run:** `systemd-run --user --scope -p MemoryMax=3G -p MemorySwapMax=0 -- timeout --signal=KILL <T> <cmd>`. In-language caps are not guarantees (run #2: MemoryConstrained missed a runaway by 5.7× and the OOM killer took the whole session down, twice); plain `timeout` sends SIGTERM, which a stuck kernel ignores. Logs are written from inside the script or redirected to a file, never piped through `tee` (a kill loses the pipe's contents). Question any run over 10 min: chunk it, or say in the report why it cannot be chunked (run Z memory).
- **Shared machine:** inspect `ps` args and cwd before killing any "orphan", and again at kill time; never touch processes outside the project (run #1 nearly killed the owner's unrelated job); courtesy locks count only CPU-active processes (run #2: the owner's idle notebook kernels held a naive lock forever). The Stop hook reports leftover kernels and LaTeX runs; act on its report.
- **Network and writes:** GET-only, serial per host, ≥ 3 s spacing, abandon a host for the night on 429/403; no installs, no sudo; writes confined to the repo, `LOOP/` and the scratchpad. The end report lists all external traffic in one line (voteforlunch: one approved data download, one 51 KB asset fetch, PyPI, git pushes).

## 5. Protected checks

- **Before the first dispatch, write `LOOP/protected.txt`**: one absolute path per line, for every test, reference-value and tolerance file the loop's results are judged by. Keep reference values and tolerances in files of their own, so they can be protected without freezing the code under test. While the file exists, the PreToolUse hook `protect-checks.py` refuses Edit and Write to a listed path. It does not see shell writes: a Bash write to a listed file is a rail violation, not a loophole.
- During the run, lines are only added (by the orchestrator, with a JOURNAL line saying why), never removed. Changing or loosening a check is the owner's decision.
- **Every brief says: an honest abort, "could not do X, here is why" with the evidence, is a successful outcome.** Weakening a test, loosening a tolerance, editing a reference value, skipping a check, or fake-running what cannot run here is a failure whatever it produces. A check believed wrong goes into MORNING.md with the evidence, and the task that depends on it is marked blocked.

## 6. Verification

- **Independent code before comparing.** A verifier writes its own implementation from the source or spec before it reads the code under test (run Z brief rule 6: the decay agent's own code showed that a premise in every brief rested on a double-precision `numpy.roots` artifact).
- **No agreement between routes that share an ancestor counts as evidence**; it measures how identical the two copies are. For every load-bearing number, name what the two routes share and argue why that shared part cannot hide a common-mode error (HP: three propagator routes agreeing to 5.6e-9 and a formula match to 2.6e-16 all descended from the same wrong vertex tables). A control that predicts a *different* number from the same machinery discriminates; a second match of the same number is one more bit of the same kind.
- **Ask of every control whether it can fire**, including controls the orchestrator invents. A control drawn from the same family as the object under test is the one to distrust (HP: a perturbation along the solution space would have passed vacuously).
- **QC gets a disclosed positive control:** tell the QC agent that N defects are known (or name one), and that finding only the disclosed ones means its reading was still too shallow (HP: it found both, then found that both fixes were wrong). A disagreement list is held to the same standard as the claims it corrects.
- **Premises carry their source.** Every premise in BRIEF.md says whose it is (owner / orchestrator / verified by <task>) and carries a claim tag; an untested load-bearing premise is labelled as such and tested early by one agent with independent code. **A refutation is broadcast at once** by SendMessage to every running agent whose brief or inputs carry the premise; BRIEF.md is corrected in the same cycle and every dependent claim is regraded (run Z: one false premise sat in every round-1 brief for 4 h; 5 agents had to be corrected).
- **`LOOP/BRIEF.md`, at most ~100 lines, is the agent entry point:** mission, rails in force, conventions, premises, current headline numbers. Briefs point at it and at named sections of large files, never at whole STATE or JOURNAL files (HP: 150 KB state files "cost every dispatch a large startup tax"; run Z re-grew a 112 KB log that agents were told to read). A rail, premise or headline number that changes is updated in BRIEF.md in the same edit.
- **Reports:** the agent's first tool call creates its report file, and it writes incrementally from then on (a usage-limit kill takes everything unwritten; HP lost one agent's whole task that way). At most ~250 lines, findings first, one line per claim (statement, tag, route, number), tables over prose, no restating of the brief; over the cap it says so rather than cutting tables. The final message is data for the orchestrator, at most ~20 lines. **A dying or final message is not a report**: a claim not in the report file is unverified.
- **Claim tags** measured / derived / inferred / web-sourced / assumed, each with what would falsify it. **Grades** in `LOOP/CLAIMS.md` (claim | tag | grade | evidence path | checked by): agent-claimed → independently checked → refereed by a fresh-context agent → owner-checked. **"PROVED", "verified", "confirmed" or "solid" appear in a heading, a state file or a message to the owner only at grade independently-checked or above** (run Z: "PROVED" headings written from single-agent reports; a result called "the sharpest statement so far" was refuted an hour later). MORNING.md says what no human has checked.
- Point agents at data files; never hand them a number in prose (HP: a channel-order swap introduced in transit).
- The orchestrator re-runs the verification itself before a gate closes or a commit; agent-pasted output is a claim.

## 7. State

- **LOOP/ files:** `ORCHESTRATION.md` (protocol instance, self-contained for resuming), `BRIEF.md`, `STATE.md`, `CLAIMS.md`, `JOURNAL.md` (append-only), `RETRO.md` (friction written at the moment it happens), `PARKING.md`, `MORNING.md`, `protected.txt`, `reports/` (one file per task, written by the agent), `archive/`.
- **STATE.md and MORNING.md are regenerated whole with Write** from the reports and CLAIMS.md at every cycle, never patched: no sed, no heredocs, no `str.replace` scripts (run Z: 29 `str.replace` calls and 28 heredoc appends left "Where we stand" contradicting the track list below it; run #2: a composed heredoc carried a stray destructive line). JOURNAL, RETRO and PARKING are appended with Edit.
- **STATE.md at most ~200 lines:** header (started, `stop_at`, lock, budget, live-sessions table, guard shell ids), queue (open / running / done / blocked / aborted / orphaned), file-ownership table, decisions taken. Finished rounds move to `archive/` (HP's STATE reached 160 KB).
- **MORNING.md** (at most ~80 lines), regenerated at every check-in so that a dead loop still leaves a current summary (run Z had none; the owner asked at 08:24 and got a chat reply): delivered, the grade of every headline claim, decisions taken for the owner, what failed or was aborted and why, checks believed wrong, open questions, ranked next steps, read order, last USAGE line.
- **PARKING.md:** tangents and "interesting but not the goal" findings, one line each with a pointer, not chased without the owner (HP: "STOPPED BY ANTTI … DO NOT CHASE"; overfull boxes and 1e-9 agreements are not findings).
- One owner per mutable file at any time; the orchestrator enforces it by dispatch order.
- Timestamps only from `date` output (HP: a session idled ~15 h between turns and stamped entries with the previous day's clock).
- **Commits: only the loop's own files, by explicit path.** Never `git add -A` or `git add .` while any agent may be writing (run Z: 42 `git add -A` calls with up to 17 agents writing). A project without git skips commits; its state files are the durable record.
- **Pushes follow `~/Git/dotfiles/claude/push-policy`.** A repo listed `free` may be pushed. Any other repo is not pushed unattended: an in-session "push so we don't lose progress" is not standing approval unless the owner adds the repo to push-policy before leaving. A push carries all earlier commits.

## 8. Shutdown (at `stop_at`, queue empty, `LOOP/STOP`, or the owner says stop)

1. Stop dispatching; wait a bounded time for stragglers; TaskStop overruns and mark their tasks orphaned.
2. Stop the guards and every background shell; delete the recurring check-in; list own processes (`ps -u "$(id -u)" -o pid,stat,etimes,args`) and leave no project process, no stopped (`T`) process, no kernel and no pdflatex; act on the Stop hook's report.
3. Final MORNING.md; RETRO synthesis with ranked lessons for the next run.
4. Final commit by path; push only as §7 allows.
5. Revert temporary permission grants.
