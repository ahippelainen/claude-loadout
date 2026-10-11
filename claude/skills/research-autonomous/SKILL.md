---
name: research-autonomous
description: Sets up and runs a fully autonomous research program that lives for weeks (mathematics first) in a Git repo or a Dropbox folder - a charter with claim tags, ledgers with verification tiers V0-V3, task cards, fresh-context adversaries, a nightly compute queue run by cron, an hourly watchdog, headless orchestrator rounds, a daily literature watch, a roadmap graph, and notes written from basics for the owner's sign-off. Covers the whole setup from "here is the folder and the problem". Triggers - "start an autonomous research program", "set up a math program", "research-autonomous", resuming a program (CHARTER.md and STATE.md exist), an efficiency review of a program. Do NOT use for - a single overnight run on an existing project (autonomous-loop), owner-in-the-loop physics projects where Claude works in LLM/ and the author promotes (research-init), building software (general-loop).
---

# Autonomous research program

**Load first:** `~/Git/dotfiles/claude/skills/autonomous-loop/rails.md`. Its rails (budget, staying alive, context, guards, protected checks, verification, state, shutdown) bind every orchestrator session of a program; this file adds the program layer.

A program differs from an overnight loop in lifetime and supervision. It runs for weeks; all state is in files; orchestrator sessions are short and replaceable; compute runs on cron without any LLM; nothing is publishable until the owner has understood it end to end. **Agents design, write and verify code; machines search. No agent ever sits in an inner loop.** It grows by adding task cards, ledger entries and nodes in the roadmap, not by making sessions longer.

Worked example: a private mathematics program run this way since 2026-10-05; the kit in `kit/` is its supervision code made generic.

## Setup (the owner gives a folder and a problem)

1. **Intake, in one message**, with defaults the owner can accept wholesale:
   - the long-term aim and the realistic outputs, in order of likelihood;
   - premises: external results the owner accepts without verification (tag `[H: external, owner-accepted]`; every statement that uses one says so, at every tier);
   - scope and stop list (what is parked, and the criteria for re-entering it);
   - parallel-agent cap (default 2: in that program the owner reported on 2026-10-08 that 3 agents exhausted the usage window; the owner's number overrides rails §1), the compute window (default 22:00–06:30) and whether the host stays on;
   - push policy (`free` in `~/Git/dotfiles/claude/push-policy`, or ask) and literature access (legal channels only; the owner's library access for what is paywalled);
   - publication standard: default "nothing leaves the repository before tier V3", plus the venue and the AI-use statement the owner wants (template §9).
2. **Inventory** the host as in rails §0.1 and write it, dated, into STATE.md's Environment section. Re-measure after any host move: the worked example's environment section described a different host after a move.
3. **Charter.** Write `CHARTER.md` from `charter-template.md`. Every mathematical claim in it carries `[K]`, `[V]` or `[H]`. The owner reads and approves it as v0.1. From then on it changes only by dated amendment; a contradicted `[V]`/`[H]` claim goes to `ledgers/KILLED.md` first.
4. **Scaffold:** `bash ~/Git/dotfiles/claude/skills/research-autonomous/kit/scaffold.sh <root> [<name>]` (never overwrites; lists what it skipped).
   - In `~/Git`: `git init -b main`, a private remote after the owner confirms the name (`gh repo create <user>/<name> --private --source . --remote origin`), first commit `chore: program layout`. The repo is added to push-policy only if the owner says so.
   - In Dropbox: no git, and runtime churn must stay out of the synced folder. Scaffold with the locations set, e.g. `PROGRAM_RUN=~/.local/state/<name>/run PROGRAM_RAW=~/.local/state/<name>/raw PROGRAM_VENV=~/.local/state/<name>/venv bash …/scaffold.sh <root>` (scaffold.sh prints the exact line); they go into the crontab lines. Keep `lit/pdf/` small or move it likewise.
   - The compute window comes from `PROGRAM_WINDOW` (default `22:00-06:30`), read at scaffold time for the crontab and at run time by `nightly.sh` and the watchdog.
5. `make venv && make smoke` green (< 60 s), then `make e2e`. Project code goes into its own package under `src/`; nightly jobs are thin tasks in `src/program/tasks/` that call it.
6. **Initial queue** in `tasks/open/`, one card each (template §7): librarian notes on the core literature (`lit/<key>.md`), an adversary pass over every `[V]`/`[H]` claim in the charter, the first engineering cards, a known-results table. Then `STATE.md` from the template.
7. **Cron and headless loops**, each only with the owner's yes: show `ops/crontab.txt` filled in; install it only after approval. Headless orchestrator rounds stay disabled until the owner creates `ops/agent-loops.enabled` with `email=` and `org_id=` lines (the loop checks `claude auth status` against them so it never spends another account's usage). Never enable them while an interactive orchestrator runs.
8. **Probe (mandatory before any unattended use):** run one headless round by hand (`ops/agent_loop.sh orchestrator` with a card that ends in `stopped probe`) and one `ops/litsweep.sh` if the watch is on; read the result files and `run/watchdog.log`. A round that stalls on a permission prompt or exits with `is_error` is a setup failure, not a research result. The probe leaves the loop stopped: resume it by deleting `$PROGRAM_RUN/loops/orchestrator/STOP` (the watchdog then restarts it at its next check).

## Layout

| Path | What | Written by |
|---|---|---|
| `CHARTER.md` | mission, constraints with tags, scope, ladder and gates, caps, protocol, tiers, roles, risks | owner-approved; amendments only |
| `STATE.md` | live handoff, ≤ 150 lines, overwritten every session | orchestrator only |
| `ledgers/` | `IDEAS.md CANDIDATES.md VERIFIED.md KILLED.md` (+ `EVIDENCE.md` if useful) | orchestrator only |
| `tasks/open/`, `tasks/done/` | task cards, ≤ 40 lines each | orchestrator |
| `lit/<key>.md`, `lit/daily/`, `lit/pdf/` | one distilled note per source (≤ 120 lines, exact statements, page references); daily watch output; PDFs, never committed | librarians, litsweep |
| `src/`, `tests/`, `Makefile` | project code; `make smoke`, `make test` | engineers |
| `jobs/{queue,running,done}/` | YAML manifests for the runner | engineers, runner |
| `results/`, `results/raw/` | compact outputs (committed) with the manifest and code hash; bulk output (ignored) | runner |
| `digests/` | nightly summary, ≤ 80 lines, script-generated | `nightly.sh` |
| `roadmap/roadmap.py` | dependency graph of known results, program results, open rungs and the goal | orchestrator |
| `LOOP/` | the overnight-session state of rails §7, when an interactive orchestrator runs | orchestrator |
| `ops/`, `nightly.sh` | watchdog, headless loop, reaper, lit watch, thermal governor, prompts, crontab | kit |
| `lecture_notes/`, `companion/`, `papers/` | notes for the owner, companion notes, drafts | chapter agents |
| `retro/` | efficiency reviews | auditor |

## Running the program

**Two ways to orchestrate, never both at once:**
- *Owner present:* an interactive orchestrator under the rails: `/goal`, a recurring check-in, `LOOP/` state, at most the cap of live agents, slots kept filled while the owner is in session. It creates `LOOP/ACTIVE` at start and removes it at shutdown; while that file exists, headless rounds are deferred. `LOOP/STATE.md` is the session's state; the root `STATE.md` stays the program's handoff, rewritten at the end of the session.
- *Guards:* in a program root the kit's watchdog, reaper and thermal governor replace the guard kit of rails §4. Do not start the rails guards there: their `CWD_UNDER` pattern matches the nightly runner and would kill it.
- *Owner away:* the hourly watchdog starts `ops/agent_loop.sh orchestrator`; each round is a fresh `claude -p` that reads `STATE.md`, does exactly one task unit, writes the handoff, commits by path and writes `worked`, or exits at once with `stopped <reason>` when the next step needs the owner. Usage exhaustion is retried hourly at the cost of reading STATE.md; `stopped` is never restarted; crashes are restarted at most 6 times a day, then flagged `stuck` in the digest. This mode is built and tested with a fake CLI but has not yet run a real program unattended (the worked example kept it disabled; only its daily literature watch ran headless): treat the first nights as a trial and read every round's result.

**Session protocol.** Start: `STATE.md`, the latest digest, the task card; nothing else unless the card names it. Work: one task unit. End: overwrite `STATE.md` (history lives in git), move or update the card, update the ledgers, commit `type: [phase][task] summary` by explicit path.

**Roles** (modes, not agents): orchestrator, librarian, engineer, constructor, adversary, auditor. Never constructor and adversary on the same claim. Adversaries are always fresh agents, re-derive before reading the constructor's argument, and get a disclosed positive control (rails §6), marked "suspected" when the orchestrator invented it.

**Ledgers and tiers.** IDEAS → CANDIDATES → VERIFIED at a tier, or KILLED with a one-line reason. Entries are never deleted; killed ones prevent repeated work.

| Tier | Requirement | May be called |
|---|---|---|
| V0 | computed once by the authoring code | "computed (unchecked)" |
| V1 | reproduced by an independent implementation (other language, library or method, no shared ancestor) | "independently checked" |
| V2 | V1 where applicable + fresh-context adversary passed with recorded attacks + every `[V]`/`[H]` dependency resolved + a novelty check against the literature | "verified by AI adversaries; no human check" |
| V3 | the owner understood it end to end and signed off | publishable |

A dependency on an unrefereed or external result appears in the statement itself ("conditional on …"). Prior art can surface late: the novelty check runs before V2 and again before any write-up, and a source that could not be opened is listed as unread.

**Compute.** Jobs are manifests; the runner caches by (task, params, seed, code hash) and never recomputes silently; every task checkpoints at least every 15 min and is resumable, seeded and idempotent; every job ends with one JSON line. `make smoke` passes before anything is queued. Keep 2–3 nights queued so days without usage still produce results. Hot loops in compiled code or a CAS; Python orchestrates. Profile before optimising.

**Caps** (tunable at reviews): STATE.md ≤ 150 lines, digest ≤ 80, card ≤ 40, lit note ≤ 120, command output read by an agent ≤ 60 lines, one task unit per orchestrator session or stop at about half context.

**Literature.** Each source is distilled once into `lit/<key>.md`; agents read notes, not PDFs, unless the task is to check a note. Big sweeps with `lit-sweep`, briefed to write its notes to `lit/<key>.md` and PDFs to `lit/pdf/` (ignored), not to `Papers/`; the daily watch (`ops/litsweep.sh`, prompt `ops/prompts/litsweep.txt` with the topic, queries and watched sources filled in at setup) when the field moves fast. Legal sources only; no PDF or text dump is ever committed (that program had to purge two dumps from its history).

**Roadmap.** `roadmap/roadmap.py` holds nodes with statuses and "is used by" edges, the goal at the end; regenerate `.dot/.pdf/.svg` after every ledger change that moves a node. It is the one picture the owner reads first.

**Notes for the owner (the V3 path)** follow `notes.md`: lecture notes from basics, one fresh agent per chapter in a dedicated slot, then one overhaul, then frozen; a companion note per headline result, with a fast path and a review path, refereed by two fresh agents (mathematics; numbers and sources) before the owner reads it.

**Efficiency review** every 10 orchestrator sessions or 14 days: tokens per verified result, idle nights, recomputation and rereading, caps to change; `retro/YYYY-MM-DD.md` with at most 3 changes, applied before the next working session. Also re-check the premises: an external claim can be withdrawn (in that program, three companion claims of an accepted external release were withdrawn the day after it appeared, and the work built on one of them had to be re-targeted).

## Red flags

- A result called verified, proved or new above its tier, or a statement that hides a conditional premise.
- A worker writing STATE.md, a ledger, a commit or a push; two orchestrators alive.
- A digest written by an agent; an agent polling a job; a job queued without a green smoke test.
- Constructor and adversary on the same claim; an adversary that read the argument before re-deriving it.
- Anything about a CANDIDATES entry leaving the repository (email, post, issue, preprint) before V3.
- Headless loops enabled without the account file, or while an interactive orchestrator runs.
- A charter claim changed without a KILLED entry and a dated amendment.
