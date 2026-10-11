---
name: academic-paper
description: "Drafts and revises the author's hep-th/hep-ph and economics papers from his own notes, results and draft. Modes: outline, draft (subsection by subsection, as paste-ready LaTeX in LLM/), abstract, revision (from a review roadmap), response (coaching on real referee reports: parsed comments, roadmap, response-letter skeleton, completeness check). Triggers: outline the paper, turn my notes into a paper, draft section X, write the abstract, revise per the roadmap, I got referee reports, help me answer the referees, response letter. Do NOT trigger for: literature searches (lit-sweep), citation checks (/cite-check), porting to a journal template (journal-port), simulated peer review (academic-paper-reviewer), derivation checks (physics-review), the introduction, conclusions recap or golden-thread appendix (draft-sections), choosing a journal (journal-picker agent)."
---

# academic-paper

Turns the author's material into paper text he then rewrites, and helps him answer referees. Content comes only from his notes, results, notebooks, draft and bibliography; this skill supplies structure and prose, never physics, economics or numbers.

## Rules

1. **Only his material.** Where the outline needs something the material lacks, write `[MATERIAL GAP: what is missing]`. Never add a result, a derivation step, a number or an interpretation. A citation not in the project's `.bib` or a lit-sweep file is `[CITE: what is needed]`; get it through lit-sweep, never from memory.
2. **His files are his.** New text goes to `LLM/<YYMMDD>_<section>.tex` as paste-ready blocks. Edit the draft or the notes only when he names the scope in this turn.
3. **His LaTeX.** Copy the class, macros, citation commands, dash and equation-punctuation conventions from the existing draft or notes; do not choose a class. For a new JHEP draft the class is `article` with `\usepackage{jheppub}` (not `\documentclass{jheppub}`); APS journals use `revtex4-2`; porting to Springer or Elsevier is journal-port's job. Page, word and abstract limits and section rules: check the journal's current author guide, never quote them from memory.
4. **His style.** Follow the author's style notes where CLAUDE.md names them; where there are none, say you are guessing. Avoid throat-clearing openers, sentences announcing what a section will do, lists padded to three, synonym cycling for a technical term, and "we show that" without the result.
5. **Hand-over.** Every block comes with the list of placeholders left (`[MATERIAL GAP]`, `[CITE]`) and the sources it drew on (file and section or line).

## Modes

### outline
Input: notes, results, any draft. Output: a section plan in which each section lists the content it carries (with where it sits in the notes), its equations and figures, and the claim it supports; then the paper's main claims as the notes state them, each with where it is established (equation, figure, notebook). Follow the structure of his existing papers or notes. Defaults: hep-th: introduction, setup or model, main computation, results, discussion and conclusions, appendices; economics: introduction, related literature if the journal expects a separate section, model or framework, results, discussion and conclusions. Ask only about choices only he can make (the headline result, what goes to appendices). **Checkpoint:** he confirms the outline before any drafting.

### draft
One subsection at a time: draft it, he rewrites it, then the next. Each block: LaTeX in his dialect, placeholders, sources. The introduction, the conclusions recap and the golden-thread appendix go to draft-sections. A related-work paragraph uses only the `.bib` and the lit-sweep notes, and keeps their tags: another paper's ASSERTED claim is not described as its result, and an `[abstract only]` paper is cited for what its abstract claims, if at all.

### abstract
Problem; what was done; the main result stated specifically (the number, scaling, sign or condition as the body states it); its implication. One or two variants. Nothing that is not in the body. Length from the journal's guide.

### revision
Input: `decision.md` from academic-paper-reviewer, or his own list. For each item: the proposed change as a paste-ready block with its location. Items needing a new calculation or analysis are listed for him, not attempted. Afterwards suggest /cite-check if references changed, and academic-paper-reviewer's re-review mode.

### response (real referee reports)
1. **Parse.** Every comment verbatim, multi-point comments split, numbered `E.1` (editor), `R1.1`, `R1.2`, `R2.1`, ...; nothing dropped (state the count). Ask where a boundary or a meaning is unclear.
2. **Classify and locate.** Must address (the editor requires it, or it challenges correctness, novelty or a stated claim), should address, editorial, positive; map each to a section or equation. Flag referees who contradict each other, and comments that look technically wrong (for a disputed derivation, physics-review in verify mode; he decides).
3. **Coach**, for each must-address comment: the referee's actual concern; agree, partly agree or disagree, which is his call; what the answer would say and what change it implies; the risk of declining. Do not default to accepting everything: referees can be wrong. Arguments for disagreeing come from his material, not from invention.
4. **Output** in `LLM/<YYMMDD>_response/`: `roadmap.md` (id, summary, class, location, planned action, status) and a response-letter skeleton that quotes each comment, with `Response:` and `Changes:` placeholders for him. Status: RESOLVED (change and location), CLARIFIED (explained, and the text changed so the misreading cannot recur), DECLINED (with the argument and its evidence). Reuse the format of an earlier response letter in the project if there is one.
5. **Completeness check** before resubmission: every comment has a response; every "changed in Sec. X" is present in the revised source (diff old against new); new references pass /cite-check.

## Failure paths

| Situation | Handling |
|---|---|
| Too little material to write from | Say what is missing; literature gaps go to lit-sweep; nothing filled from memory |
| A derivation is needed | Stop: derivations are his. Checking one is physics-review |
| A referee comment contradicts the physics or the economics | Flag it with the reason; he decides |
| No target journal yet | journal-picker agent |

## Place in the pipeline

lit-sweep → academic-paper (outline, draft, abstract) → /cite-check → academic-paper-reviewer → academic-paper (revision) → re-review → journal-port → arxiv-package. Real referee reports enter at the response mode.
