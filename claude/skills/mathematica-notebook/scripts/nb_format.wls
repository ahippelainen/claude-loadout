#!/usr/bin/env wolframscript
(* nb_format.wls -- deliver code cells as 2D-formatted Input cells (FractionBox, SuperscriptBox,
   SqrtBox, tight Dot); line layout is never changed. Every cell passes a semantic check or keeps
   its original content.

   Usage (via run_wolfram.sh, which turns --strict into NB_STRICT=1 because wolframscript drops
   dash-prefixed script arguments):
     nb_format.wls format  <in.nb>          <out.nb> [--strict]
     nb_format.wls from-wl <in.wl | in.m>   <out.nb> [--strict]

   --strict  accept only cells whose held expressions are identical (===); by default a difference
             that is purely Times associativity (from FractionBox) is accepted unless the cell uses
             Hold*/Unevaluated/Compile/... *)

args = If[Length[$ScriptCommandLine] >= 2,
  Rest[$ScriptCommandLine],
  Module[{cl = $CommandLine, pos},
    pos = FirstPosition[cl, "-script" | "-file", Missing["NotFound"]];
    If[! MissingQ[pos] && pos[[1]] + 1 <= Length[cl], Drop[cl, pos[[1]] + 1], {}]]];

scriptPath = If[StringQ[$InputFileName] && $InputFileName =!= "", $InputFileName, First[$ScriptCommandLine]];
Get[FileNameJoin[{DirectoryName[scriptPath], "nb_format.wl"}]];

usage[] := (
  WriteString["stderr",
    "Usage:\n" <>
    "  nb_format.wls format  <in.nb>        <out.nb> [--strict]\n" <>
    "  nb_format.wls from-wl <in.wl|in.m>   <out.nb> [--strict]\n"];
  Exit[1]);

If[Length[args] != 3, usage[]];
{cmd, in, out} = args;
NbFormat`$NbStrict = Environment["NB_STRICT"] === "1";
If[! FileExistsQ[in], WriteString["stderr", "Error: input not found: " <> in <> "\n"]; Exit[1]];

warnNoFE[] := WriteString["stderr",
  "[warn] front-end parser unavailable: code strings are left as unformatted raw cells\n"];

doFormat[] := Module[{nb, res, log},
  nb = Get[in];
  If[Head[nb] =!= Notebook, WriteString["stderr", "Error: not a Notebook expression: " <> in <> "\n"]; Exit[1]];
  (* Only raw-string code cells need the FE parser; existing boxes are formatted kernel-side. *)
  {res, log} = If[FreeQ[nb, Cell[BoxData[_String, ___], "Input" | "Code", ___]],
    NbFormat`NbFormatNotebook[nb],
    UsingFrontEnd[
      NbFormat`$NbFE = NbFormat`NbFEAvailableQ[];
      If[! NbFormat`$NbFE, warnNoFE[]];
      NbFormat`NbFormatNotebook[nb]]];
  Put[res, out];
  Print["Wrote " <> out];
  Print[NbFormat`NbSummary[log]]];

doFromWL[] := Module[{specs, cells, log = {}},
  specs = NbFormat`NbPackageToCells[Import[in, "Text", CharacterEncoding -> "UTF8"]];
  cells = UsingFrontEnd[
    NbFormat`$NbFE = NbFormat`NbFEAvailableQ[];
    If[! NbFormat`$NbFE, warnNoFE[]];
    Map[
      Function[s, If[s[[3]],
        With[{r = NbFormat`NbFormatCode[s[[2]]]}, AppendTo[log, r]; Cell[r["boxes"], "Input"]],
        Cell[s[[2]], s[[1]]]]],
      specs]];
  Put[Notebook[cells], out];
  Print["Wrote " <> ToString[Length[cells]] <> " cells to " <> out];
  Print[NbFormat`NbSummary[log]]];

Switch[cmd,
  "format", doFormat[],
  "from-wl", doFromWL[],
  _, usage[]];

Exit[0];
