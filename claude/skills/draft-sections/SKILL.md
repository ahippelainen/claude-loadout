---
name: draft-sections
description: "Ghost-drafts the specific paper sections the author dislikes writing — the introduction, the recap paragraphs that open the conclusions, and technical appendices — as inspiration text to rewrite, generated from the author's own notes and draft and matched to their style. Modes: intro, conclusions, appendix, learn-style. Triggers: write my introduction, draft the intro, write the conclusions recap, wrap up the conclusions, draft the appendix, golden-thread appendix, generate section from my notes. Do NOT trigger for: full-paper drafting (use academic-paper), reviewing a paper (academic-paper-reviewer), or checking physics correctness (physics-review)."
---

# draft-sections — ghost-draft the sections you'd rather not write

Generates the three sections the author routinely offloads — **introduction**, the **opening recap of the conclusions**, and **technical appendices** — from material the author has already written (research notes + the current draft), in the author's own voice. Output is always *inspiration to rewrite*, never a finished section.

## Non-negotiable principles

1. **Inspiration, not final text.** Everything you produce is raw material the author will rewrite. State this. Never imply the draft is submission-ready.
2. **Inferable-only for conclusions and appendix.** These two must contain *nothing that isn't already in the notes or draft* — no new results, no interpretation, no claims the author didn't make. Where the text is begging for a judgement the author must supply, leave an explicit `[author's take: …]` placeholder instead of inventing one. Dry is correct here.
3. **The introduction is the exception** — it needs outside literature, so it is allowed (required) to bring in real earlier work via web search. But it may never fabricate a citation. Every reference is either verified this session or marked `[verify]`.
4. **Style fidelity.** Read `~/Git/dotfiles/claude/contexts/authorial-style.md` first. If it is still the seed (unanalyzed), offer to run `style-analyst` on 2–5 of the author's prior papers before drafting; if the author declines, infer style from the current draft and say you did.
5. **Match the draft's LaTeX.** Detect the author's macros, environments, dash conventions, and equation punctuation from the current draft and emit copy-pasteable LaTeX in that dialect.

## Inputs to gather first

- **The notes** — the author's working notes for this paper (file path, or pasted). The substantive source.
- **The current draft** — the `.tex` (or its structure). Needed for: the intro's roadmap paragraph (which must match the *actual* section list, appendices included), and for conclusions/appendix to retell what the paper actually did.
- **Which section + mode.**

If notes and a draft both exist, read both. If only notes exist, say the roadmap/recap will be provisional until a draft structure is fixed.

---

## Modes

| Mode | Trigger | Produces |
|------|---------|----------|
| `intro` | "write my introduction" | Full introduction draft in three movements (below), with real candidate citations |
| `conclusions` | "conclusions recap", "wrap up the conclusions" | Only the opening recap paragraphs (NOT future directions) |
| `appendix` | "draft the appendix", "golden-thread appendix" | A plain sequential retelling of what the paper does |
| `learn-style` | "learn my style" | Hands off to the `style-analyst` agent, then stops |

### intro
The author's preferred shape, in three movements:
1. **Motivation** — a few paragraphs on why the problem matters and is interesting, citing earlier work. This is where you **web-search for real, relevant literature** (or, for a broad sweep, hand off to `lit-sweep`; BibTeX only via its `inspire.py bibtex`). Present candidate references with a one-line why-relevant each; the author chooses. Never invent a reference; mark anything unverified `[verify]`.
2. **What / how / why** — a few paragraphs stating what this paper does, by what method, and why that approach. Drawn from the notes.
3. **Roadmap** — one closing paragraph walking the paper section by section, **appendices included**, phrased in the author's roadmap template (see style profile). Read the draft's actual `\section`/`\appendix` structure so the roadmap is truthful.

Offer the motivation movement as 1–2 variants (e.g. broad-hook vs. gap-first opening) so the author can pick a direction.

### conclusions
Produce **only the opening recap** — the "golden thread in reverse": a dry, faithful walk back through what the paper set out to do and what it found, highlighting the main parts and results. Everything must be inferable from the notes/draft. Do **not** write the future-directions part; stop where it would begin and mark `% --- future directions: author writes ---`. Interpretation the author might add goes in `[author's take: …]`.

### appendix
Produce the **golden thread**: a simple, sequential account of the primary things the paper does — a collection of things done, written plainly, in the order the paper does them. Optional slots (`[historical remark?]`, `[extra detail?]`) mark places the author may enrich. Do not invent derivation steps that aren't in the notes; where a step is only sketched in the notes, render what's there and flag `[expand from notes]`.

---

## Workflow

1. Read the style profile (offer `style-analyst` if it's a seed).
2. Gather notes + draft; confirm section and mode.
3. `intro` only: run the literature search; assemble verified candidate citations.
4. Draft in the author's LaTeX dialect, applying the mode's discipline above.
5. Return the draft with: a one-line note that it's inspiration-grade, a list of every `[verify]` / `[author's take]` / `[expand]` placeholder left for the author, and (intro) the citation candidates with links.

Keep your own commentary minimal — the deliverable is the section text, not a discussion of it.
