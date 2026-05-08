---
name: deep-research-academic
description: Analyze provided papers and build an INSPIRE-HEP bibliography + research summary for use as Stage 1 of the academic pipeline. Use when starting from existing papers (LaTeX source, PDFs, or text files) and needing a structured research report before writing.
---

# Deep Research — Academic (Physics)

Analyze papers you provide, extract the key physics and bibliography, and produce a research report ready to hand off to `academic-paper`.

## When to Use

- You have a set of papers (as `.tex`, `.pdf`, `.txt`, or pasted text) and want a structured starting point for writing
- You need an annotated INSPIRE-HEP bibliography built from those papers
- You want a synthesis of what the literature establishes before drafting

For open-ended web research without existing papers, use `deep-research` instead.

---

## Modes

| Mode | Use when | Output |
|------|----------|--------|
| `full` | Starting a new paper project | Full research report + annotated bibliography + coverage assessment |
| `quick` | Only need the bibliography | INSPIRE bibliography + one-paragraph summary per paper |

---

## Process

### Step 1: Receive and Read Papers

Accept papers in any of these forms:
- `.tex` source files (read directly)
- `.pdf` or `.txt` files (read and extract)
- Pasted abstract or full text
- INSPIRE keys or arXiv IDs (fetch via WebSearch)

For each paper, extract:
- Title, authors, year, journal/arXiv ID
- Central claim or result
- Key equations or techniques used
- Which prior works it cites (these become bibliography candidates)

### Step 2: Build the Bibliography

For every paper (provided or cited within provided papers):

1. Locate the INSPIRE-HEP record via WebSearch: `site:inspirehep.net "[title]"` or `inspirehep [author] [year] [keyword]`
2. Extract the INSPIRE key (`Author:YEARabc` format)
3. Confirm arXiv ID and DOI match
4. Write the BibTeX entry in INSPIRE format

**Anti-hallucination rule**: Never write a BibTeX entry from memory. Every entry must be verified against an actual INSPIRE-HEP or arXiv record. If a paper cannot be found after 3 search attempts, flag it as `UNVERIFIED` — do not include it silently.

### Step 3: Synthesize (full mode only)

Produce a concise research landscape covering:
- What is established (with citations)
- What is contested or open
- Which techniques/frameworks are standard in this area
- Where your paper could contribute

Keep this honest and specific — cite the papers by INSPIRE key, note which results are robust vs. conjectural.

### Step 4: Output — Schema 1 Handoff

Produce the following (required by `academic-pipeline` Schema 1):

```markdown
## Research Question
[The finalized research question or problem statement]

## Key References
[Annotated list — INSPIRE key, arXiv ID, one-paragraph annotation per paper]

## Bibliography
[Full BibTeX block, INSPIRE format]

## Coverage Assessment
[Self-assessment: what's well-covered, what's missing, confidence level]

## Open Questions (optional)
[Gaps or open problems identified]

## Calculation Notes (optional)
[Key equations, results, or techniques from reviewed papers]
```

---

## Output Quality Rules

1. Every BibTeX entry must have: INSPIRE key, `eprint` field (for preprints), `doi` (for published), correct journal abbreviation
2. Annotation must state the paper's central result in 2-3 sentences — not just the abstract reworded
3. Coverage assessment must be honest about gaps — don't claim completeness if searches were limited
4. Flag any paper that could not be verified on INSPIRE as `UNVERIFIED` with a note

---

## Handoff to academic-paper

When the user says "now write the paper" or "proceed to Stage 2":
- Pass the full Schema 1 output to `academic-paper`
- The intake agent will detect the bibliography and skip redundant steps
- If using `academic-pipeline`, this output satisfies the Stage 1 → Stage 2 transition
