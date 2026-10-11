---
name: lit-sweep
description: "Literature sweep for a research project, run as parallel strands (one opus subagent per disjoint scope). Each paper is characterised from its full text: results tagged proven / simulated / estimated / asserted, read level tagged read in full / abstract only / secondary, and the abstract's claim checked against what the body delivers. PDFs are named and de-duplicated into Papers/, notes go to LLM/, the author approves a ToRead / ToCite split, and BibTeX comes only from INSPIRE (hep) or Crossref by DOI (other fields) through inspire.py. Modes: sweep (topic), seed (start from given papers), bib (identifiers to BibTeX). Triggers: literature sweep, lit sweep, survey the literature on X, what has been done on X, find the papers on X, build a reading list, related-work search, get BibTeX for these arXiv ids or DOIs. Do NOT trigger for: checking a manuscript's citations against its .bib (/cite-check), reviewing a manuscript (academic-paper-reviewer), or writing the related-work prose (academic-paper, draft-sections)."
---

# lit-sweep

Finds and characterises the literature around a project so the author can decide what to read and what to cite. The output is a reading guide he can trust about what each paper *does*, not what its abstract says.

`inspire.py` lives next to this file: `python3 ~/Git/dotfiles/claude/skills/lit-sweep/inspire.py -h`.

## Rules

1. **Abstracts are claims, not results.** Characterise a paper from its full text. Every entry says how it was read: `[read in full]`, `[abstract only]`, or `[secondary: via <paper>]` (known only from another paper's description of it). Never write "the paper shows" from an abstract.
2. **The author's unpublished text never goes into a web search.** Queries are built from field-standard terms, author names, and titles or identifiers of published work. Never paste a sentence, phrase, working title, or term coined in his notes or draft. Strand agents get a scope written in standard terms, not his notes.
3. **BibTeX only from records**: `inspire.py bibtex` (INSPIRE for hep; Crossref by DOI for other fields). Never write BibTeX from memory. A source with neither (some working papers, books without DOI) gets an entry built from its landing page read this session, with `note = {manual entry from <URL>, <YYYY-MM-DD>}`, and is listed as hand-made.
4. **Absence is scoped.** "Nothing found" means nothing found by the queries listed in the strand file. Say that, not "no such work exists".
5. **Nothing is moved or deleted without his list.** He picks ToRead and ToCite; files move only after that, and deletion needs an explicit instruction.
6. **Working papers are flagged.** NBER, SSRN and RePEc/IDEAS sources carry `[NBER WP]`, `[SSRN]`, `[RePEc]`; look for a published version (Crossref search by the published title) and cite that if it exists, noting if its results differ from the version read.

## Project layout

- `Papers/` — PDFs named `Surname_Year_ShortTitle.pdf`: first author's surname in ASCII without spaces, year of first appearance, two to four significant title words in CamelCase; suffix `a`, `b` on collisions.
- `Papers/READING_GUIDE_<YYMMDD>.md` — the reading guide.
- `Papers/ToRead/`, `Papers/ToCite/` — after his split.
- `LLM/<YYMMDD>_litsweep_<strand>.md` — one per strand; `LLM/<YYMMDD>_litsweep.bib` — BibTeX for ToCite.

Create `Papers/` and `LLM/` if absent. If the project is a git repo, check that `.gitignore` tracks PDFs in the subfolders: a non-recursive `!Papers/*.pdf` leaves `Papers/ToRead/*.pdf` untracked (seen in one of his projects).

## Sources

- hep: `inspire.py search '<INSPIRE query>' -n 25 --sort mostcited` (INSPIRE search syntax, e.g. `t "holographic QCD" and date > 2018`; `refersto:arxiv:<id>` for papers citing a given one); arXiv listings.
- Economics and other fields: NBER, SSRN, RePEc/IDEAS, Crossref (`https://api.crossref.org/works?query.bibliographic=<terms>&rows=20`), journal tables of contents, authors' pages, arXiv econ and q-fin.
- PDFs: arXiv first, then working-paper series and authors' pages. Publisher sites may block non-browser fetches (recorded for ScienceDirect, Springer Link, APS and IOP in `~/Git/dotfiles/claude/skills/journal-port/SKILL.md`); then the entry is `[abstract only]` unless another version is found.

## Workflow

### 1. Inventory
Read `Papers/` (filenames, any earlier READING_GUIDE) and the project's `.bib`. Build the list of known arXiv ids and DOIs; strands skip them.

### 2. Plan — checkpoint
Propose two to five strands with disjoint scopes. For each: scope in standard terms, the neighbouring scopes it must leave to other strands, sources, seed papers if any, date range, and a budget (default at most 25 papers per strand; stop earlier when new queries return only known papers). Show the plan and wait. Network use starts after he approves it.

### 3. Strands
One Agent call per strand, `model: "opus"`, all in one message so they run in parallel. Brief:

```
You run one strand of a literature sweep. Scope: <standard-terms scope>.
Leave to other strands: <their scopes>. Known papers, skip: <ids>.
Sources: <list>. Budget: <N> papers. Date range: <range>.
Search rule: queries use field-standard terms, author names and published titles or identifiers only.
Download each PDF you can into <project>/Papers/ as Surname_Year_ShortTitle.pdf (curl -L).
Read it with the Read tool (pages in chunks of at most 20). If you cannot obtain the text, say so in the entry.
Get identifiers (arXiv id, DOI, INSPIRE texkey); do not write BibTeX.
Write <project>/LLM/<YYMMDD>_litsweep_<strand>.md: first the queries you ran and what each returned,
then one entry per paper in the format below, then "Coverage": what you looked for and did not find.
Return a ten-line summary as your final message.
```

Entry format:

```
### Surname_Year_ShortTitle
- Ref: authors; year; title; journal or series ([NBER WP] / [SSRN] / [RePEc]); arXiv:<id>; doi:<doi>; texkey
- Read: [read in full] | [abstract only] | [secondary: via <paper>]
- Does: what the paper actually does, one to three sentences, in your words
- Results: each main result with one tag and its location in the paper:
  PROVEN (derived or proved in the paper), SIMULATED (numerics, simulation or calibration; name the inputs),
  ESTIMATED (from data; name the data and method), ASSERTED (stated without derivation, data or citation here)
- Claim vs delivery: the strongest claim in the abstract or introduction against what the body delivers,
  with locations; "matches" if it does
- Relevance: one line on why it matters for the scope; proposed ToRead / ToCite / neither
- PDF: Papers/<file>.pdf, or "not obtained: <reason>"
```

### 4. Merge
- De-duplicate: `md5sum Papers/*.pdf` for identical files; then the same arXiv id or DOI under two files (keep the published or latest version); then the same paper in two strands (one entry, both strands named).
- Rename `Unknown_*`, `Anon_*` and other off-convention files after reading their title pages.
- Write `Papers/READING_GUIDE_<YYMMDD>.md`: date and strands; first, the papers whose claim exceeds their delivery; then per strand a table (file, what it does, read level, result tags, proposed ToRead/ToCite); then papers not obtained; then the coverage notes, marked as limited to the queries run.

### 5. Split — checkpoint
Propose ToRead (the short core he should read himself) and ToCite. A paper read `[abstract only]` or `[secondary]` may be proposed for ToCite only with the note "read before citing". He edits the lists; then move the files as agreed.

### 6. Bibliography
`python3 ~/Git/dotfiles/claude/skills/lit-sweep/inspire.py bibtex <ids...> > LLM/<YYMMDD>_litsweep.bib`, then `inspire.py check LLM/<YYMMDD>_litsweep.bib`. Report entries not found, entries from Crossref, working papers and hand-made entries. He merges the file into his own `.bib`; do not edit his bibliography.

## Modes

- **sweep** (default): steps 1–6 from a topic.
- **seed**: he gives papers (paths, arXiv ids, DOIs). Read them in full first; their reference lists and, for hep, `refersto:arxiv:<id>` (papers citing them) supply the seeds and the strand scopes. His own unpublished drafts can be seeds for scoping, but rule 2 still holds.
- **bib**: only step 6, for a list of identifiers.

## Hand-over

Paths of the reading guide, strand files and `.bib`; counts by read level; the claim-vs-delivery gaps; what was not obtained; what the queries did not cover. Next stages: academic-paper for writing, /cite-check once the manuscript cites these.
