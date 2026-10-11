---
name: arxiv-package
description: "Bundles exactly the files an arXiv submission needs — the LaTeX source, the .bib, and only the figures actually referenced — into a .tar.gz, then proves it by compiling the extracted archive in a clean directory before handing it over. Triggers: package this for arxiv, make the arxiv tarball, prepare the arxiv upload, bundle the paper for submission, what do I upload to arxiv. Do NOT trigger for: publishing code/data to GitHub (use share-to-github) or writing/formatting the paper itself (academic-paper)."
---

# arxiv-package — assemble and verify the submission tarball

Produces the `.tar.gz` to upload to arXiv, containing precisely what arXiv needs and nothing else, verified by a clean-room compile.

## What arXiv needs (current policy)

arXiv processes a `.bib` itself (BibTeX, or biblatex with Biber, selected automatically) and uses a `.bbl` instead whenever one is present (info.arxiv.org/help/submit_tex.html, checked 2026-09-29). TeX Live 2025 is the default (2023 also available). So the submission is:

- the main `.tex` source;
- the bibliography **`.bib`** file(s) — including any auto-generated companion the document class emits (e.g. RevTeX writes a `…Notes.bib` holding `@CONTROL` records; include it if present);
- **only the figures the source actually `\includegraphics`** — grep them out; do not ship the rest of the images folder.

A `.bbl` is optional; the default here is bib-only. Include one when the author wants the exact bibliography he compiled; it must then match arXiv's format (with biblatex on TeX Live 2025: bbl format 3.3), and it takes precedence over the `.bib`. Do not upload `.aux/.log/.out/.toc/.synctex.gz`, editor scratch files, or unused figures.

## Workflow

1. **Confirm the fileset with the author.**
   - Find the main source (the `.tex` with `\documentclass` + `\begin{document}`).
   - List `\bibliography{…}` / `\addbibresource{…}` targets and locate those `.bib` files; detect any class-generated companion bib.
   - `grep` every `\includegraphics` to get the referenced-figure list; resolve extensions. Report any files in the images folder that are **not** referenced (they will be dropped) and any referenced file that is **missing** (blocker).
   - Present the proposed archive contents for a yes/no.
2. **Assemble** into a temp staging dir, preserving the referenced subfolder layout (`images/…`); paths are case-sensitive. Keep the structure flat and predictable.
3. **Clean-room compile test.** Extract the tarball into a fresh empty directory (so the test can only use what's inside it) and run the real bibliography cycle: `pdflatex → bibtex → pdflatex → pdflatex`. Then verify:
   - page count is as expected;
   - **zero** undefined citations or references in the log;
   - no missing-figure / missing-file errors;
   - all fonts embedded (`pdffonts` shows no "no" in the embedded column).
   Report the numbers. If it fails, the archive is wrong — fix the fileset, don't ship it.
4. **Deliver** the `.tar.gz` path and its contents list. Note the arXiv form choices to make deliberately: primary + cross-list categories, and the license (the default arXiv non-exclusive license keeps later journal submission unconstrained; only pick CC-BY if the author wants it).

## Notes

- If the repo build was stale, regenerate before packaging so the shipped source is what actually compiles.
- A cosmetic but real point: the source is downloadable from arXiv, so a source file literally named `draft…`/`vN_final` is visible to readers — offer to rename to something neutral.
- Keep the archive minimal: every extra file is a potential processing surprise on arXiv's side.
