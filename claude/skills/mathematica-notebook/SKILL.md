---
name: mathematica-notebook
description: Author and edit Wolfram Mathematica notebooks (.nb files). Generates new notebooks with Title/Section/Text/Input cells for derivations, symbolic math, physics or engineering computations, coursework, or research scaffolds; or extracts cells from an existing .nb, refactors code, and saves back. Use whenever the user asks to create, scaffold, build, write, or generate a Mathematica or Wolfram notebook, mentions a target .nb filename (e.g. "save as foo.nb"), wants Wolfram Language code or a worked derivation organized into a structured notebook, wants to modify, refactor, or rewrite an existing .nb — including replacing calls throughout it (e.g. Integrate to NIntegrate) or importing and reusing definitions from another .nb — or describes a multi-step Wolfram computation they plan to work through — even if they don't explicitly say "notebook". Skip for throwaway wolframscript one-liners, Mathematica install/environment issues, kernel error-message debugging, .nb exports or format conversions (except .wl/.m → .nb, which `from-wl` handles), or questions about unrelated tools (Jupyter, SymPy, SageMath, MATLAB). Requires a local Wolfram kernel (wolframscript, wolfram, or math).
---

# Mathematica Notebook Tooling

Build `.nb` files using Mathematica's own serialization so the resulting files open natively in the Wolfram frontend with proper cell styles, grouping, and section hierarchy.

## When to use

- The user wants a `.nb` notebook generated for a specific task (e.g. "make me a notebook that derives the Euler–Lagrange equations for a pendulum", "scaffold a notebook computing gamma-matrix traces").
- The user wants to extract, refactor, or regenerate code inside an existing `.nb`.
- Any workflow where notebook contents must be programmatically constructed from Wolfram code snippets plus narrative text.

Don't use this skill for a throwaway Wolfram one-liner — `wolframscript -code ...` is simpler there. This skill is about producing a notebook the user will later open, read, and extend.

## Principle

The user's goal is typically to receive a **well-structured, correct, unevaluated notebook** that they can open in the Wolfram frontend and evaluate themselves. Generated notebooks should feel like they were hand-written by a careful collaborator: clear headings, narrative text explaining each step, idiomatic Wolfram Language code, and enough structure that the user can drop in their own modifications. When **authoring a new** notebook, do **not** evaluate it, and do **not** include `Output` cells — the user runs it. (This is about authoring: when **editing an existing** notebook, `Output` cells and graphics that came out of `extract` round-trip faithfully and should be left intact, not stripped.)

## Architecture

Two bundled scripts:
- `scripts/nb_tool.wls` — the Wolfram Language script that does the notebook I/O (creates `Notebook[{Cell[...], ...}]` expressions and serializes them with `Put`; reads them back with `Get`).
- `scripts/run_wolfram.sh` — a bash wrapper that locates a Wolfram executable and invokes the script.

**Always invoke the wrapper**, not `nb_tool.wls` directly. The wrapper probes for `wolframscript` → `wolfram` → `math` (in that order), falls back to common macOS install paths, and picks the right invocation flag for each executable. The desktop `Mathematica` binary is a frontend only, not a kernel — the wrapper correctly ignores it.

## Cell specification (JSON)

Notebook content is a JSON object `{"cells": [...]}` where each cell is:
- `"type"` — cell style. Supported (in typical hierarchy order): `Title`, `Chapter`, `Section`, `Subsection`, `Subsubsection`, `Subsubsubsection`, `Text`, `Input`, `Code`, `Item`, `ItemNumbered`, `Program`, `Message`.
- `"content"` — the cell's text content (a string).
- `"raw"` — optional boolean. If `true`, `content` is parsed as a raw Wolfram expression (for advanced use: cells containing `BoxData`, `TextData`, formatted math). Default `false`.
- `"options"` — optional string: the cell's trailing Wolfram options as a comma-joined sequence, e.g. `"CellLabel -> \"Out[5]=\", FontColor -> RGBColor[1, 0, 0]"`. Produced by `extract` to preserve per-cell formatting; spliced back by `create`. Omit when there are none.
- `"image"` — optional string, **output only**. When `extract` finds a cell with rendered graphics it rasterizes it to a PNG sidecar (`<jsonbase>_img_<n>.png`, next to the JSON) and records the filename here so you can view the result with the Read tool. `create` ignores this field — the graphic itself round-trips via `content`.

The top-level object may also carry `"notebookOptions"` — a string of `Notebook[…]`-level options (e.g. `"StyleDefinitions -> \"Default.nb\""`) that `extract` captures and `create` re-applies, so the stylesheet and window state survive a round trip.

Keep the cell list **flat** — the frontend auto-groups cells based on heading hierarchy when opened. Don't try to nest.

### Example creation input

```json
{
  "cells": [
    {"type": "Title", "content": "Euler–Lagrange Equations for a Simple Pendulum"},
    {"type": "Section", "content": "Setup"},
    {"type": "Text", "content": "Generalized coordinate: theta(t). Lagrangian L = T - V for a point mass m on a massless rod of length l in uniform gravity g."},
    {"type": "Input", "content": "L = (1/2) m l^2 theta'[t]^2 - m g l (1 - Cos[theta[t]])"},
    {"type": "Section", "content": "Derivation"},
    {"type": "Text", "content": "The Euler-Lagrange equation is d/dt (dL/dq') - dL/dq = 0."},
    {"type": "Input", "content": "eqn = D[D[L, theta'[t]], t] - D[L, theta[t]] == 0"},
    {"type": "Input", "content": "Simplify[eqn]"},
    {"type": "Section", "content": "Small-angle limit"},
    {"type": "Input", "content": "Series[Sin[theta[t]], {theta[t], 0, 1}] // Normal"}
  ]
}
```

## Creating a notebook

1. Plan the notebook structure: Title → Sections → Text + Input cells. Aim for 1–2 lines of narrative text before each block of input cells, so a reader understands the intent.
2. Write the cells to a temporary JSON file using the `Write` tool.
3. Invoke the wrapper with absolute paths:
   ```
   scripts/run_wolfram.sh create /abs/path/cells.json /abs/path/output.nb
   ```
4. Verify `output.nb` exists and read the formatting summary it prints (see below). It will open in the Wolfram frontend unevaluated — the user runs it themselves.

## 2D formatting of code cells

`create` delivers `Input`/`Code` cells as parsed 2D boxes, not raw strings: `a/b` → built-up fraction (`FractionBox`), `x^n` → superscript, `Sqrt[x]` → radical, `X . Y` → `X.Y`. Line breaks are kept exactly as written; subscripts and other forms are untouched. An operator with a comment or line break next to it stays linear, and a dot next to a number keeps its spaces (`2 . v` tightened would read as `2.` times `v`). Cells with nothing to rewrite keep their original string.

Every cell is verified before it is written: the new boxes must read (held `ToExpression`) as the same expressions as the original boxes and the source string, statement by statement, with comments unchanged. A failing cell keeps its original content and is listed in the summary. One difference is accepted by default: a fraction with a product numerator reads as a flat `Times` (`(a b)/c` → `Times[a,b,c^-1]`, not `Times[Times[a,b],c^-1]`), which evaluates identically; cells using `Hold*`, `Unevaluated`, `Defer`, `Compile`, `Inactivate`, ... must match exactly. `--strict` demands exact matches everywhere.

```
scripts/run_wolfram.sh create  cells.json out.nb [--no-format] [--strict]
scripts/run_wolfram.sh format  in.nb      out.nb [--strict]   # existing notebook: only Input/Code cell contents change
scripts/run_wolfram.sh from-wl in.wl|in.m out.nb [--strict]   # (* ::Section:: *)-style markers → cells, code → formatted Input cells
```

Parsing code strings needs the Wolfram front end, which the scripts launch headless (no display needed). If it cannot start, string code cells are written unformatted with a warning. When editing via `extract` → `create`, string code cells that contain something to rewrite get reformatted; pass `--no-format` if they must stay byte-identical.

## Extracting and modifying a notebook

1. Extract cells to JSON:
   ```
   scripts/run_wolfram.sh extract /abs/path/input.nb /abs/path/cells.json
   ```
2. Read `cells.json`. Plain-string cells come back as `{"type": ..., "content": "..."}`. Complex cells (typeset math boxes, output cells with graphics, etc.) come back with `"raw": true` and `content` as a Wolfram expression string. Leave `raw: true` cells alone unless you need to modify them — rewriting typeset content is error-prone.
3. Extraction is **faithful**: per-cell formatting (`options`), notebook-level styling (`notebookOptions`), and any evaluated `Output` cells — including graphics — are all captured and round-trip exactly. Don't drop `Output` cells or `options`/`notebookOptions` when editing unless the user wants them gone; preserving them is what keeps the user's evaluated notebook intact.
4. To **see** a plot or image, open the PNG named in that cell's `"image"` field with the Read tool — the raw `GraphicsBox` in `content` is not human-readable, but the sidecar PNG renders it.
5. Modify the cells array as needed (edit strings, insert/delete cells, reorder).
6. Write back with `create`, pointing at the modified JSON.

The round trip `extract → create` reproduces the notebook expression exactly when cells are left verbatim; it is lossy for complex cells only if you hand-edit their raw Wolfram expressions or `options` strings incorrectly.

## Writing idiomatic Input cells

- One evaluation unit per cell. Multiple statements inside a single cell is fine (separated by `;` or newline), but don't split one logical computation across multiple cells unless you want the user to evaluate them separately.
- **No superfluous whitespace around operators or inside brackets.** Mathematica's frontend writes code tightly, so spaced-out code looks wrong when the notebook opens. Write `thing//.repl` not `thing //. repl`, and `myFunction[thing,{a,b,c[d,e]}]` not `myFunction[thing, {a, b, c[d, e]}]`. This applies to commas in argument lists/lists, and to operators like `//.`, `/.`, `->`, `:>`, `@`, `/@`, `//`.
- **Line-break long objects logically.** Don't paste a big `Association`, list, rule set, or nested-call argument onto one runaway line — put each entry on its own line so the structure reads at a glance. The opening bracket/brace stays on the first line, each element goes on its own line, and the closing bracket/brace on a final line. **Do not add manual indentation** — leading spaces in `content` are displayed literally; the frontend auto-indents only line breaks stored as `\[IndentingNewLine]` (what typing produces), not the plain newlines of generated code. Just the newlines, flush left:
  ```
  params=<|
  "mass"->1,
  "length"->2,
  "gravity"->9.81,
  "damping"->0.1
  |>;
  ```
  rather than `params=<|"mass"->1,"length"->2,"gravity"->9.81,"damping"->0.1|>;`. The same applies to long `{...}` lists, multi-rule `/.` replacements, and option-heavy calls like `Plot[...]` or `NDSolve[...]` — break each option onto its own line. Combine this with the no-extra-whitespace rule: tight tokens, a newline per logical element, and no hand-added indentation.
- Prefer pattern-based definitions (`f[x_] := x^2`) over immediate assignment (`f[x] = x^2`) for functions, because patterns avoid premature evaluation.
- Use `Module[{...}, ...]` or `Block[{...}, ...]` for local scoping.
- Comments go inside code cells as `(* ... *)`. Don't abuse `Text` cells as inline code comments — keep `Text` cells for narrative that describes what's happening.
- Use ASCII names in code (`Alpha`, `Pi`, `Infinity`). Avoid raw Unicode characters — they can confuse parsers. If you need the pretty symbols, use Wolfram named-character escapes: `\[Alpha]`, `\[Pi]`, `\[Infinity]`.
- Do not emit `Output` cells. Do not pre-evaluate.
- For differential equations, prefer `NDSolve` (numeric) or `DSolve` (symbolic) — the user will pick. For root-finding inside a solution, `FindRoot` or `WhenEvent` inside `NDSolve` are both idiomatic.

## Inline math in Text cells (advanced — use sparingly)

Plain `Text` cells accept plain strings. For typeset inline math (e.g., rendering α² rather than writing "alpha^2"), use a raw cell with `TextData`:

```json
{
  "type": "Text",
  "raw": true,
  "content": "TextData[{\"The conserved quantity is \", Cell[BoxData[FormBox[SuperscriptBox[\"\\\\[Alpha]\", \"2\"], TraditionalForm]]], \".\"}]"
}
```

This is fiddly and error-prone. Default to plain strings that describe the math in words or ASCII ("the conserved quantity is alpha^2"). Only reach for typeset math when the user has specifically asked for it or when the formula would be unreadable otherwise.

## If the wrapper can't be executed

Some environments (sandboxed subagents, unusual permission setups, machines with no Wolfram install) may block `run_wolfram.sh` from running. If that happens after a reasonable attempt, don't give up silently — the user still needs a useful artifact:

1. **Always produce `cells.json`.** That's the structured intermediate the user can feed through the wrapper themselves in one command.
2. **Best-effort fallback: write the `.nb` directly.** The `.nb` format is simply a Wolfram `Notebook[{...}]` expression serialized as plain text by `Put`. Mirror that format — one `Notebook[]` wrapping a flat list of `Cell[]` expressions — so the user can still open the file in the frontend even if the wrapper never ran. Template:

   ```wolfram
   Notebook[{
     Cell["My title", "Title"],
     Cell["A section", "Section"],
     Cell["Narrative text goes here.", "Text"],
     Cell[BoxData["f[x_] := x^2"], "Input"],
     Cell[BoxData["Integrate[f[x], {x, 0, 1}]"], "Input"]
   }]
   ```

   Write the expression verbatim (UTF-8 text) to the target `.nb` path. Follow the same style conventions the wrapper uses:
   - `Input`, `Code`, `Program` cell bodies → wrap in `BoxData["..."]` so the frontend renders them as formatted code.
   - All other cells (`Title`, `Section`, `Text`, `Item`, ...) → plain string bodies.
   - Escape `"` as `\"` and backslashes as `\\` inside the strings, as usual in Wolfram expressions.
   - Keep cells flat — don't add `CellGroupData` wrappers; the frontend groups on open.
3. **Tell the user.** Say clearly that the wrapper was blocked, point at both the `cells.json` and the fallback `.nb`, and suggest re-running the wrapper once bash access is granted (`run_wolfram.sh create cells.json out.nb`) for a canonical serialization.

The fallback is for genuine blockers, not the first sign of friction — try the wrapper once or twice and diagnose before falling back.

## Common pitfalls

- **String escaping.** Wolfram uses backslash escapes: `\"` inside a string is a literal quote. Inside JSON that becomes `\\\"`. For a literal backslash in Wolfram code inside JSON: `\\\\`. If a cell's `content` looks off after round-tripping, escaping is almost always the culprit.
- **The frontend is not a kernel.** The standalone `Mathematica.app` / `Mathematica.exe` is a frontend; it doesn't run scripts. The user needs either Wolfram Engine (free) or Wolfram Desktop with `wolframscript` enabled. If the wrapper can't find a kernel, surface this clearly rather than retrying.
- **Relative paths.** Pass **absolute** paths to `run_wolfram.sh`. The Wolfram kernel's working directory can differ from yours.
- **Don't hand-write `.nb` files.** The format is a strict nested Wolfram expression. Always go through the script.
- **Heading hierarchy.** Cells auto-group by style; the frontend treats `Title > Chapter > Section > Subsection > Subsubsection` as increasing depth. Don't skip levels arbitrarily (e.g., `Title` directly to `Subsection`) — it looks wrong when opened.
- **Invisible on open (`Visible -> False`).** A `.nb` saved through a headless frontend session (`UsingFrontEnd`, `NotebookOpen` + `NotebookSave`, e.g. converting a `.m` to `.nb`) gets the live window options baked into the file: `Visible -> False`, `WindowMargins`, `FrontEndVersion`, and — when the source was a `.m` — `StyleDefinitions -> "Package.nb"`. The file parses fine, but the desktop frontend applies the saved options on open, so the window is invisible and the notebook "appears broken". Diagnose with `Get[f]` and inspect `Rest[List @@ nb]`. Fix with the kernel: `nb=Get[f]; Put[Notebook[First[nb], Sequence@@Append[DeleteCases[Rest[List@@nb], (Visible->_)|(StyleDefinitions->_)|(ExpressionUUID->_)|(WindowMargins->_)|(FrontEndVersion->_)], StyleDefinitions->"Default.nb"]], f]` — cells round-trip untouched. The `create` path here (plain `Put`) never writes window options, so prefer it over headless-frontend saves.

## Quick reference

| Goal | Command |
|---|---|
| Create a new notebook | `scripts/run_wolfram.sh create cells.json out.nb` |
| Extract cells from existing | `scripts/run_wolfram.sh extract in.nb cells.json` |
| Modify and re-save | `extract` → edit JSON → `create` to the same `.nb` |
| 2D-format an existing notebook | `scripts/run_wolfram.sh format in.nb out.nb` |
| Package → notebook | `scripts/run_wolfram.sh from-wl in.wl out.nb` |
