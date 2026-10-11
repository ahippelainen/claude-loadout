---
name: academic-pipeline
description: "Takes a paper through the author's stages with a checkpoint at each: lit-sweep → academic-paper → /cite-check → academic-paper-reviewer → revision → re-review → journal-port / arxiv-package. Detects the current stage from the files in the project and reports status checked against those files. Triggers: paper pipeline, take this paper to submission, end-to-end paper workflow, where is this paper in the pipeline, what is the next step for this paper. Do NOT trigger for a single stage: call that skill or command directly."
---

# academic-pipeline

An orchestrator. It does no substantive work: each stage is run by its own skill, agent or command, and the author approves every transition.

## Rules

1. **Checkpoint after every stage.** Stop, show the outputs (paths and a three-line summary), and wait for his go or his edits. Never chain two stages without it.
2. **No stage web-searches his unpublished text.** lit-sweep builds queries from field-standard terms and published identifiers; referees look up published work only; there is no originality or plagiarism search over draft text.
3. **His files are his.** Stages write new files under `LLM/` or `Papers/`; his notes, draft and `.bib` change only when he says so.
4. **Stale results.** A review or citation check older than the manuscript's last change is stale for the changed parts. Say so and offer to rerun it before anything relies on it.
5. **Subagents** run with `model: "opus"`.

## Stages

| # | Stage | Run by | Output | Checkpoint question |
|---|---|---|---|---|
| 1 | Literature | lit-sweep | `Papers/READING_GUIDE_<YYMMDD>.md`, `LLM/<YYMMDD>_litsweep_*.md`, `LLM/<YYMMDD>_litsweep.bib` | Is the reading list right; which papers go to ToRead and ToCite? |
| 2 | Writing | academic-paper (outline, draft, abstract); draft-sections for introduction, conclusions recap and appendix | outline and blocks in `LLM/`; the draft is his `Paper/*.tex` | Outline confirmed? Next subsection? |
| 3 | Citations | /cite-check | report | Missing and mismatched references resolved? |
| 4 | Venue | the author; journal-picker agent if undecided | target journal | Which journal? (The review needs a target.) |
| 5 | Review | academic-paper-reviewer (full) | `LLM/<YYMMDD>_review/` with `decision.md` and its roadmap | Which roadmap items will he act on? |
| 6 | Revision | academic-paper (revision); physics-review for any disputed derivation | blocks in `LLM/`; he applies them | Done with the revision? |
| 7 | Re-review | academic-paper-reviewer (re-review), then /cite-check again | `LLM/<YYMMDD>_rereview/` | Ready to submit, or another round? |
| 8 | Submission | journal-port for the journal template; arxiv-package for arXiv | port directory; tarball | He submits himself |

Real referee reports enter at academic-paper's response mode, then stage 7's /cite-check, then stage 8 for the resubmission.

## Hand-offs

What each stage must leave for the next:

- **1 → 2**: the reading guide with read levels and result tags, and ToCite BibTeX from `inspire.py` only.
- **2 → 3**: a compilable main `.tex` with its `.bib`; `[CITE: ...]` and `[MATERIAL GAP: ...]` placeholders listed.
- **5 → 6**: the roadmap in `decision.md`: id (M.. must-address, O.. optional), point, source referee, location.
- **6 → 7**: the revised source, the old source for a diff, and his notes on which roadmap items were done or declined.
- **7**: a table per referee: earlier point, the author's claim, location in the revised text, verdict (addressed / partly / not addressed / made worse).

## Stage detection and status

Read the project, not memory: which of the outputs above exist, their dates, and whether they postdate the current manuscript. Report "checked against the files": current stage, completed stages with dates, stale results, blockers (for example unresolved `[CITE]` placeholders or missing references), and the next action. Entry points: a topic and no material → 1; notes or results → 2; a draft → 3; a draft and real referee reports → academic-paper response mode.
