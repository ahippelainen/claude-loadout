# Charter template

Copy into the project as `CHARTER.md` and fill every `<…>`. Keep the section numbers: STATE.md, task cards and prompts cite them. Write for an agent that reads it once at program start and again at each efficiency review; everyone else works from STATE.md, cards and digests.

---

# <Program name> — Charter (v0.1)

Created <date>. Owner: the human researcher ("owner"). Amendments are dated and listed under the section they change; superseded text stays in git history.

## 0. How to use this document

Read in full at program start and at each efficiency review. Workers receive only the sections their card names.

Every mathematical claim here carries a tag:

| Tag | Meaning | Allowed use |
|---|---|---|
| **[K]** | standard, well established | use directly; cite the source |
| **[V]** | believed correct, to be checked against the primary literature | verified (lit note + citation) before any ledger entry depends on it |
| **[H]** | working hypothesis of this program | proved or checked by an adversary before use |
| **[H: external, owner-accepted]** | an outside result the owner accepts without verification | every statement that uses it says "conditional on <it>", at every tier |

The author of this charter can be wrong. A contradicted [V]/[H] claim is recorded in `ledgers/KILLED.md` and amended here; never worked around.

## 1. Mission and honest framing
- **Long-term aim.** <one paragraph>
- **Central difficulty.** <what makes the problem hard; what running the obvious search harder will not fix>
- **Realistic outputs, in order of likelihood.** <numbered; each a statement someone could check>
- **Both sides.** <how failures are recorded: a failed construction is data about that construction, never evidence for the opposite conclusion unless certified>
- **Publication standard.** Nothing leaves the repository before tier V3 (§9).

## 2. Constraints that shape the plan (read before planning anything)
### 2.1 Statement [K]
<the precise statement of the target problem, with what is known to be false nearby>
### 2.2 Known cases [V]
<table or list with citations; amended as librarians verify each row>
### 2.3 Premises accepted by the owner
<each external result, its source, its tag, and the owner's decision with date>
### 2.4 Reductions and levers
<the arguments the plan rests on, each tagged>

## 3. Scope
### 3.1 In scope
### 3.2 Parked, with re-entry criteria
<item | why parked | what would bring it back>

## 4. Background for agents
<definitions, notation, golden facts for tests (small cases with known answers), enumeration sizes>

## 5. The ladder: phases, deliverables, gates
### Phase 0 — Setup (budget ≤ <n> sessions)
Repository, `make smoke`, nightly pipeline, watchdog, librarian notes on the core sources, adversary pass over §2. **Gate 0:** smoke green, one night run end to end, every [V] in §2 checked or listed.
### Phase 1 … <n>
Each phase: deliverable, budget in sessions and nights, gate with the evidence that closes it.

## 6. Compute and token economics
- **Two meters.** Tokens bind; overnight compute is nearly free. Agents design, write and verify code; machines search; no agent sits in an inner loop.
- **Caps.** STATE.md ≤ 150 lines; digest ≤ 80 (script-generated); card ≤ 40; lit note ≤ 120; command output read by an agent ≤ 60 lines; one task unit per orchestrator session or stop at about half context; at most <cap> parallel agents. Only the orchestrator writes STATE.md and the ledgers and commits and pushes, sequentially, batched at milestones.
- **Code.** Hot loops in <C / Rust / Numba / PARI / Mathematica>; exploit every symmetry; checkpoint ≤ 15 min; resumable, seeded, deterministic, idempotent; cache key (task, params, seed, code hash); one JSON line per job; `make smoke` (< 60 s) before queueing; profile before optimising.
- **Batching.** Manifests in `jobs/queue/`; keep 2–3 nights queued; review agent output in batches (one adversary session for a week's candidates).
- **Nightly pipeline.** Cron starts `nightly.sh` at <22:00>; it checkpoints and stops at <06:30>, writes `digests/<night>.md`, commits compact results by path, pushes only if push-policy allows.
- **Supervision.** Hourly `ops/watchdog.sh`: heartbeats, status per loop (crashed → restart, at most 6 per day, then stuck; usage exhausted → retry hourly; stopped → never), single instance, no restart during a git operation.
- **Efficiency review** every 10 orchestrator sessions or 14 days → `retro/<date>.md`, at most 3 changes.
- **Literature access.** <legal channels; owner's library>; PDFs in `lit/pdf/` (not committed).

## 7. Session protocol
Start: STATE.md, the latest digest, the card. Work: one task unit. End: overwrite STATE.md; move or update the card; update the ledgers; commit `type: [phase][task] summary` by explicit path.

### STATE.md template
```markdown
# STATE  (updated YYYY-MM-DD, session NNN)
Phase: 1   Gate status: G0 passed (evidence: digests/...), G1 open
Owner decisions in force: <dated, one line each>
Key results: <ledger ids with tier, one line each>
Active: <tasks and roles>   Queue: <n nights queued>   Last night: <OK/failed, hours, what ran>
Ledgers: VERIFIED n (V1:a, V2:b, V3:c), CANDIDATES n, IDEAS n, KILLED n
Since last review: <sessions>, <nights>
Next action: <one sentence>
Open questions for owner: <at most 3, one line each>
## Environment (measured <date>, host <name>)
```

### Task card template
```markdown
# T07 — <title>
Role: engineer        Phase: 1d        Budget: 2 sessions, 2 nights
Read only: §4.1, §5 Phase 1d, lit/<key>.md
Inputs: results/...
Deliverable: src/..., tests, jobs/queue/t07.yaml
Done when: <checkable criterion>
Do not: extend scope, read PDFs, print > 60 lines
```

## 8. Repository layout and git conventions
<the layout table of the skill, adjusted>. Raw bulk output is not committed; compact results carry the manifest and code hash that regenerate them. Tag verified results `v-<ledger-id>-V<k>`. No paper PDFs, scans or text dumps in git, ever.

## 9. Verification tiers, ledgers, publication
| Tier | Requirement |
|---|---|
| V0 | computed once by the authoring code |
| V1 | reproduced by an independent implementation (different language, library or method) |
| V2 | adversary review passed (attacks recorded; every step checked against lit notes; every [V]/[H] dependency resolved) and a novelty check done |
| V3 | the owner understands the result end to end and signs off. **Only V3 is publishable** |

### 9.1 Publication and AI-use standards (owner, <date>)
- Pipeline: <venue order>.
- Only humans are authors; the owner signs only what he understood end to end.
- AI-use statement, specific: which models did what (search, conjecture, computation, proof drafting, adversarial review) and what the owner did; a key idea from an agent is credited as such.
- Verification statement per claim: tier and how it was checked; anything checked only by AI says so.
- Conditional premises appear in the theorem statements.
- Prior art: a documented search before submission; precursors credited prominently; "new" only within the search actually done.
- Code: only what reproduces the results, in a separate public repository at publication time.
- Errata: a public correction that says where the error is.

### Ledger entry template
```markdown
## VER-0007  <statement in one line>  (tier V2) (<date>)
Statement: ...
Depends on: <§/lit note [tag]>, <external result [conditional]>
Evidence: commit abc123, src/..., jobs/done/..., results/...
Independent check: <method/implementation>, commit def456
Adversary: <task id>, fresh context, <date>; attacks tried: ...; verdict: pass
Literature novelty check: <who, what was searched, result; sources not opened listed>
Owner review: pending (V3). Not checked by any human.
```
IDs: `IDEA-`, `CAND-`, `VER-`, `KIL-` with four digits. A failed candidate moves to KILLED with a one-line reason; entries are never deleted.

## 10. Roles
Orchestrator (STATE, queue, gates, cards; reads digests, never raw output) · Librarian (lit notes, known-results table, novelty checks) · Engineer (code, tests, manifests, pipeline) · Constructor (proposes constructions and arguments) · Adversary (attacks every claim before V2, fresh context) · Auditor (efficiency reviews). Never constructor and adversary on the same claim.

## 11. Risk register
| Risk | Mitigation |
|---|---|
| A [V]/[H] claim here is wrong | tags, mandatory verification, KILLED + amendment |
| A "new" result is already in the literature | novelty check before V2 and before any write-up |
| A convincing but wrong agent argument | adversary, independent recomputation, V3 gate |
| An accepted external premise is withdrawn or revised | conditional labels; re-check at every review; regrade dependants |
| Someone else resolves the target | watch the literature (daily if the field moves); re-plan instead of continuing |
| Token overrun / idle nights | caps, batching, short sessions; 2–3 nights queued, smoke before queueing |
| Scope creep | re-entry criteria (§3.2), changed only at reviews |

## 12. Initial task queue
| ID | Role | Task | Phase |
|---|---|---|---|
| T01 | Engineer | scaffold check, `make smoke`, nightly pipeline end to end, watchdog | 0 |
| T02 | Librarian | `lit/<key>.md` for the core sources of §2 | 0 |
| T03 | Librarian | known-results table with citations (§2.2) | 0 |
| T04 | Adversary | check every [V]/[H] claim of §2 and §4 | 0 |
| T05 | Engineer | golden tests from §4; second independent implementation of the core computation | 1 |
| T06 | Auditor | first efficiency review, after T01–T05 or 10 sessions | — |
