(* nb_tool.wls — create and extract Mathematica notebooks via the Wolfram kernel.

   Usage (invoked via run_wolfram.sh, which dispatches to whichever kernel is available):
     nb_tool.wls create  <cells.json> <output.nb> [--no-format] [--strict]
     nb_tool.wls extract <input.nb>   <cells.json>

   create formats Input/Code cells with nb_format.wl (FractionBox, SuperscriptBox, SqrtBox,
   tight Dot; line layout untouched); --no-format writes the code as raw strings instead.
   Flags reach this script as NB_NO_FORMAT=1 / NB_STRICT=1 (run_wolfram.sh translates them).

   Cell JSON format: {"cells": [{"type": "Section", "content": "...", "raw": false}, ...]}
   - "type"    — cell style (Title, Section, Text, Input, ...)
   - "content" — cell content (plain string, OR a Wolfram expression string if raw=true)
   - "raw"     — optional bool; if true, content is parsed with ToExpression
*)

(* Argument handling: wolframscript -file populates $ScriptCommandLine,
   but `wolfram -script` leaves it empty and puts args in $CommandLine.
   Try $ScriptCommandLine first, then fall back to parsing $CommandLine. *)
args = If[Length[$ScriptCommandLine] >= 2,
  Rest[$ScriptCommandLine],
  Module[{cl = $CommandLine, pos},
    pos = FirstPosition[cl, "-script" | "-file", Missing["NotFound"]];
    If[! MissingQ[pos] && pos[[1]] + 1 <= Length[cl],
      Drop[cl, pos[[1]] + 1],
      {}
    ]
  ]
];

scriptPath = If[StringQ[$InputFileName] && $InputFileName =!= "", $InputFileName, First[$ScriptCommandLine]];

usage[] := (
  WriteString["stderr",
    "Usage:\n" <>
    "  nb_tool.wls create  <cells.json> <output.nb> [--no-format] [--strict]\n" <>
    "  nb_tool.wls extract <input.nb>   <cells.json>\n"
  ];
  Exit[1]
);

If[Length[args] < 1, usage[]];

subcommand = args[[1]];

$validStyles = {
  "Title", "Chapter", "Section", "Subsection", "Subsubsection", "Subsubsubsection",
  "Text", "Input", "Output", "Code", "Item", "ItemNumbered", "Program", "Message",
  "Caption", "PageBreak"
};

(* ==== shared helpers ==== *)

(* Serialize a Wolfram expression to a single-line InputForm string.
   PageWidth -> Infinity prevents line-wrapping from injecting newlines that
   would otherwise survive into the JSON and clutter (or, for some heads,
   break) the round trip. *)
exprToString[expr_] := ToString[expr, InputForm, PageWidth -> Infinity];

(* Serialize a sequence of cell/notebook options to a comma-joined Wolfram
   sequence string, e.g. "CellLabel -> \"Out[5]=\", ImageSize -> 300".
   Returns "" when there are none. *)
optsToString[opts_List] := StringRiffle[exprToString /@ opts, ", "];

(* Parse an "options"/"notebookOptions" string back into a list of options.
   Returns {} on empty/missing/unparseable input (with a warning). *)
parseOpts[s_] := Module[{str, parsed},
  str = If[StringQ[s], StringTrim[s], ""];
  If[str === "", Return[{}]];
  parsed = Quiet @ ToExpression["{" <> str <> "}", InputForm, HoldComplete];
  If[Head[parsed] === HoldComplete && MatchQ[parsed, HoldComplete[_List]],
    List @@ ReleaseHold[parsed]
    ,
    WriteString["stderr", "[warn] failed to parse options, dropping: " <> str <> "\n"];
    {}
  ]
];

(* ==== create ==== *)

(* Code-bearing styles: content should be wrapped in BoxData[...] so the
   frontend renders it as formatted code rather than a literal string. *)
$codeStyles = {"Input", "Code", "Program"};

cellFromSpec[spec_] := Module[{type, content, raw, parsed, body, opts},
  type    = Lookup[spec, "type", "Text"];
  content = Lookup[spec, "content", ""];
  raw     = TrueQ @ Lookup[spec, "raw", False];
  opts    = parseOpts @ Lookup[spec, "options", ""];

  If[!MemberQ[$validStyles, type],
    WriteString["stderr", "[warn] unknown cell type '" <> ToString[type] <> "', falling back to Text\n"];
    type = "Text";
  ];

  body = If[raw,
    parsed = Quiet @ ToExpression[content, InputForm, HoldComplete];
    If[Head[parsed] === HoldComplete && Length[parsed] == 1 && parsed =!= HoldComplete[Null],
      ReleaseHold[parsed]
      ,
      WriteString["stderr", "[warn] failed to parse raw content, using as string\n"];
      ToString[content]
    ]
    ,
    ToString[content]
  ];

  (* For code-bearing cells, wrap plain-string bodies in BoxData so the
     frontend renders them as formatted code. Raw bodies that are already
     box expressions (BoxData[...], RowBox[...], etc.) are passed through.
     Trailing options captured on extract are spliced back in to preserve
     per-cell formatting (CellLabel, FontColor, ImageSize, ...). *)
  If[MemberQ[$codeStyles, type] && StringQ[body],
    Cell[codeBoxes[type, body], type, Sequence @@ opts]
    ,
    Cell[body, type, Sequence @@ opts]
  ]
];

buildNotebook[specs_List, nbOpts_List] := Notebook[cellFromSpec /@ specs, Sequence @@ nbOpts];

(* Program cells are listings, not evaluated, so only Input/Code get 2D formatting. *)
$formatOn = False;
$fmtLog = {};
codeBoxes[type_, s_String] := If[$formatOn && MemberQ[{"Input", "Code"}, type],
  With[{r = NbFormat`NbFormatCode[s]}, AppendTo[$fmtLog, r]; r["boxes"]],
  BoxData[s]];

doCreate[jsonPath_, nbPath_] := Module[{data, specs, nbOpts, nb},
  If[!FileExistsQ[jsonPath],
    WriteString["stderr", "Error: input JSON not found: " <> jsonPath <> "\n"];
    Exit[1];
  ];
  data = Import[jsonPath, "RawJSON"];
  specs = Which[
    AssociationQ[data] && KeyExistsQ[data, "cells"], data["cells"],
    ListQ[data], data,
    True, (WriteString["stderr", "Error: JSON must be a list of cells or {\"cells\": [...]}\n"]; Exit[1])
  ];
  If[!ListQ[specs],
    WriteString["stderr", "Error: 'cells' must be a list\n"];
    Exit[1];
  ];
  (* Notebook-level options (StyleDefinitions, WindowSize, ...) captured on
     extract are re-applied so the stylesheet and window state round-trip. *)
  nbOpts = If[AssociationQ[data], parseOpts @ Lookup[data, "notebookOptions", ""], {}];
  $formatOn = Environment["NB_NO_FORMAT"] =!= "1" &&
    AnyTrue[specs, MemberQ[{"Input", "Code"}, Lookup[#, "type", "Text"]] && ! TrueQ[Lookup[#, "raw", False]] &];
  nb = If[$formatOn,
    Get[FileNameJoin[{DirectoryName[scriptPath], "nb_format.wl"}]];
    NbFormat`$NbStrict = Environment["NB_STRICT"] === "1";
    UsingFrontEnd[
      NbFormat`$NbFE = NbFormat`NbFEAvailableQ[];
      If[! NbFormat`$NbFE,
        WriteString["stderr", "[warn] front-end parser unavailable: code cells written as unformatted raw strings\n"]];
      buildNotebook[specs, nbOpts]],
    buildNotebook[specs, nbOpts]];
  Put[nb, nbPath];
  WriteString["stdout", "Wrote " <> ToString[Length[specs]] <> " cells to " <> nbPath <> "\n"];
  If[$formatOn, WriteString["stdout", NbFormat`NbSummary[$fmtLog] <> "\n"]];
];

(* ==== extract ==== *)

(* Attach a serialized "options" field to a spec, but only when the cell
   actually carried trailing options — keeps the JSON clean for simple cells. *)
withOpts[spec_, {}] := spec;
withOpts[spec_, opts_List] := Append[spec, "options" -> optsToString[opts]];

(* Unwrap the common BoxData-wrapped-string case that `create` produces for
   code cells, so `extract` round-trips cleanly back to plain content. Trailing
   options (CellLabel, FontColor, ImageSize, ...) are captured, not discarded. *)
cellToSpec[Cell[BoxData[s_String], style_String, opts___]] :=
  withOpts[<|"type" -> style, "content" -> s|>, {opts}];
cellToSpec[Cell[content_, style_String, opts___]] := withOpts[
  If[StringQ[content],
    <|"type" -> style, "content" -> content|>,
    <|"type" -> style, "raw" -> True, "content" -> exprToString[content]|>
  ],
  {opts}
];
cellToSpec[other_] := <|"type" -> "Text", "raw" -> True, "content" -> exprToString[other]|>;

(* Collect content cells in document order, descending ONLY through
   CellGroupData grouping wrappers — never into a content cell's own body, so
   inline cells nested inside Text/title cells are not double-extracted. *)
collectCells[Cell[CellGroupData[cs_List, ___], ___]] := Join @@ (collectCells /@ cs);
collectCells[c : Cell[__]] := {c};
collectCells[_] := {};

(* True when a cell's content contains rendered graphics. *)
graphicsQ[boxes_] := ! FreeQ[boxes, GraphicsBox | Graphics3DBox | RasterBox];

(* Strip the BoxData wrapper to get the raw boxes ToExpression can interpret. *)
renderBoxes[BoxData[b_, ___]] := b;
renderBoxes[other_] := other;

(* Rasterize a graphics-bearing cell to a PNG sidecar next to the JSON, and
   return the bare filename for the spec's "image" field. The raw box stays in
   "content" regardless, so a rasterization failure is non-fatal. *)
exportImage[boxes_, jsonPath_, n_] := Module[{gfx, dir, base, png},
  gfx = Quiet @ ToExpression @ renderBoxes[boxes];
  If[Head[gfx] === ToExpression || gfx === $Failed,
    WriteString["stderr", "[warn] could not interpret graphics in cell " <> ToString[n] <> "; box preserved\n"];
    Return[Missing[]]
  ];
  dir  = DirectoryName @ ExpandFileName[jsonPath];
  base = FileBaseName[jsonPath];
  png  = FileNameJoin[{dir, base <> "_img_" <> ToString[n] <> ".png"}];
  If[Quiet[Export[png, gfx, "PNG"]] === $Failed,
    WriteString["stderr", "[warn] could not export graphics in cell " <> ToString[n] <> "; box preserved\n"];
    Missing[]
    ,
    FileNameTake[png]
  ]
];

doExtract[nbPath_, jsonPath_] := Module[{nb, nbOpts, cells, specs},
  If[!FileExistsQ[nbPath],
    WriteString["stderr", "Error: input notebook not found: " <> nbPath <> "\n"];
    Exit[1];
  ];
  nb = Get[nbPath];
  If[Head[nb] =!= Notebook,
    WriteString["stderr", "Error: file is not a Wolfram Notebook expression\n"];
    Exit[1];
  ];
  (* Notebook-level options (stylesheet, window state, ...) follow the cell list. *)
  nbOpts = Rest[List @@ nb];
  cells = Join @@ (collectCells /@ First[nb]);
  specs = MapIndexed[
    Function[{cell, idx},
      Module[{spec = cellToSpec[cell], img},
        If[graphicsQ[cell[[1]]],
          img = exportImage[cell[[1]], jsonPath, First[idx]];
          If[!MissingQ[img], spec = Append[spec, "image" -> img]];
        ];
        spec
      ]
    ],
    cells
  ];
  Export[
    jsonPath,
    If[nbOpts === {},
      <|"cells" -> specs|>,
      <|"cells" -> specs, "notebookOptions" -> optsToString[nbOpts]|>
    ],
    "RawJSON", "Compact" -> False
  ];
  WriteString["stdout", "Extracted " <> ToString[Length[specs]] <> " cells from " <> nbPath <> "\n"];
];

(* ==== dispatch ==== *)

Which[
  subcommand === "create",
    If[Length[args] < 3, usage[]];
    doCreate[args[[2]], args[[3]]],
  subcommand === "extract",
    If[Length[args] < 3, usage[]];
    doExtract[args[[2]], args[[3]]],
  True,
    WriteString["stderr", "Unknown subcommand: " <> ToString[subcommand] <> "\n"];
    usage[];
];

Exit[0];
