# Elsevier: CAS classes

Publisher file for `journal-port`; read `../SKILL.md` first. The records come from the Pareto paper's two ports: Physica A (guide saved May 2026, numbered, Editorial Manager) and Mathematical Social Sciences, MSS (guide saved Sept 2026, author-year, Elsevier's new submission system). Items tagged with a journal and date come from that journal's guide as saved then; re-check each against the guide you saved.

## Template

- `cas-sc.cls` (single column) or `cas-dc.cls` (double column); both load `cas-common.sty`. The older `elsarticle.cls` is a different class with its own `.bst` files and is not used here. The bundle's `cas-sc-template.tex` is the canonical syntax.
- Bundle: `els-cas-templates.zip` from `https://www.elsevier.com/researcher/author/policies-and-guidelines/latex-instructions`. The Sept 2026 download from the MSS guide's LaTeX link was byte-identical to the May 2026 one, so a bundle kept from an earlier submission is normally fine.
- Next to `main.tex`: the class, `cas-common.sty` and the `.bst` (see Citations). `thumbnails/` (`cas-{email,url,facebook,twitter,gplus,linkedin}.jpeg`, author-info icons that `cas-common.sty` references) only if the log asks for it: both Pareto builds with `cas-sc` compiled without it (Sept 2026).
- Layout: both Pareto submissions used `cas-sc`. The Physica A guide permits double column (`cas-dc`) for LaTeX submissions only.

## Guide

`https://www.sciencedirect.com/journal/<journal-slug>/publish/guide-for-authors`; the elsevier.com guide URL redirects there. ScienceDirect serves a captcha to WebFetch and curl (measured Sept 2026), so the author opens the guide in a browser and saves it as PDF into `journal_info/`. Sections to read: aims and scope, article types, peer review, title page, abstract, keywords, highlights, article structure (appendix numbering), figures, references, declarations (competing interest, funding, data, generative AI, CRediT), submit online.

## Preamble

```latex
\documentclass[a4paper,fleqn]{cas-sc}
\usepackage[numbers]{natbib}   % [authoryear] for author-year journals, see Citations
\usepackage{amsthm}            % cas-sc does not load it; needed for \theoremstyle, \newtheorem, proof
\usepackage{mathtools}
\usepackage{physics}           % only if the body uses \qty, \dd, ...; no conflict with CAS
\usepackage{enumitem}
\usepackage[english]{babel}
```

This is the Pareto ports' preamble; drop what the body does not use. CAS already loads amsmath, amsfonts, amssymb, graphicx, hyperref, xcolor, inputenc, fontenc and booktabs: drop those from the RevTeX preamble, together with `\hypersetup` overrides (CAS sets its own) unless the author has a reason to keep one.

## Front matter

```latex
\begin{document}
\let\WriteBookmarks\relax

\shorttitle{Short title}              % required: running heads
\shortauthors{F. Last}                % required

\title[mode=title]{Full title}

\author[1]{First Last}[orcid=0000-0000-0000-0000]   % omit [orcid=...] if none
\cormark[1]
\ead{email@institution}
\credit{Conceptualization, Formal analysis, Visualization, Writing -- original draft, Writing -- review and editing}

\affiliation[1]{organization={Institution},
                addressline={Street or PO Box},
                postcode={...},
                city={...},
                country={...}}

\cortext[1]{Corresponding author}

\begin{abstract}
...verbatim...
\end{abstract}

% \input{highlights}

\begin{keywords}
keyword1 \sep keyword2 \sep keyword3
\end{keywords}

\maketitle
```

- Several authors: `\author[1]{A}`, `\author[2]{B}` with `\affiliation[1]{...}`, `\affiliation[2]{...}`; two affiliations for one author: `\author[1,2]{Name}`. A present-address note: `\fnmark[1]` on the author, `\fntext[1]{Present address: ...}`.
- No `\clearpage` after `\maketitle`; CAS handles the spacing.
- If `\maketitle` errors, look for a missing `\affiliation` or mismatched `[i]` indices.

## Highlights

Physica A (May 2026): 3–5 bullets, at most 85 characters each including spaces, submitted as a separate editable file with "highlights" in the filename. MSS (Sept 2026) also took a highlights file. CAS can print them on a separate page via `\begin{highlights}`; keep `\input{highlights}` commented out so that page does not appear during drafting, and upload the file separately.

```latex
% 3-5 bullets, max 85 characters each including spaces (journal guide)
\begin{highlights}
\item ...
\end{highlights}
```

Highlights are new text in the author's name: offer a draft built from the abstract's own claims, marked as a draft, and list it in the hand-off. Length check: `sed -n 's/^\\item //p' highlights.tex | awk '{print length($0) ": " $0}'`.

## Body transforms

**Float options are keyval, not a float specifier.** `cas-common.sty` redefines `figure` and `table` with `\RenewDocumentEnvironment{figure}{O{}}{...}` and parses the optional argument as keys. Write `\begin{figure}[pos=ht]`, never `\begin{figure}[ht]`; bare `\begin{figure}` is fine (position defaults to `t`). The `[ht]` form lays out correctly on TeX Live 2023, but on TeX Live 2025 it parses to an empty position and every float is deferred to the end of the document, with "No positions in optional float specifier" warnings. A correct-looking local build proves nothing, so convert always. Keys: `pos`, `width`, `cols`, `align`, `abovecap`, `belowcap`, `abovefig`, `belowfig`, `full`; for example `[pos=ht, width=0.6\linewidth]`.

**Check:** `grep -nE '\\begin\{(figure|table)\}\[' main.tex | grep -v 'pos='` is empty.

**Tables.** Physica A (May 2026): "Avoid vertical rules and shading within table cells." Replace `\hline` and `|` column specs with `\toprule`, `\midrule`, `\bottomrule` (booktabs, loaded by CAS); text columns `l`, numeric `c`, aligned currency or decimals `r`.

**Check:** `grep -nE '\\hline|\\begin\{tabular\}\{[^}]*\|' main.tex` is empty.

## Citations and bibliography

- Numbered (Physica A): `\usepackage[numbers]{natbib}` with `\bibliographystyle{elsarticle-num}`; square brackets, order of first appearance. The notes say to take `elsarticle-num.bst` from TeX Live rather than the CAS bundle; either way, copy it next to `main.tex`.
- Author-year (MSS): `\usepackage[authoryear]{natbib}` with `\bibliographystyle{cas-model2-names}`, which ships in the CAS bundle. `elsarticle-harv` is the author-year style of the plain elsarticle class, not of CAS. No `longnamesfirst`: the MSS style uses "et al." from the first citation for three or more authors. MSS guide examples: "(Allan, 2020a, 2020b; Allan and Jones, 2019)", "Kramer et al. (2023) have recently shown"; list alphabetical, then chronological. Every `\cite` is classified (`SKILL.md` Step 5).
- `cas-model2-names` lowercases titles: brace proper nouns. Keep DOI fields bare, or the output prints `doi:https://doi.org/`.
- Physica A (May 2026): "This journal does not set strict requirements on reference formatting at submission"; the journal style is applied at proof stage.
- Physica A guide: mark datasets and software with `[dataset]` or `[software]` before the title; mark preprints with the server and ID (`note = {arXiv preprint arXiv:NNNN.NNNNN}`); avoid references in the abstract, and if one is essential cite it in full as "(Author, Year)". Flag an abstract that contains `\cite`.

## Figures

- The guides ask for each image as a separate file "using a logical naming convention (Figure_1, Figure_2 etc.)": `NAME = 'Figure_{}{}'` in `SKILL.md` Step 7. Figures go into the source zip and are also uploaded individually.
- Physica A (May 2026) minimum resolutions: vector drawings as EPS or PDF with fonts embedded or outlined; photos and halftones 300 dpi; bitmapped line drawings 1000 dpi; combinations 500 dpi (TIFF, JPG or PNG).
- Physica A guide: generative AI in figures only if it is part of the research method, described reproducibly; never for graphical abstracts.

## Appendix numbering

The guides ask for `(A.1)`, `(B.1)` in appendices. CAS letters the appendix sections but keeps numbering equations consecutively (the Physica A PDF ran (51) to (62) through the appendices). Add one line:

```latex
\appendix
\numberwithin{equation}{section}
```

**Check:** `pdftotext main.pdf - | grep -o '([A-Z]\.[0-9]*)' | sort -u` lists A.1, …, B.1, …; body equations unchanged. The Physica A guide also asks for `Fig. A.1` and `Table A.1` in appendices; no recipe is recorded for that yet, so check the PDF.

## Declarations

After `\section*{Acknowledgements}` (verbatim) and before `\appendix` or the bibliography:

```latex
\section*{Declaration of competing interest}
The author declares no competing financial or personal interests. [funding sentence]

\section*{Data availability}
[the author's statement]

\section*{Declaration of generative AI and AI-assisted technologies in the manuscript preparation process}
[only if AI was used]

\printcredits
```

- Funding, with no grant: "This research did not receive any specific grant from funding agencies in the public, commercial, or not-for-profit sectors." With one: "Funding: This work was supported by [Funder] [grant numbers]." The Pareto ports appended it to the competing-interest declaration, since both concern financial relationships.
- The AI heading above is prescribed verbatim by the MSS guide (Sept 2026). The guide's template: "During the preparation of this work the author(s) used [NAME OF TOOL / SERVICE] in order to [REASON]. After using this tool/service, the author(s) reviewed and edited the content as needed and take(s) full responsibility for the content of the published article." It does not apply to basic tools (grammar, spelling, reference managers). Keep the author's existing wording, but flag it if it names no tool.
- `\printcredits` prints the CRediT block from `\credit{}` and goes right before `\bibliography`. CRediT roles: Conceptualization, Data curation, Formal analysis, Funding acquisition, Investigation, Methodology, Project administration, Resources, Software, Supervision, Validation, Visualization, Writing – original draft, Writing – review and editing. A single-author paper still needs the statement.
- Data: the Physica A guide requires a statement even when no data exist ("To foster transparency, you are required to state the availability of any data at submission"). The notes disagree on whether the statement also has its own submission-form field; check the journal's guide and the form. The in-manuscript section is in both Pareto ports.
- Competing interest: the Physica A notes (May 2026) describe Elsevier's declarations tool, which produces a `.doc`/`.docx` to upload; the MSS form (Sept 2026) took pasted text. Check the journal's guide and the form. The in-manuscript section is in both.

**Check:** competing interest (with funding), data availability, AI declaration if applicable, `\printcredits`, in that order.

## Acceptable lines in the body diff

The keywords block, the removed `\clearpage`, booktabs rules replacing `\hline` and `|` column specs, the declarations block with `\printcredits`, the `\numberwithin` line, and the `\bibliographystyle` line.

## Upload

- Systems: Elsevier is moving journals from Editorial Manager to `https://submit.elsevier.com/<JOURNALCODE>` (MSS in Sept 2026, `.../MSS`; its old `editorialmanager.com/mss` page said "Site under development. Do not use for live manuscript submission"). Physica A still used `https://www.editorialmanager.com/physa/default.aspx` in May 2026. Take the live link from the journal homepage's "Submit your paper".
- Items in the new system (MSS, Sept 2026): the manuscript item is the compiled PDF; the LaTeX source is one flat zip under the source-file item type, never under supplementary material, which is published as submitted; each `Figure_N` file individually; `highlights.tex` as the highlights file; declarations as the form asks (see Declarations); 3–5 classifications from the journal's own list.
- Classifications: MSS uses JEL two-digit codes. For the inequality-measurement paper the fit was D3 Distribution, D6 Welfare Economics, C6 Mathematical Methods and Programming, C4 Statistical Methods: Special Topics. Choose by where the referees should come from, not by keyword overlap. Physics journals use their own subject lists.
- Also in the form: open access and licence (the Physica A guide says to check funder requirements before choosing), optional suggested reviewers, CRediT and competing-interest confirmation.
- Physica A guide: editable source files are required at submission or at revision. Supplementary files are submitted with the manuscript, can be added or replaced only at revision, are cited in the text, each with a caption, and are not typeset.
- Zip contents: `main.tex main.bbl <bib>.bib cas-sc.cls cas-common.sty <bst> Figure_*`.
- Symptom: "No positions in optional float specifier" means the float conversion was missed (Body transforms).

## Journals on record

- **Physica A** (guide saved May 2026): numbered; research article at most 30 pages, mini review at most 10; abstract at most 250 words; 1–7 keywords; highlights as above; no vertical rules or shading in tables; appendix equations (A.1); SI units required ("If other units are mentioned within your article, you should provide the equivalent unit in SI"); scope requires that papers "explicitly utilize concepts, models, and techniques from statistical mechanics" (the Pareto paper was desk-rejected there on scope, June 2026). Editorial Manager.
- **Mathematical Social Sciences** (guide saved Sept 2026): author-year with `cas-model2-names`; the AI-declaration heading above; highlights file; JEL classifications; new submission system at `submit.elsevier.com/MSS`. Other limits were not recorded here; read them from the guide.
