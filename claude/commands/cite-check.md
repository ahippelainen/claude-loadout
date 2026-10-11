---
description: Check a paper's citations against its .bib (missing, unused, duplicate keys) and the .bib against INSPIRE/Crossref records; report only
argument-hint: "[optional: path to the main .tex]"
---

Report the citation state of the paper. Edit nothing (not the .tex, not the .bib) unless I ask after the report.

1. **Main .tex.** $ARGUMENTS if given. Otherwise look in `Paper/` (or `paper/`), then the project root, for `.tex` files containing `\documentclass`. One candidate: use it. Several: take the one containing `\begin{document}` that no other file `\input`s or `\include`s; if still ambiguous, list them and ask.
2. **Source set.** Follow `\input{}`, `\include{}` and `\subfile{}` recursively from the main file (add `.tex` when the extension is missing; paths relative to the main file's directory). Ignore everything after an unescaped `%` on a line.
3. **Cited keys.** Collect keys from every citation command: `\cite`, `\citep`, `\citet`, `\citealt`, `\citealp`, `\citeauthor`, `\citeyear`, `\citenum`, `\Cite`, `\Citep`, `\Citet`, `\parencite`, `\textcite`, `\autocite`, `\footcite`, `\nocite`, including starred forms and optional `[...]` arguments; split on commas and trim. `\nocite{*}` makes every .bib entry count as used.
4. **Bibliography files.** From `\bibliography{a,b}` (append `.bib`) or `\addbibresource{x.bib}`, relative to the main file's directory.
5. **Compare** and list:
   - missing: cited, not in any .bib (with file:line of the first citation);
   - unused: in the .bib, never cited;
   - duplicate keys: the same key twice, or keys differing only in case;
   - duplicate works: different keys with the same `eprint` or `doi`.
6. **Log.** If a `.log` or `.blg` for the main file exists (next to it, or in the latexmk `$out_dir` from a `latexmkrc`), add its undefined-citation and BibTeX warnings, and say how old the log is relative to the .tex.
7. **Records.** Run `python3 ~/Git/dotfiles/claude/skills/lit-sweep/inspire.py check <bib>` for each .bib. It queries INSPIRE, and Crossref for DOIs INSPIRE lacks, pausing 0.4 s between requests; running this command is the go-ahead for that traffic. Relay its title / first-author / year / eprint / DOI mismatches, not-found entries, working-paper notes and the list of entries it could not check (no eprint or doi).
8. **Proposals, not edits.** For missing keys that look like INSPIRE texkeys (`Surname:2019abc`), or for which an arXiv id or DOI is known from the context, run `inspire.py bibtex <id>` and show the entries it returns, labelled with their source. Never write a BibTeX entry from memory.

Report tersely, one line per item, under the headings of steps 5–8 (omit empty ones), then one line of counts. A mismatch is a lead for me to check against the paper itself, not a verdict: a changed journal title or a collaboration listed as author can trigger one.
