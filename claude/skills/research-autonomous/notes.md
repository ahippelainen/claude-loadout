# Notes for the owner: lecture notes and companion notes

The owner signs off (V3) only on what he has understood end to end, so a program writes its way to him. Two kinds of document, both LaTeX books under the program root, both built by `build.sh` with `latexmk` under a KILL timeout.

## Lecture notes: from basics to the research horizon

- **Plan card first.** One planner agent writes `COMMON_SPEC.txt` (the reader, read order, macros and environments, status-tag convention, house style, what each chapter exports), `PROGRESS.txt` (chapter list, dependencies, status, writing order) and one stub per chapter whose commented PLAN block is that chapter's brief (scope, prerequisites, theorems, examples, exercise themes, length target, labels to export).
- **The reader** is the owner as he is: say what he knows and what he does not (for a physicist: fluent in differential geometry, Lie groups, complex analysis; not trained in algebraic geometry or number theory). Physics analogies only where honest, in a box that says where the analogy stops.
- **One fresh agent per chapter**, sequentially in a dedicated slot, each reading COMMON_SPEC, the preamble (never editing it), PROGRESS, its stub and the chapters it depends on. A chapter agent never commits.
- Every new object: motivation, an intuition box, a worked example with actual numbers, the statement with its status tag, the proof or a precise citation. Exercises with full solutions.
- After the last chapter: **one overhaul pass** (consistency, cross-references, notation clashes), then **freeze** with a git tag. Later changes are errata.

## Companion note: one headline result, explained completely

- **Plan card first** (`companion/PLAN.txt`, edited only by the coordinator): the theorem, its tier and conditions as recorded in the ledger, the inputs (proof document, ledger entries, lit notes, reports, the paper draft), the proof steps numbered exactly as in the proof document and the paper, the audience, the page budget per chapter and a floor of 80 % of it.
- **Three reading paths:** a fast path (the first section of every chapter, written so that these briefs read consecutively as one proof sketch), the full path, and a review path through the risky steps in the order a checker should take them.
- Chapter shape: where-we-are box (which step, where in the paper, what it needs) → brief → material → recap.
- It cites the lecture notes instead of re-deriving their content.
- **Two fresh referees** before the owner reads it: R1 mathematical (every step), R2 numbers and sources (every number traced to a data file or computation, every citation opened). Their findings are applied and listed.
- **Public edit** separately: remove internal scaffolding (agent names, script paths, ledger ids) into an internal-only appendix; the public text carries the AI-use and verification statements of charter §9.1.
