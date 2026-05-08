---
name: academic-paper
description: "Academic paper writing pipeline for physics and interdisciplinary science (hep-th, econophysics, sociophysics). Modes: full, plan, outline, revision, revision-coach, abstract, lit-review, citation-check, format-convert. Output: RevTeX4-2 LaTeX + BibTeX. Citation: INSPIRE-HEP preferred, JHEP/PRD/SciPost/PRE journal targets. Triggers: write paper, draft paper, paper outline, write abstract, revise paper, parse reviews, revision roadmap, I got reviewer comments. Do NOT trigger for: deep research only, pure literature survey, reviewing someone else's paper."
---

# Academic Paper — Physics & Interdisciplinary Science Writing Pipeline

Structured paper writing for theoretical physics and quantitative interdisciplinary science. Default output format is RevTeX4-2 LaTeX with BibTeX. Target journals: JHEP, PTEP, SciPost Physics, Physical Review D, Physical Review E, Physical Review Letters.

## Scope

**Primary domains**: hep-th (AdS/CFT, holography, string theory, quantum gravity), econophysics, sociophysics, statistical physics applied to complex systems.

**This skill does NOT**: fabricate citations, invent results, write beyond what the user provides, modify submitted manuscripts when in review mode.

---

## Modes

| Mode | Trigger | What it does |
|------|---------|--------------|
| `full` | "write a paper on X" | Full pipeline: config → literature → structure → draft → citations → review → output |
| `plan` | "guide my paper", "help me plan" | Socratic chapter-by-chapter planning before writing |
| `outline` | "paper outline" | Structure + section plan only |
| `revision` | "revise paper", "incorporate these comments" | Targeted revision from reviewer feedback |
| `revision-coach` | "parse reviews", "I got reviewer comments", "revision roadmap" | Parse unstructured referee reports into prioritized revision roadmap |
| `abstract` | "write abstract" | Abstract only: structured (context/gap/approach/result/significance) |
| `lit-review` | "literature review section" | Related work section with INSPIRE-HEP search strategy |
| `citation-check` | "check citations", "verify references" | Audit BibTeX entries, flag missing DOIs/arXiv IDs, detect orphans |
| `format-convert` | "convert to LaTeX", "clean up bibliography" | Format conversion, BibTeX cleanup, journal style adaptation |

Not sure? Use `plan` — it guides step by step before any writing happens.

---

## Configuration Interview (all modes except revision-coach and citation-check)

Before starting, confirm:

1. **Paper type**: Research article / Letter / Review / Proceedings contribution
2. **Domain**: hep-th / econophysics / sociophysics / other (specify)
3. **Target journal**: JHEP / SciPost Physics / PRD / PRL / PRE / PTEP / other
4. **Stage**: Starting from scratch / have notes / have draft / have submitted version
5. **Existing materials**: list what exists (notes, calculations, Mathematica outputs, prior drafts)
6. **Word/page target**: journal-specific (e.g., JHEP research article: no hard limit; PRL: 4500 words)

Output a **Paper Configuration Record** and wait for user confirmation before proceeding.

---

## Full Pipeline

```
Phase 0: CONFIG        → Paper Configuration Record (user confirms)
Phase 1: LITERATURE    → INSPIRE-HEP search strategy + annotated key references
Phase 2: STRUCTURE     → Section plan + logical flow + equation map
Phase 3: ARGUMENT      → Claim-evidence chains, identify novel contribution
Phase 4: DRAFTING      → Section-by-section draft in RevTeX4-2
Phase 5: CITATIONS     → BibTeX audit, arXiv IDs, INSPIRE keys
Phase 6: REVIEW        → Self-review against journal criteria
Phase 7: OUTPUT        → Final .tex + .bib package
```

User confirms after Phase 0 (config) and Phase 2 (structure) before drafting begins.

---

## Physics Writing Standards

### Structure
Standard hep-th structure: Introduction (motivation + results summary) → Setup/Model → Main calculation/analysis → Results → Discussion → Conclusion → Appendices (technical details). Adapt for econophysics/sociophysics as appropriate (may use IMRaD for empirical papers targeting PRE).

### Citations
- Use INSPIRE-HEP keys: `Author:YEARabc` format (e.g., `Maldacena:1997re`)
- arXiv IDs mandatory for all preprints: `\eprint{hep-th/9711200}`
- DOI mandatory when published
- No fabricated references. If unsure a paper exists, say so — do not invent one.
- Flag papers that appear only in memory without a verifiable arXiv/DOI

### LaTeX conventions
- RevTeX4-2: `\documentclass[aps,prd,twocolumn]{revtex4-2}` for PRD; `\documentclass{jheppub}` for JHEP
- Equations: `align` environment, numbered unless inline
- Figures: EPS or PDF, `\includegraphics`
- No `\usepackage{hyperref}` conflicts with RevTeX — use `hyperref` option in documentclass
- BibTeX database: one `.bib` file, INSPIRE export format

### Abstract structure (hep-th)
1. What is the problem / question
2. What did we do (method/model)
3. Main result (be specific — state the result, not "we find interesting behavior")
4. Significance / implication

### Common anti-patterns to avoid
- "We show that..." without stating what you show
- Placeholder equations that don't match the text
- Citation to "it is well known" without a reference
- IRON RULE: never write `[citation needed]` in a draft — flag it explicitly as `[CITE: describe what's needed]` so it's findable

---

## Revision-Coach Mode

Input: raw referee reports (paste text or provide file).

Output:
1. Parsed referee comments classified as: **Critical** (must address) / **Major** (should address) / **Minor** (optional)
2. Each comment mapped to paper section
3. Prioritized revision roadmap with suggested response strategy
4. Response letter skeleton

Disambiguation rule: when a referee comment is ambiguous, flag it and ask rather than guess.

---

## Failure Paths

| Situation | Handling |
|-----------|----------|
| Insufficient prior work to write from | Recommend running `deep-research-academic` first |
| User provides wrong journal target | Suggest appropriate venue for paper type/domain |
| Citation cannot be verified | Flag as `[UNVERIFIED: author, year, title]` — never fabricate |
| Calculation/derivation needed | Stop — derivations require user input, not generation |
| Reviewer comment contradicts physics | Flag for user decision; do not silently accept wrong physics |

---

## Integration

```
deep-research-academic  →  academic-paper (full/plan)  →  academic-paper-reviewer
                                                        ↓
                                               revision-coach mode
                                                        ↓
                                               academic-paper (revision mode)
```
