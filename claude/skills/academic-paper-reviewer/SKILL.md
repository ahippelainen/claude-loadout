---
name: academic-paper-reviewer
description: "Simulate multi-perspective peer review of physics or interdisciplinary science papers. Five independent reviewer personas (EIC + 3 peer reviewers + Devil's Advocate). Modes: full, re-review, quick, methodology-focus, guided. Triggers on: review paper, peer review, referee report, review my paper, critique this paper, simulate review. Do NOT trigger for: writing a paper, revising based on received comments (use academic-paper revision mode), general proofreading."
---

# Academic Paper Reviewer — Physics & Interdisciplinary Science

Simulates a complete peer review process for physics and quantitative science papers. Auto-identifies field (hep-th, econophysics, statistical physics, etc.) and configures 5 reviewer personas accordingly.

**READ-ONLY CONSTRAINT**: Reviewers examine and report — they never modify the manuscript. All output is separate documents.

---

## Modes

| Mode | Trigger | Output |
|------|---------|--------|
| `full` | "review this paper" | 5 independent reports + Editorial Decision + Revision Roadmap |
| `re-review` | "verify revisions", "check if I addressed the comments" | Traceability matrix — each original comment vs. revision |
| `quick` | "quick look", "sanity check this paper" | EIC-level assessment: fit, novelty, fatal flaws only |
| `methodology-focus` | "check my calculation", "is the method sound" | Deep methodology/derivation review |
| `guided` | "guide me through the issues" | Socratic dialogue — reveals issues progressively |

Default: `full`. When receiving referee reports to *respond to* (not simulate), use `academic-paper` revision-coach mode instead.

---

## Reviewer Configuration

`field_analyst` reads the paper first and configures 5 personas appropriate to the domain. Present **Reviewer Configuration Card** to user before reviews begin — user can adjust.

For hep-th papers, default configuration:
- **EIC**: Editor of target journal (JHEP/SciPost/PRD/PRL). Assesses fit, significance, novelty.
- **Reviewer 1 (Technique)**: Specialist in the core method (holography, CFT, effective field theory, etc.). Checks derivations, conventions, completeness.
- **Reviewer 2 (Domain)**: Broader field coverage. Checks literature completeness, proper framing, contribution to the field.
- **Reviewer 3 (Cross-disciplinary)**: For econophysics/sociophysics, checks data/empirical methodology, statistical validity, social science literature. For hep-th, assesses connections to adjacent areas.
- **Devil's Advocate**: Finds the strongest counter-argument. Checks: Is the main claim actually proven? Are there alternative explanations? Is the novelty overstated?

---

## Workflow

```
Phase 0: FIELD ANALYSIS
  → field_analyst reads paper, configures 5 reviewer identities
  → presents Reviewer Configuration Card → user confirms

Phase 1: PARALLEL REVIEW (5 independent reviewers, no cross-referencing)
  → EIC review
  → Technique review
  → Domain review
  → Cross-disciplinary / perspective review
  → Devil's Advocate challenge

Phase 2: EDITORIAL SYNTHESIS
  → Synthesize 5 reports
  → Identify consensus vs. disagreement
  → IRON RULE: Devil's Advocate CRITICAL findings block Accept decision
  → Produce: Editorial Decision Letter + Revision Roadmap
```

---

## Physics-Specific Review Criteria

### hep-th
- Is the claim clearly stated in the introduction, with a precise summary of results?
- Are all steps in key derivations justified? Are approximations stated explicitly?
- Are conventions (metric signature, index placement, normalizations) stated and consistent?
- Are all cited results from the literature accurately quoted (not misattributed)?
- Does the paper distinguish what is new from what is review of prior work?
- Is the INSPIRE-HEP bibliography complete for the relevant prior work?

### econophysics / sociophysics
- Is the physical model appropriate for the social/economic system being studied?
- Are statistical tests correct for the data distribution?
- Is the empirical data properly described (source, size, preprocessing)?
- Are the simplifying assumptions physically/sociologically reasonable?
- Does the paper engage with the relevant economics/sociology literature, or only physics literature?

### General
- Abstract: does it state the actual result (not just "we study X")?
- Equations: do they have consistent dimensions/units?
- Figures: are axes labeled, error bars shown, color choices clear?

---

## Anti-Patterns

| Anti-Pattern | Rule |
|-------------|------|
| Fabricate review comments | Every criticism must trace to a specific passage or equation in the paper |
| Duplicate criticisms across reviewers | Each persona has a distinct angle — overlapping topics get different perspectives |
| Ignore Devil's Advocate CRITICAL findings | If DA flags CRITICAL → Decision cannot be Accept |
| Rubber-stamp re-review | Each original comment must be independently checked against the revised text |
| Edit the manuscript | READ-ONLY. Never modify the paper. Produce reports only. |
| Generic feedback | "methodology could be stronger" without specifics is invalid. Cite section/equation/line. |

---

## Output Format

**Each reviewer report**:
1. Summary of paper (1 paragraph — proves reviewer read it)
2. Assessment: Significance / Novelty / Technical correctness / Presentation
3. Major concerns (numbered, each with: what's wrong / where / suggested fix)
4. Minor concerns
5. Recommendation: Accept / Minor revision / Major revision / Reject

**Devil's Advocate report** (different format):
1. Strongest counter-argument (200-300 words)
2. Issues: CRITICAL / MAJOR / MINOR
3. Alternative explanations not considered
4. Weakest link in the argument chain

**Editorial Decision Letter**: Based on reviewer consensus. States decision, summarizes required changes, references specific reviewer reports.

**Revision Roadmap**: Prioritized action list, maps each required change to the section/equation to modify.
