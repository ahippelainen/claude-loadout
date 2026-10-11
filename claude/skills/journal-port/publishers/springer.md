# Springer Nature: sn-jnl

Publisher file for `journal-port`; read `../SKILL.md` first. The records come from the Lorenz-curvature paper's submission to The Journal of Economic Inequality, JEI (Sept 2026, author-year, built on TeX Live 2023, Springer Nature's submission portal). Items tagged JEI come from its guidelines as saved then; re-check each against the guide you saved.

## Template

- One template for all Springer, Nature Portfolio and BMC journals: `sn-jnl.cls`, v3.1 (Dec 2024). The journal-specific part is only which `.bst` and what the guidelines ask for (abstract length, keywords, classification codes, figure naming, declarations).
- Bundle: `sn-jnl.cls`, `bst/sn-{basic,chicago,apacite,aps,mathphys-num,mathphys-ay,nature,vancouver-num,vancouver-ay}.bst`, `sn-article.tex` (sample), `user-manual.pdf`. Download page `https://www.springernature.com/gp/authors/campaigns/latex-author-support`; the zip link is a `cms-resources.apps.public.k8s.springernature.io/.../18782940/data/v12` URL (measured Sept 2026: 880 KB, fetchable with curl).
- The shipped files have CR/CRLF line endings, so `grep` on them returns nothing. Normalise with `tr -d '\r'` or read them in Python.
- `sn-article.tex` and `user-manual.pdf` stay in `template/`; test-compile the sample once (`latexmk -pdf sn-article.tex` compiled cleanly on TeX Live 2023).
- Next to `main.tex`: `sn-jnl.cls` and the chosen `.bst` (the JEI zip shipped `sn-basic.bst` only).

## Guide

link.springer.com is cookie-walled for WebFetch and curl (303 to `idp.springer.com`, then a 3 KB stub; measured Sept 2026). Ask the author to print the journal's "Submission guidelines" and "How to publish with us" pages to PDF into `journal_info/`, plus one or two recent articles from the journal, whose reference lists show the citation style.

## Class line and options

`\documentclass[pdflatex,sn-basic]{sn-jnl}`. The reference style is a class option, one per `.bst`. `sn-basic` and `sn-chicago` are author-year by default and numbered with the extra option `Numbered`; the bundle's numbered math-and-physics style is `sn-mathphys-num` (no Springer physics journal has been ported yet, so which style such a journal wants comes from its guide). `referee` gives double spacing, `lineno` line numbers, `iicol` two columns; use none unless the journal asks.

## Preamble

```latex
\documentclass[pdflatex,sn-basic]{sn-jnl}
\usepackage{graphicx}
\usepackage{amsmath,amssymb,amsfonts}
\usepackage{amsthm}
\usepackage{mathrsfs}
\usepackage[title]{appendix}
\usepackage{xcolor}
\usepackage{textcomp}
\usepackage{physics}                         % only if the body uses \qty, \dd, \pdv

%% macros carried over from the RevTeX source, only those the body uses

\let\cite\citep                              % optional bulk conversion, see SKILL.md Step 5

%% the class's \orcid inserts Orcidlogo.eps, which Springer does not ship
\gdef\orcid#1{\,\href{https://orcid.org/#1}{\textsf{\footnotesize ORCID: #1}}}

\theoremstyle{thmstyleone}
\newtheorem{theorem}{Theorem}
\newtheorem{definition}{Definition}
\raggedbottom
```

- `\newtheorem` must be preceded by `\theoremstyle{thmstyleone|thmstyletwo|thmstylethree}` (bold-italic, roman-italic, bold-roman); the class errors on a plain `\newtheorem`.
- Drop from the RevTeX preamble, unless the body uses them: `inputenc`, `lmodern`, `geometry`, `setspace`, `hyperref`, `float`, `tcolorbox`, `tikz`, `enumitem`, `subcaption`.
- Instead of redefining `\orcid`, the ORCID can be left to the portal's author form.

## Front matter

```latex
\begin{document}
\title[Running title]{Full title}
\author*[1]{\fnm{First} \sur{Last}\orcid{0000-0000-0000-0000}}\email{...}
\affil*[1]{\orgdiv{Department}, \orgname{University}, \orgaddress{\street{...}, \postcode{...}, \city{...}, \country{...}}}
\abstract{...verbatim...}
\keywords{k1, k2, k3, k4, k5}
\pacs[JEL Classification]{D31, D63, C43}   % \pacs[MSC Classification]{...} likewise
\maketitle
```

No `\tableofcontents`, no `\clearpage`. The portal fills title, abstract and keywords from the `.tex`, so a raw `$\alpha$` or `--` in `\abstract{}` lands in the metadata field; the author edits that field to plain text on the Review page.

## Citations and bibliography

- The class loads natbib; a bare `\cite` is textual (`\citet`). With an author-year `.bst` that renders "economics Salverda et al. (2011)." for an aside; classify per `SKILL.md` Step 5. Multiple keys in one bracket are joined with semicolons.
- JEI (Sept 2026): author-year in the text, "(Thompson 1990)", "Becker and Seligman (1996)"; reference list "Author, A.B.: Title. J. Abbrev. vol(issue), pages (year)", alphabetical, with full DOI links. That is `sn-basic` in author-year mode.
- `sn-basic` lowercases titles after the first word: brace proper nouns and quoted titles.
- A code or data deposit is cited following Springer's data-citation guidance (creator, title, repository, year, DOI): the `@misc` entry in `SKILL.md` Step 6.

## Figures

JEI guideline: "Name your figure files with 'Fig' and the figure number, e.g. Fig1.eps", so `NAME = 'Fig{}{}'` in `SKILL.md` Step 7. EPS or TIFF are preferred, but PDF and PNG compiled fine through the portal (JEI, Sept 2026). Fonts embedded; 600 dpi for combination art.

**Check:** the PDF captions read Fig. 1 to N, with no A-prefix in the appendices if the journal numbers figures continuously.

## Back matter and appendices

Template order:

```latex
\bmhead{Acknowledgements}
...verbatim...

\section*{Declarations}
\bmhead{Competing interests}
The author declares no competing interests.
\bmhead{Use of large language models}   % only if applicable, the author's own wording
...
\bmhead{Data and code availability}
...verbatim, plus the deposit DOI if there is one...

\newcounter{mainfigures}\setcounter{mainfigures}{\value{figure}}
\begin{appendices}
\setcounter{figure}{\value{mainfigures}}\renewcommand{\thefigure}{\arabic{figure}}
...verbatim appendix...
\end{appendices}

\bibliography{<bib>}
\end{document}
```

- `\bmhead{...}` gives the unnumbered run-in heads: the acknowledgements and each item under `\section*{Declarations}`.
- `appendices` resets the figure, table and equation counters to `A1` style. JEI's guideline says "continue the consecutive numbering of the main text. Do not number the appendix figures A1, A2", hence the two counter lines; equations `(A1)`, `(B13)` were fine. Tables would need the same treatment if a journal asks for it (untested).
- Competing interests: the standard sentence above.
- AI use: Springer's policy asks that LLM use be documented in the Methods section or "a suitable alternative part"; "AI-assisted copy editing" needs no declaration. For use beyond copy editing, the JEI port put a `\bmhead{Use of large language models}` paragraph under Declarations, in the author's own words.
- Funding: with no grant, Springer's sample sentence is "The author did not receive support from any organization for the submitted work." At JEI it went into the portal's funding field; if a guide asks for it in the manuscript, it becomes one more `\bmhead` under Declarations.
- Data and code at JEI (Sept 2026): the replication policy asks for data, code, a source list and a description document in a repository from the Social Science Data Editors list (Zenodo, openICPSR, Dataverse, OSF). GitHub alone does not qualify, a personal Dropbox never does. A Zenodo release of the GitHub repository, with its DOI cited in the data statement and in the reference list, satisfies it. It was done at submission, although strictly the policy applies only to the final version.

## Known warnings

Three `Package hyperref Warning: Difference (n) between bookmark levels` lines from the class's Declarations and appendix heading structure. Harmless; the portal's Review page reports the same three.

## Acceptable lines in the body diff

`\abstract{` in place of the abstract environment, `\keywords` and `\pacs`, removed `\clearpage` and `\tableofcontents`, the `\bmhead` lines, the Declarations block, `appendix` replaced by `appendices` plus the counter lines, and the deposit clause in the data sentence.

## Upload

- Portal: `https://submission.nature.com/new-submission/<journal-number>/3`, not Editorial Manager. Pages: Files, Details, Authors, Declarations, Review. The portal compiles the zip itself and shows the log warnings on the Review page.
- The Manuscript item is one flat zip ("Please do not use subfolders for your LaTeX submission"): `main.tex main.bbl <bib>.bib sn-jnl.cls sn-basic.bst Fig*`. At JEI the figures-separately, supplementary and related-files slots stayed empty at initial submission.
- Form fields at JEI, each prepared in `form_texts.txt`: cover letter ("briefly discuss the context and importance of the submitted work and why it is appropriate for the journal"); author-contribution statement with initials ("<Initials> is the sole author and carried out all parts of the work: ..."); competing interests; data availability (the manuscript sentence); acknowledgements; funding; hybrid-journal acknowledgement; Research Square preprint opt-in (No at JEI, the paper being on arXiv already); suggested reviewers (optional, an institutional e-mail for each).
- Review-page checks: compile "successful"; the extracted abstract has no `$...$` or `--`; the affiliation matches the manuscript (the portal dropped "Department of Physics" once); page count and last reference in the portal's PDF match the local build; Research Square is No.
- APC: the author checks coverage under the institution's Springer agreement.

## Journals on record

- **The Journal of Economic Inequality** (guidelines saved Sept 2026): author-year, `sn-basic`; abstract 150–250 words (count it and flag if outside); 4–6 keywords; JEL codes required; figures `Fig1`…, numbered continuously through the appendices; replication policy as above.
- Social Choice and Welfare, Empirical Economics, Journal of Economic Interaction and Coordination, European Physical Journal B: no port recorded.
