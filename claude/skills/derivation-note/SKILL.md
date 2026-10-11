---
name: derivation-note
description: Writes a standalone companion note that derives one result of a paper completely explicitly (dictionary, conventions, every step), compiled with the draft's own preamble so its blocks can be pasted into the paper, for the author to check by hand or to answer a coauthor's question. Use on "write a derivation note", "make a note deriving X", "explain this step for the coauthors", "companion note". Do NOT use to edit the draft itself, to check a derivation (physics-review), or to draft paper sections (draft-sections).
---

# Derivation note

A note that makes one argument impossible to misread. The author reads it line by line, so nothing is left implicit; the paper's golden thread must survive, so the note says where each piece would go in the draft.

## Inputs

The result to derive and where it appears (draft section, equation); the project's `LLM/conventions.md`; the draft (`Paper/`) for notation and preamble. If the result was questioned (by a coauthor or a referee), the question verbatim.

## Structure

1. **Question**: what is being derived and why, one paragraph; the objection it answers, if any.
2. **Dictionary and conventions**: every symbol used, which bulk field sources which operator, the conventions from `LLM/conventions.md` with their sources, and each normalization marked as a convention (a choice) or a consequence (forced by something named).
3. **Derivation**: every step on its own line with its justification (an identity, an equation of the draft by label, an equation of motion, a boundary condition, a cited result with arXiv ID). No "it can be shown"; no step hidden in a phrase.
4. **Checks**: the limits and consistency checks performed, with the script that did them (`LLM/<name>.wls` or `.py`, run with `wlrun` for Mathematica) and their output.
5. **Not checked**: what the note assumes without verifying.
6. **For the paper**: paste-ready LaTeX blocks, each saying where it would go in the draft.

## Rules

- Write `LLM/<topic>_note.tex` compiled with the draft's preamble (`\input` it or copy it), so notation and macros match; compile with a KILL timeout and report warnings.
- Never edit `draft.tex` or any file in `Paper/`; the author moves blocks himself.
- When a new version replaces an old one, keep the old file (`_v1`) and say in one line what changed and why.
- Claims the note makes about the result's status stay in the note; if a stored memory disagrees with the note's finding, correct the memory with the date.
