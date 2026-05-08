---
name: academic-pipeline
description: "Orchestrate the full research-to-paper pipeline for physics and interdisciplinary science: deep-research-academic → academic-paper → academic-paper-reviewer → revision → re-review → finalize. Triggers on: academic pipeline, research to paper, full paper workflow, paper pipeline, end-to-end paper, research-to-publication. Do NOT trigger for single-step tasks — use the individual skills directly."
---

# Academic Pipeline — Full Research-to-Publication Workflow

Lightweight orchestrator for the complete paper pipeline. Does not do substantive work — detects stage, dispatches the right skill, manages transitions, enforces checkpoints.

---

## When to Use

Use this when starting from a research question and wanting to proceed all the way to a submission-ready manuscript with checkpoints at each stage.

For single steps, use the individual skills directly:
- Only searching literature → `deep-research-academic`
- Only writing from existing notes → `academic-paper`
- Only reviewing a draft → `academic-paper-reviewer`
- Only parsing referee reports → `academic-paper` (revision-coach mode)

---

## Pipeline Stages

```
Stage 1: RESEARCH
  → Skill: deep-research-academic
  → Output: Research report with key references + INSPIRE-HEP bibliography
  → Checkpoint: user confirms research is sufficient before writing

Stage 2: WRITE
  → Skill: academic-paper (full or plan mode)
  → Output: Complete .tex + .bib draft
  → Checkpoint: user confirms draft before integrity check

Stage 2.5: INTEGRITY CHECK
  → Verify all citations exist (arXiv/DOI check)
  → Flag unverified claims
  → Must pass before review

Stage 3: REVIEW
  → Skill: academic-paper-reviewer (full mode)
  → Output: 5-reviewer report + Editorial Decision + Revision Roadmap
  → Checkpoint: user reviews revision roadmap before revising

Stage 4: REVISE
  → Skill: academic-paper (revision mode)
  → Input: original draft + Revision Roadmap
  → Output: revised draft

Stage 4.5: INTEGRITY CHECK (repeat)
  → Re-verify citations and claims after revision

Stage 3': RE-REVIEW
  → Skill: academic-paper-reviewer (re-review mode)
  → Verify revisions address original comments
  → Output: traceability matrix + new decision

Stage 5: FINALIZE
  → Final formatting pass (journal style)
  → Cover letter draft
  → Submission checklist
```

---

## Stage Detection

Pipeline auto-detects entry point from what the user provides:

| User provides | Entry stage |
|---------------|-------------|
| "I want to write a paper on X" (no materials) | Stage 1 (RESEARCH) |
| Research notes / prior papers | Stage 2 (WRITE) |
| Existing draft | Stage 2.5 (INTEGRITY) |
| Draft + referee reports | Stage 4 (REVISE) |
| Revised draft | Stage 4.5 (INTEGRITY) |

---

## Checkpoint Rules

1. **IRON RULE**: Confirm Paper Configuration Record before drafting (Stage 2)
2. **IRON RULE**: Integrity check must pass before submitting to review (Stage 2.5)
3. **IRON RULE**: No fabricated citations anywhere in pipeline — flag and stop
4. User confirms revision roadmap before beginning Stage 4
5. User can skip Stage 1 if bringing own research materials
6. User can request Pipeline Status Dashboard at any point

---

## Status Dashboard

On request, report:

```
Pipeline Status
───────────────
Current stage : [stage name]
Completed     : [list]
Pending       : [list]
Blockers      : [any integrity failures or unresolved issues]
Next action   : [what to do next]
```
