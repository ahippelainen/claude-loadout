---
name: journal-port
description: Ports a finished RevTeX manuscript to a journal's LaTeX template, or re-ports an existing port to another journal, for any publisher that has a rules file in this skill's publishers/ folder (Elsevier CAS and Springer Nature sn-jnl so far; a new publisher is one new file). The RevTeX source stays untouched and the body goes over verbatim; the skill saves the journal's guide first, classifies citations for author-year journals, renames figures, adds the declarations the guide asks for, proves faithfulness with a mechanical body diff and clean-room tests the upload zip. Triggers on port to Elsevier or Springer, convert RevTeX to the journal template, prepare the submission to Physica A, Mathematical Social Sciences, the Journal of Economic Inequality, Social Choice and Welfare or EPJ B, CAS or sn-jnl template, resubmit to another journal after a desk reject. Do NOT trigger for APS journals (PRD, PRE, PRL stay RevTeX), for writing, revising or reviewing the paper (academic-paper, academic-paper-reviewer), for choosing the journal (journal-picker), for arXiv packaging (arxiv-package), or for LaTeX help unrelated to a port.
---

# Journal port: RevTeX to a publisher's template

This file is the workflow common to every publisher. Everything that belongs to one publisher (template bundle, class line, macros, float and appendix mechanics, declarations markup, upload items, requirements recorded from its journals' guides) is in `publishers/<publisher>.md`. Read the matching file before Step 1:

- Elsevier, CAS classes: `~/Git/dotfiles/claude/skills/journal-port/publishers/elsevier.md`
- Springer Nature, sn-jnl: `~/Git/dotfiles/claude/skills/journal-port/publishers/springer.md`

No file for the target publisher: write one first ("Adding a publisher", at the end).

The lessons come from three ports: the Pareto paper to Physica A (Elsevier, numbered, May 2026) and, after a scope desk-reject, to Mathematical Social Sciences (Elsevier, author-year, Sept 2026); and the Lorenz-curvature paper to The Journal of Economic Inequality (Springer, author-year, Sept 2026).

## The contract

- **The RevTeX source is the source of truth and is never edited** unless the author explicitly asks. It stays the arXiv version. The port is a new file in a new folder.
- **Faithfulness.** The body goes over verbatim. Permitted edits are template mechanics: preamble, front matter, citation commands, figure paths and float options, table rules the guide forbids, appendix numbering, declaration headings, bibliography style. Do not rephrase, tighten or "improve" a sentence, and add no sentence the template or the guide does not require. If a mandatory item needs the author's words (an abstract below the minimum length, an AI-use statement without the facts), port what exists and flag the gap. The author diffs the port against the RevTeX draft and deletes anything that differs; Step 9 makes that diff mechanical.
- **The saved guide beats memory**, including this skill and the publisher files. Their journal numbers are records of a guide read on a stated date.

## Before porting

This skill makes no scope or fit decisions. If the venue is not settled, or the paper was just desk-rejected, the `journal-picker` agent chooses it. Two venue facts are scriptable (both send network traffic; run them when the author asks for venue checks):

- JUFO level: `https://jufo-rest.csc.fi/v1.1/etsi.php?issn=<ISSN>` returns the channel id, `https://jufo-rest.csc.fi/v1.1/kanava/<id>` returns JSON with `Level`. Measured Sept 2026: Mathematical Social Sciences 1, Physica A 1, Journal of Economic Inequality 2, Physical Review E 2, Entropy 0. A simulated review once put MSS at 2, so do not trust levels quoted from memory or simulation.
- Whether the journal publishes the topic: `https://api.crossref.org/works?filter=issn:<ISSN>,from-pub-date:2019-01-01&query.bibliographic=<terms>&rows=12&select=title,issued&mailto=<address>`. Zero title hits on the paper's core term is a desk-reject risk signal, not a verdict.

## Configuration interview

Ask once, then proceed without re-asking:

1. **Target journal**, which selects the publisher file.
2. **Source**: the RevTeX file (normally in `Paper/`) and its `.bib`.
3. **Earlier port of this paper** in `Submissions/`? Same publisher: "Re-porting" below. Other publisher: "Porting across publishers".
4. **Citation mode**, numbered or author-year, from the saved guide's reference section and the reference lists of one or two recent articles in the journal.
5. **Class options** the publisher file lists (layout, referee spacing, line numbers): what the guide asks, otherwise none.
6. **ORCID** (if none, the author registers at orcid.org before submitting), **keywords**, and **classification codes** (JEL, MSC) if the journal asks.
7. **Funding** (no specific grant, or funder and grant number), **competing interests**, **AI use** (yes or no; if yes, which tools and for what), **CRediT roles** where the publisher asks (single author: offer Conceptualization, Formal analysis, Visualization, Writing – original draft, Writing – review and editing, and let the author trim).
8. **Code and data**: is there a deposit with a DOI, and does the journal's policy require one?
9. **Earlier cover letter**, for this paper or another.

## Folder layout

Projects follow `Data/ Images/ LLM/ Numerics/ Paper/ Papers/ Submissions/`. One folder per attempt, `Submissions/<YYYY-MM>_<Journal>/`:

```
journal_info/    saved guide PDFs and their pdftotext output, submission URL, classification list
template/        the unzipped publisher bundle (sample .tex, manual), untouched
main.tex  main.bbl  main.aux  main.pdf  <bib>.bib
<class, style and .bst files>  <renamed figures>  <publisher extras, e.g. highlights.tex>
cover_letter.txt  form_texts.txt
upload/  <Surname>_<Journal>_source.zip
```

The decision letter goes into the same folder when it arrives. Scripts written for the port (generator, citation classifier, body diff) go in the project's `LLM/`, so they never reach the upload.

Everything the compile needs sits flat next to `main.tex`. The guides read for these ports ask for a LaTeX source without subfolders (Springer: "Please do not use subfolders for your LaTeX submission"; the Elsevier guides likewise), and a class or `.bst` that is not next to `main.tex` is either not found or replaced by the TeX Live system copy, possibly a different version (seen with CAS: the log showed the class loading from `/usr/local/texlive/...`).

## Workflow

Each step has a check; do not go on until it passes.

### 1. Save the guide

Before anything else, the journal's guide for authors goes into `journal_info/` as PDF, is converted with `pdftotext -layout`, and is read: aims and scope, article types and limits, title page, abstract, keywords, highlights, structure and appendix numbering, figures, references, declarations, data and code policy, submission items. Follow it over anything remembered.

Publisher sites block non-browser fetches (ScienceDirect serves a captcha, link.springer.com a cookie wall, both measured Sept 2026; the notes record the same for APS and IOP). Ask the author to save the pages from a browser; the publisher file says which pages. Also save one or two recent articles from the journal: their reference lists show the citation style in use. Take the submission URL from the journal homepage, not from memory, and note it in `journal_info/`.

Extract the numbers and headings the port is checked against (abstract length, keyword count, page limit, highlights, figure naming, exact declaration headings), each with the guide page it comes from.

**Check:** the guide text is in `journal_info/`; the extracted list quotes it.

### 2. Template

Get the publisher's bundle (the publisher file gives source and files), unzip it into `template/`, copy the needed class, style and `.bst` files next to `main.tex`, and test-compile the sample once. A bundle kept from an earlier submission to the same publisher is normally fine; the publisher file records when that was last checked.

**Check:** the files are in the folder; the sample compiles.

### 3. Generate the port by script

Write a script in `LLM/` that reads the RevTeX file, slices out the abstract, the body (after `\maketitle` or `\tableofcontents`, up to the acknowledgements), the acknowledgements, the data-availability paragraph and the appendices, and assembles `main.tex` around the publisher's preamble, front matter and back matter. Inside the body it applies only the publisher file's mechanical transforms (float options, figure paths). The body is then verbatim by construction. The first Elsevier port was instead a copy of the source edited in place; that works too, and Step 9 catches drift either way.

Preamble:
- Start from the publisher file's block.
- Carry over only the macros the body uses: grep each `\newcommand`, `\renewcommand`, `\def` and `\DeclareMathOperator` name against the body. In the JEI port the RevTeX preamble defined over 100 macros and the body used 3–5, and several of them (`\d`, `\u`, `\S`, `\P`, `\L`, `\O`) redefined core LaTeX commands.
- Drop the RevTeX class line and options, section-numbering renames (`\thesection`, `\thesubsection`, `\p@subsection`, `\p@subsubsection`), packages the class already loads (publisher file) and RevTeX-only commands. Keep the theorem setup, adapted to the class. Drop `\tableofcontents` and the `\clearpage` after `\maketitle`.

**Check:** `grep -n revtex main.tex` is empty; the file compiles (Step 8).

### 4. Front matter, back matter, appendices

Use the publisher file's macros; author, affiliation, e-mail and ORCID come from the RevTeX source and the interview.

Declarations take the guide's headings verbatim and the author's existing text verbatim. Where a statement is mandatory and the source has none:
- a standard sentence the guide itself prescribes (no-grant funding, nothing to declare) may be used; list it in the hand-off;
- for work with no data, the Elsevier notes give "No new data were generated or analyzed in support of this research."; with a deposit, the author's sentence plus the DOI;
- an AI-use declaration is drafted only from the author's facts (tools, purpose) in the guide's template wording; if the author's existing wording names no tool and the guide asks for one, flag it rather than rewrite it.

Whether a statement also goes into a field of the submission form differs between journals and systems: check the guide and the form, and put the text in `form_texts.txt`.

Appendix numbering of equations, figures and tables follows the guide; the publisher file gives the mechanism.

**Check:** every declaration the guide lists is present under its exact heading; the PDF shows the appendix numbering the guide asks for.

### 5. Citations (author-year journals only)

RevTeX numbered citations are bare `\cite{}`. Under natbib author-year a bare `\cite` renders textually, "Clauset et al. (2009)", which is wrong for parenthetical asides. Do not bulk-replace; inventory first:

```bash
grep -n -o '.\{90\}\\cite{[^}]*}.\{25\}' main.tex                                        # every citation in context
grep -noE '[A-Z][A-Za-z\-]+( and [A-Z][A-Za-z\-]+| et al\.)? \\cite\{[^}]+\}' main.tex    # name already in the prose
```

Classify each occurrence:
- `\citep`: an aside, "…bounded rationality \citep{Simon:1955}." Most cases.
- `\citet`: the citation is a noun in the sentence, "Tables 6.2 and 6.3 of \citet{Clauset:2009}", "In \citet{Ghosh:2021} it was conjectured", "Looking at \citet{A} and \citet{B}".
- `\citealp`: already inside the author's own parentheses, "(see \textit{e.g.} \citealp{Arnold:2008})", avoiding double brackets.
- `\citeyearpar`: the author's name already stands in the prose, "Becker and Seligman \citeyearpar{Becker1996}" rendering "Becker and Seligman (1996)", the form both guides show ("Becker and Seligman (1996)" at JEI, "Kramer et al. (2023)" at MSS). With `\citep` the name repeats, "Vilfredo Pareto (Pareto, 1897)". The source words stay the same but the rendered text changes, so list every such spot for the author.
- Name-preceded keys sharing a bracket with a differently authored key: split, `Amato and Kakwani \citeyearpar{Amato1968,Kakwani1980} \citep[see also][]{Arnold2012}`. The two added words are a wording change; flag it.
- A platform named after its corporate author ("World Bank PIP (World Bank 2026a)") stays `\citep`.

Apply with a script that asserts each hand-classified textual fragment occurs exactly once, converts those, then converts the remaining bare `\cite` to `\citep`; report the count per class. The JEI port used `\let\cite\citep` in the preamble instead, which does the bulk conversion in one line and leaves the body untouched; the exceptions are still classified one by one.

Harmless renderings: same-author, same-year entries get `a`/`b` suffixes ordered by the `.bst` (title order), so a citation may read "2020b,a"; sn-jnl joins multiple years with a semicolon, "(1968; 1980)".

**Check:** no bare `\cite{` left (unless `\let\cite\citep` is used); `pdftotext main.pdf - | grep -c '(?)'` is 0; the name-preceded spots render "Name (year)".

### 6. Bibliography

`\bibliographystyle` and the natbib option come from the publisher file; `\bibliography{<bib>}` takes no `.bib` extension.

Needed in every port:
- DOI fields bare (`10.1016/...`): with a `https://doi.org/` prefix the link prints twice.
- Both author-year styles used so far lowercase titles: brace proper nouns and quoted titles (`{K}olkata`).
- Fix data errors the render exposes, such as an author field containing "World Bank" that rendered "Kakwani N, Bank W".

A full cleanup where the journal formats references from the `.bib` or asks for a specific format (JEI did; the Physica A guide sets no strict requirement at submission): standard fields only (drop abstracts, keyword dumps, ISSNs, `urldate`, Google Books and JSTOR URLs, bracketed publisher clutter); a DOI for every article, looked up on Crossref (`api.crossref.org/works?query.bibliographic=...` with a mailto User-Agent) and confirmed to resolve (`curl -sI https://doi.org/<doi>` returns 302); a URL only where no DOI exists; details you cannot verify (series volume, edition numbers) dropped rather than asserted. The lookups are network traffic; tell the author before running them.

A code or data deposit is cited as a reference (creator, title, repository, year, DOI):

```bibtex
@misc{SurnameZenodo2026,
  author = {...}, title = {Code and data for ``{Title}'' (v1.0.0)},
  year = {2026}, howpublished = {Zenodo}, doi = {10.5281/zenodo.NNNNNNNN}
}
```

**Check:** no warnings in `main.blg`; the rendered list scanned by eye once.

### 7. Figures and tables

Copy the figures flat into the folder, renamed in order of first appearance with the publisher's naming, and rewrite the paths in the same pass (run in the submission folder):

```python
import re, shutil
from pathlib import Path
SRC, NAME = Path('../../Paper'), 'Figure_{}{}'   # SRC: where the RevTeX paths are relative to; NAME: publisher file
t = Path('main.tex').read_text()
paths = list(dict.fromkeys(re.findall(r'\\includegraphics(?:\[[^\]]*\])?\{([^}]*)\}', t)))
for i, p in enumerate(paths, 1):
    new = NAME.format(i, Path(p).suffix)
    shutil.copy(SRC / p, new)   # copy, never move: the RevTeX source still needs its figures
    t = t.replace('{' + p + '}', '{' + new + '}')
Path('main.tex').write_text(t)
```

The script numbers files, not figure environments: if one figure includes several files, settle their names with the guide first. Paths without an extension need one before it runs; with `\graphicspath` in the source, `SRC` is that folder.

Then, per the guide: fonts embedded in vector figures (`pdffonts <file>`, every font `emb yes`), raster resolution (the PNG `pHYs` chunk), table rules (publisher file).

**Check:** `grep -oE 'includegraphics[^}]*}' main.tex` lists the new names 1…N in order; the PDF captions run 1…N the way the guide wants.

### 8. Compile and keep the .bbl

```bash
timeout -s KILL 300 latexmk -pdf -interaction=nonstopmode main.tex
grep -iE "warning|error|undefined" main.log | grep -viE "Underfull|Overfull|Font|rerunfilecheck|infwarerr|empty anchor|multiple pdfs"
pdftotext main.pdf - | grep -c '(?)'
rm -f main.abs main.synctex.gz main.out main.fls main.fdb_latexmk   # keep main.aux, main.bbl, main.blg
```

The log filter comes from the CAS ports and should print nothing; anything it prints must be fixed or be one of the publisher file's known warnings. Debug one problem at a time.

Keep `main.bbl` and `main.aux`; never run `latexmk -c`. The author's editor may rebuild with a single pdflatex pass and no bibtex, and without the `.bbl` every citation becomes "?" in the PDF that gets uploaded. This happened at MSS and at JEI and was caught both times only because the author looked. If you cleaned, rebuild with the full chain. If the permission classifier blocks a command in the project folder (seen with `latexmk -c` in a Dropbox folder), compile in the scratchpad and copy the PDF back.

**Check:** filter output empty apart from known warnings; `(?)` count 0; no pdflatex process left running.

### 9. Prove faithfulness

Save as `LLM/bodydiff.py` and run `python3 LLM/bodydiff.py Paper/<source>.tex Submissions/<folder>/main.tex`:

```python
import difflib, re, sys

def body(path):
    t = open(path).read()
    start = min(t.find(m) for m in ('\\begin{abstract}', '\\abstract{') if m in t)
    return t[start:t.index('\\bibliography{')]

NORM = [(r'\\cite(?:t|p|alp|yearpar)?\{', r'\\cite{'),
        (r'\\begin\{(figure|table)\}\[pos=([^,\]]*)[^\]]*\]', r'\\begin{\1}[\2]'),
        (r'\\includegraphics(\[[^\]]*\])?\{[^}]*\}', r'\\includegraphics\1{FIG}')]

def norm(t):
    for a, b in NORM:
        t = re.sub(a, b, t)
    return [l.strip() for l in t.splitlines() if l.strip() and not l.lstrip().startswith('%')]

old, new = (norm(body(p)) for p in sys.argv[1:3])
print('\n'.join(difflib.unified_diff(old, new, 'revtex', 'port', lineterm='', n=0)))
```

The normalisation hides citation-command swaps (Step 5 lists those), float options, figure paths and comment-only changes. Acceptable output: the abstract wrapper, removed `\clearpage`/`\tableofcontents`, the split citations from Step 5, and the lines the publisher file lists. Anything else is content drift and gets reverted. Show the diff to the author. The author still reads the PDF in full; that is their check, not a substitute for this one.

**Check:** the diff is shown and every line in it is accounted for.

### 10. Zip and clean-room test

```bash
rm -rf upload && mkdir upload
cp main.tex main.bbl <bib>.bib <class, style, .bst files> <renamed figures> upload/   # plus the publisher file's extras
(cd upload && zip -q -X ../<Surname>_<Journal>_source.zip *)
Z=$PWD/<Surname>_<Journal>_source.zip; T=$(mktemp -d)
mkdir "$T/full" "$T/bbl" && (cd "$T/full" && unzip -q "$Z") && (cd "$T/bbl" && unzip -q "$Z")
(cd "$T/full" && timeout -s KILL 300 latexmk -pdf -interaction=nonstopmode main.tex >/dev/null; pdfinfo main.pdf | grep Pages; grep -c undefined main.log)
(cd "$T/bbl" && for i in 1 2; do timeout -s KILL 120 pdflatex -interaction=nonstopmode main.tex >/dev/null; done; grep -c undefined main.log)
```

The second build runs pdflatex only, no bibtex, which proves the shipped `.bbl` alone resolves every citation.

**Check:** both `undefined` counts are 0; the page count equals the local build.

### 11. Form texts and cover letter

`form_texts.txt` holds the text for every field of the submission form, paste-ready, with gaps flagged at the field, for example "ABSTRACT (138 words; JEI asks for 150–250, extend before pasting)". The abstract goes in as plain text: a raw `$\alpha$` or `--` shows as typed in a metadata field.

`cover_letter.txt`: adapt the author's previous cover letter if one exists (this project's `Submissions/*/` first; otherwise ask where): venue name, scope sentence, arXiv ID, code and data DOI, AI-use sentence, with the old venue's scope argument removed. The structure used so far: enclosure line; what the paper does; context and importance; fit with the journal; status (authorship, not under consideration elsewhere, arXiv ID, code and data DOI); sign-off with ORCID. With no earlier letter, ask for the key points rather than inventing them. The letter is prose in the author's name: continuous paragraphs, and the global style-guide rule applies.

### 12. Hand off

Give the author this list:

1. The Step 9 diff; then the PDF, read in full.
2. Limits against the guide, with the numbers: page count, abstract words, keyword count, highlights if the journal has them.
3. Declarations to confirm: competing interests, funding, data, AI use (does it name the tools?), CRediT where asked, and every standard sentence the port supplied.
4. The citation spots from Step 5 (`\citeyearpar`, splits).
5. ORCID in the manuscript or in the portal's author form.
6. The code and data deposit and its DOI if the journal's policy requires one (minting the DOI is the author's step).
7. The arXiv preprint updated to the latest RevTeX version before submitting (`arxiv-package`).
8. `cover_letter.txt` and `form_texts.txt` to edit.
9. The upload plan from the publisher file: which item gets which file, which field gets which text.
10. Open access and licence: the author checks APC coverage and funder requirements.
11. After upload: the publisher file's portal checks. The decision letter goes into the submission folder.

The submission folder then holds everything in "Folder layout", with `main.pdf` built with citations resolved and the zip clean-room tested.

## Re-porting to another journal of the same publisher

The previous port is the starting point, not the RevTeX file. Measured Sept 2026 (Physica A to MSS): under an hour.

1. New folder `Submissions/<YYYY-MM>_<NewJournal>/`; save the new guide (Step 1); copy the old `main.tex`, the `.bib` and the publisher extras; class files from `template/`; figures per Step 7.
2. Run the Step 9 diff of the old `main.tex` against the current RevTeX source first. If the RevTeX was edited after the previous port, the port is stale and the body is regenerated from RevTeX (Step 3).
3. Re-read the new guide for citation mode, abstract length, keywords, classification codes, figure naming, appendix numbering and declaration headings. Switch the natbib option, `.bst` or class option if the reference style differs; redo Step 5 when switching between numbered and author-year.
4. Strip the old journal's leftovers: its name in comments and in `highlights.tex`, highlight bullets that mention the venue, the old cover letter's scope argument.
5. Rebuild `cover_letter.txt` and `form_texts.txt`, then Steps 8 to 12.

## Porting across publishers

Not done yet. Start from the RevTeX source with the new publisher file, since the front matter, back matter and float syntax differ entirely. The cleaned `.bib`, and the classified citations if the citation mode matches, can probably be carried over from the other port (inferred, untested); the Step 9 diff against RevTeX still decides.

## What this skill does not do

- Edit the RevTeX source, the mathematics or the prose, or add sentences the guide does not require.
- Lengthen an abstract, or write an AI statement without the author's facts.
- Write a cover letter from nothing, or a response to referees (it adapts an existing letter).
- Choose the journal (`journal-picker`), package for arXiv (`arxiv-package`), mint a DOI, choose reviewers, check APC coverage, or submit.

## When a step fails

- **A compile error you cannot debug:** stop and show the author the log message. Do not guess, and do not try increasingly invasive fixes.
- **The class loads from `/usr/local/texlive/...` instead of `./`:** the class files are not next to `main.tex` (Step 2).
- **The bibliography fails:** `\bibliographystyle` must match the natbib option, and the `.bst` must be in the folder.
- **Citations show as "?" in the author's PDF:** the `.bbl` is missing and the editor ran one pass; rebuild with the full chain and keep the `.bbl` (Step 8).
- Publisher-specific symptoms are in the publisher file.

## Adding a publisher

A new publisher is one file, `publishers/<publisher>.md`, written from the template bundle's sample and manual and from one journal's saved guide. Every fact carries its source (guide, bundle file, measurement) and a date; anything not yet tested is marked as such. The file must specify:

1. **Template**: download location, bundle contents, which files go next to `main.tex`, file quirks (line endings, missing logo files), and whether the sample compiles on the local TeX Live.
2. **Guide access**: where journal guides live, which pages to save, and whether non-browser fetches work.
3. **Class line and options**: layout, the numbered and author-year switch, referee spacing, line numbers.
4. **Preamble**: packages the class loads (drop them from the RevTeX preamble), packages it lacks (add them), known conflicts.
5. **Front matter**: the mapping from RevTeX's title, author, affiliation, e-mail, abstract and keywords to the class macros, plus short title, corresponding author, ORCID and classification codes.
6. **Body transforms**: everything the class redefines that the body touches (float options, theorem styles).
7. **Citations and bibliography**: the `.bst` and natbib option for each mode, how a bare `\cite` renders, `.bst` quirks (title case, DOI printing).
8. **Figures and tables**: file naming, formats, resolution, table rules.
9. **Appendix numbering**: the mechanism for equations, figures and tables, and what the class does by default.
10. **Declarations**: markup, headings, order and position, with each prescribed sentence quoted from a guide.
11. **Known harmless warnings** in the log.
12. **Acceptable lines** in the Step 9 diff.
13. **Upload**: submission system and URL pattern, zip contents and extras, item types, what is uploaded separately, form fields, metadata the system extracts, checks on its review page.
14. **Publisher policies** that change the manuscript or the upload (data and code, AI use).
15. **Journals on record**: per-journal requirements already read, each with the date of the guide.

Then add the publisher to this skill's description and to the list at the top of this file, and to the hand-off in `~/Git/dotfiles/claude/agents/journal-picker.md` if it names publishers; run `python3 ~/Git/dotfiles/claude/tools/check.py`.
