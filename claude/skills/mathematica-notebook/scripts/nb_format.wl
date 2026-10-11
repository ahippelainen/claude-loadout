(* nb_format.wl -- 2D formatting of Wolfram Input/Code cells, shared by nb_format.wls and nb_tool.wls.

   Rewrites, with line layout left exactly as it is:
     a/b -> FractionBox (one redundant outer paren pair stripped per side), x^n -> SuperscriptBox,
     Sqrt[x] -> SqrtBox, "a . b" -> "a.b".
   Every cell is verified before it is emitted; a cell that fails keeps its original content.
   Parsing a code *string* needs the front end (call inside UsingFrontEnd); formatting existing
   boxes is kernel-only. *)

BeginPackage["NbFormat`"];

NbFEAvailableQ::usage = "NbFEAvailableQ[] is True when the front-end parser answers (call inside UsingFrontEnd).";
NbFormatCode::usage = "NbFormatCode[code] parses a code string with the FE parser, formats and verifies it; returns a result association.";
NbFormatBoxes::usage = "NbFormatBoxes[boxData] formats and verifies existing cell boxes; returns a result association.";
NbFormatNotebook::usage = "NbFormatNotebook[nb] returns {nb', log} with Input/Code cells formatted.";
NbPackageToCells::usage = "NbPackageToCells[text] splits .wl/.m text into {style, content, codeQ} triples.";
NbSummary::usage = "NbSummary[log] renders a per-file report.";
$NbStrict::usage = "If True, accept only cells whose held expressions are identical (===).";
$NbFE::usage = "Set to the result of NbFEAvailableQ[]; False makes string cells fall back unformatted.";

Begin["`Private`"];

$NbStrict = False;
$NbFE = False;
$sandbox = "NbFmtSandbox`";
$inl = "\[IndentingNewLine]";

(* ==== box predicates ==== *)

hwsQ[s_String] := s =!= "" && StringMatchQ[s, (" " | "\t") ..];
hwsQ[_] := False;
wsQ[s_String] := StringMatchQ[s, (" " | "\t" | "\n" | $inl) ...];
wsQ[_] := False;
commentQ[RowBox[{"(*", ___}]] := True;
(* Styling part of a comment in the FE can split the comment-opening token itself into StyleBoxes. *)
commentQ[r : RowBox[{first : Except[_String], ___}]] :=
  MemberQ[{"(", "(*"}, firstLeaf[first]] && leafText[first] === "(*" && singleCommentQ[leafText[r]];
commentQ[StyleBox[b_, ___]] := commentQ[b];
commentQ[_] := False;
firstLeaf[s_String] := s;
firstLeaf[RowBox[{x_, ___}]] := firstLeaf[x];
firstLeaf[StyleBox[b_, ___]] := firstLeaf[b];
firstLeaf[_] := None;
leafText[s_String] := s;
leafText[RowBox[l_List]] := StringJoin[leafText /@ l];
leafText[StyleBox[b_, ___]] := leafText[b];
leafText[_] := "\[Placeholder]";
(* True if t is exactly one (possibly nested) comment. *)
singleCommentQ[t_String] := StringStartsQ[t, "(*"] && StringEndsQ[t, "*)"] &&
  Module[{d = 0, end = 0},
    Do[If[d >= 0, d += If[StringTake[t, p] === "(*", 1, -1]; If[d == 0 && end == 0, end = p[[2]]]],
      {p, StringPosition[t, "(*" | "*)", Overlaps -> False]}];
    end == StringLength[t]];
(* 2D boxes spanning a line break render badly, so operands must be single-line. *)
nlFreeQ[b_] := FreeQ[b, s_String /; StringContainsQ[s, "\n" | $inl]];
operandQ[b_] := ! wsQ[b] && ! commentQ[b] && nlFreeQ[b];

(* ==== 2D rewrites (bottom-up, never inside comments) ==== *)

tr[s_String] := s;
tr[r : RowBox[l_List]] := If[commentQ[r], r, row[tr /@ l]];
tr[FractionBox[a_, b_, o___]] := FractionBox[tr[a], tr[b], o];
tr[SuperscriptBox[a_, b_, o___]] := SuperscriptBox[tr[a], tr[b], o];
tr[SqrtBox[a_, o___]] := SqrtBox[tr[a], o];
tr[l_List] := tr /@ l;
tr[BoxData[b_, o___]] := BoxData[tr[b], o];
tr[other_] := other;

row[l_List] := Module[{m = tightDots[l], c},
  Which[
    (c = chain[m, "/"]) =!= None, fraction[c],
    (c = chain[m, "^"]) =!= None, power[c],
    (c = sqrtArg[m]) =!= None, SqrtBox[c],
    True, RowBox[unparen[m]]]];

(* (a/b) -> 2D fraction without the now-redundant parens, except where the parens carry
   meaning on screen: a power base, a head, a derivative or factorial operand. *)
fracParenQ[RowBox[{"(", mid__, ")"}]] := MatchQ[DeleteCases[{mid}, _?hwsQ], {_FractionBox}];
fracParenQ[_] := False;
unparen[m_List] := MapIndexed[
  If[fracParenQ[#1] && ! MemberQ[{"^", "[", "'", "!"}, SelectFirst[Drop[m, First[#2]], ! hwsQ[#] &, None]],
    strip1[#1], #1] &, m];

dropWSAround[l_, op_] := With[{n = Length[l]},
  Pick[l, Table[! (hwsQ[l[[i]]] && ((i > 1 && l[[i - 1]] === op) || (i < n && l[[i + 1]] === op))), {i, n}]]];

(* Operands of an n-ary chain x1 op x2 op ... ; None if the row is anything else
   (comments or line breaks next to the operator keep it linear). *)
chain[l_, op_] := With[{m = dropWSAround[l, op]},
  If[OddQ[Length[m]] && Length[m] >= 3 && AllTrue[m[[2 ;; ;; 2]], # === op &] && AllTrue[m[[1 ;; ;; 2]], operandQ],
    m[[1 ;; ;; 2]], None]];

strip1[r : RowBox[{"(", mid__, ")"}]] := With[{x = DeleteCases[{mid}, _?hwsQ]},
  If[Length[x] == 1 && ! commentQ[First[x]], First[x], r]];
strip1[b_] := b;
(* An exponent left as (n) would read as the n-th derivative, so strip every layer. *)
stripAll[b_] := FixedPoint[strip1, b];

(* a/b/c is left-associative: ((a/b)/c). *)
fraction[ops_] := Fold[FractionBox[#1, strip1[#2]] &, strip1[First[ops]], Rest[ops]];
(* a^b^c is right-associative: a^(b^c). The base keeps its parentheses. *)
power[ops_] := Fold[SuperscriptBox[#2, stripAll[#1]] &, Last[ops], Reverse[Most[ops]]];

sqrtArg[l_] := With[{m = DeleteCases[l, _?hwsQ]},
  If[MatchQ[m, {"Sqrt", "[", x_, "]"} /; operandQ[x] && ! MatchQ[x, RowBox[{___, ",", ___}]]], m[[3]], None]];

(* Removing the spaces must not merge tokens: "2 . v" -> "2.v" is a number, "x_ . y" -> "x_." is Optional. *)
tightDots[l_List] := If[FreeQ[l, ".", {1}], l,
  Module[{n = Length[l], drop = ConstantArray[False, Length[l]], lw, rw},
    Do[
      If[l[[j]] === ".",
        lw = j > 1 && hwsQ[l[[j - 1]]];
        rw = j < n && hwsQ[l[[j + 1]]];
        If[(lw || rw) && (! lw || (j > 2 && safeLeft[l[[j - 2]]])) && (! rw || (j < n - 1 && safeRight[l[[j + 2]]])),
          If[lw, drop[[j - 1]] = True];
          If[rw, drop[[j + 1]] = True]]],
      {j, n}];
    Pick[l, drop, False]]];

lastTok[s_String] := s;
lastTok[RowBox[l_List]] := With[{x = DeleteCases[l, _?wsQ]}, If[x === {}, Missing[], lastTok[Last[x]]]];
lastTok[FractionBox[_, d_, ___]] := lastTok[d];
lastTok[SuperscriptBox[_, e_, ___]] := lastTok[e];
lastTok[SqrtBox[__]] := "]";
lastTok[StyleBox[b_, ___]] := lastTok[b];
lastTok[_] := Missing[];
firstTok[s_String] := s;
firstTok[RowBox[l_List]] := With[{x = DeleteCases[l, _?wsQ]}, If[x === {}, Missing[], firstTok[First[x]]]];
firstTok[FractionBox[n_, __]] := firstTok[n];
firstTok[SuperscriptBox[b_, __]] := firstTok[b];
firstTok[SqrtBox[__]] := "Sqrt";
firstTok[StyleBox[b_, ___]] := firstTok[b];
firstTok[_] := Missing[];
(* Judged per token, not per character: symbol DM1 is safe before ".", number 1 is not. *)
safeLeft[b_] := With[{t = lastTok[b]}, StringQ[t] && t =!= "" &&
  ! (DigitQ[StringTake[t, 1]] || StringStartsQ[t, "#" | "%" | "."]) && ! MemberQ[{".", "_", "`"}, StringTake[t, -1]]];
safeRight[b_] := With[{t = firstTok[b]}, StringQ[t] && t =!= "" && ! DigitQ[StringTake[t, 1]] && ! MemberQ[{".", "`"}, StringTake[t, 1]]];

(* ==== semantics ==== *)

(* User symbols are created in a sandbox context so they can never alias this package. *)
interp[b_] := Block[{$Context = $sandbox, $ContextPath = {"System`"}},
  Quiet[Check[ToExpression[b, StandardForm, HoldComplete], $Failed]]];
parseText[t_String] := Block[{$Context = $sandbox, $ContextPath = {"System`"}},
  Quiet[Check[ToExpression[t, InputForm, HoldComplete], $Failed]]];
(* Blank lines and top-level comments parse to Null. *)
dropNull[h_HoldComplete] := DeleteCases[h, Null];
dropNull[_] := $Failed;

(* The kernel's box reader turns a top-level "\n" inside one RowBox into Times, whereas the FE
   evaluates each line as its own statement (checked by evaluating such a cell in the FE), as
   does the kernel's string parser. So cell-level meaning = string parse of the concatenated
   box text, with every non-RowBox box (2D forms, StyleBox, ...) substituted in via the box reader. *)
serialize[bd_] := Module[{n = 0, phs = <||>, f},
  f[s_String] := StringReplace[s, $inl -> "\n"];
  f[r : RowBox[l_List]] := If[commentQ[r], "(*c*)", StringJoin[f /@ l]];
  f[l_List] := StringJoin[f /@ l];
  f[BoxData[b_, ___]] := f[b];
  f[b_] := If[commentQ[b], "(*c*)", With[{k = "zzNbFmtPh" <> ToString[++n] <> "zz"}, phs[k] = b; "(" <> k <> ")"]];
  {f[bd], phs}];

phRule[k_, b_] := With[{h = interp[b], sym = Symbol[$sandbox <> k]},
  If[MatchQ[h, HoldComplete[_]], Replace[h, HoldComplete[e_] :> (sym :> e)], $Failed]];

oracle[bd_] := Module[{t, phs, h, rules},
  {t, phs} = serialize[bd];
  h = dropNull[parseText[t]];
  If[h === $Failed, Return[$Failed]];
  rules = KeyValueMap[phRule, phs];
  If[MemberQ[rules, $Failed], $Failed, h /. rules]];

literal[bd_] := dropNull[interp[bd]];

SetAttributes[inert, HoldAllComplete];
$holdSyms = Hold | HoldForm | HoldComplete | HoldPattern | Unevaluated | Defer | Inactivate | Inactive |
  Compile | FunctionCompile | Trace | TraceScan | Verbatim | HoldAll | HoldAllComplete | HoldFirst |
  HoldRest | MakeBoxes | MakeExpression;
holdSensitiveQ[h_] := ! FreeQ[Replace[h, HoldComplete[x___] :> inert[x]], $holdSyms];
(* The box reader builds FractionBox[num, den] as a flat Times, so (a b)/c reads as
   Times[a, b, c^-1] where the linear form reads Times[Times[a, b], c^-1]. Times is Flat, so the
   two evaluate identically; they differ only where code inspects held structure, hence the guard.
   Times is renamed to an attribute-free head first: a rule written with Times itself would be
   flattened at construction and silently never fire. *)
flatTimes[h_] := (h /. Times -> timesI) //. timesI[x___, timesI[y___], z___] :> timesI[x, y, z];

(* 1: identical held expressions; 2: identical up to Times associativity; 0: not verified. *)
tier[a_, b_] := Which[
  a === $Failed || b === $Failed, 0,
  a === b, 1,
  TrueQ[$NbStrict] || holdSensitiveQ[a], 0,
  flatTimes[a] === flatTimes[b], 2,
  True, 0];

commentList[b_] := Which[commentQ[b], {b}, AtomQ[b], {}, True, Join @@ (commentList /@ List @@ b)];

(* ==== statistics ==== *)

spacedDots[l_] := Count[Range[Length[l]], j_ /; l[[j]] === "." && ((j > 1 && hwsQ[l[[j - 1]]]) || (j < Length[l] && hwsQ[l[[j + 1]]]))];
stats[b_] := With[{x = b /. r_ /; commentQ[r] :> ""}, <|
  "FractionBox" -> Count[x, _FractionBox, {0, Infinity}],
  "SuperscriptBox" -> Count[x, _SuperscriptBox, {0, Infinity}],
  "SqrtBox" -> Count[x, _SqrtBox, {0, Infinity}],
  "linear /" -> Count[x, "/", {0, Infinity}],
  "linear ^" -> Count[x, "^", {0, Infinity}],
  "Sqrt[..]" -> Count[x, RowBox[{"Sqrt", "[", ___}], {0, Infinity}],
  "spaced dot" -> Total[Cases[x, RowBox[l_List] :> spacedDots[l], {0, Infinity}]]|>];

(* ==== per-cell drivers ==== *)

fe[s_String] := With[{r = Quiet[Check[MathLink`CallFrontEnd[FrontEnd`UndocumentedTestFEParserPacket[s, False]], $Failed]]},
  If[MatchQ[r, {_BoxData, ___}], First[r], $Failed]];

NbFEAvailableQ[] := TrueQ[TimeConstrained[fe["a/b"] === BoxData[RowBox[{"a", "/", "b"}]], 120, False]];

label[s_String] := StringTake[StringReplace[s, "\n" | $inl -> " "], UpTo[60]];

result[status_, boxes_, tier_, reason_, lab_, before_, after_] := <|"status" -> status, "boxes" -> boxes,
  "tier" -> tier, "reason" -> reason, "label" -> lab, "before" -> before, "after" -> after|>;

trimCode[s_String] := Module[{ls = StringSplit[StringReplace[s, "\r\n" -> "\n"], "\n", All]},
  While[ls =!= {} && StringTrim[First[ls]] === "", ls = Rest[ls]];
  While[ls =!= {} && StringTrim[Last[ls]] === "", ls = Most[ls]];
  StringRiffle[ls, "\n"]];

(* orig is what a refused cell keeps. ref: semantics the output must reproduce (source string parse, or oracle of the original boxes;
   Missing[] when the oracle cannot read the original, leaving the literal box check alone). *)
verify[orig_, pre_, post_, ref_, lab_] := Module[{t1, t2},
  If[commentList[pre] =!= commentList[post],
    Return[result["refused", orig, 0, "comment count/content changed", lab, stats[pre], stats[pre]]]];
  t1 = tier[literal[pre], literal[post]];
  t2 = If[MissingQ[ref], t1, tier[ref, oracle[post]]];
  If[Min[t1, t2] == 0,
    result["refused", orig, 0,
      If[t1 == 0, "box ToExpression differs after rewrite", "statement-level meaning differs after rewrite"],
      lab, stats[pre], stats[pre]],
    result["changed", post, Min[t1, t2], If[MissingQ[ref], "literal box check only (oracle n/a)", ""],
      lab, stats[pre], stats[post]]]];

(* Cells with nothing to rewrite keep their original string, so extract -> create round trips stay exact. *)
NbFormatCode[code_String] := Module[{src = trimCode[code], raw = BoxData[code], srcH, pre, post, lab},
  lab = label[src];
  If[src === "", Return[result["unchanged", raw, 1, "", lab, stats[raw], stats[raw]]]];
  If[! TrueQ[$NbFE], Return[result["nofe", raw, 0, "front end unavailable", lab, stats[raw], stats[raw]]]];
  srcH = dropNull[parseText[src]];
  If[srcH === $Failed, Return[result["refused", raw, 0, "kernel cannot parse the source", lab, stats[raw], stats[raw]]]];
  pre = fe[src];
  If[pre === $Failed, Return[result["refused", raw, 0, "FE parser failed", lab, stats[raw], stats[raw]]]];
  If[oracle[pre] =!= srcH,
    Return[result["refused", raw, 0, "FE boxes disagree with the kernel string parse", lab, stats[pre], stats[pre]]]];
  post = tr[pre];
  If[post === pre, Return[result["unchanged", raw, 1, "", lab, stats[pre], stats[pre]]]];
  verify[raw, pre, post, srcH, lab]];

NbFormatBoxes[BoxData[s_String, ___]] := NbFormatCode[s];
NbFormatBoxes[bd_BoxData] := Module[{post = tr[bd], lab = label[First[serialize[bd]]], o},
  If[post === bd, Return[result["unchanged", bd, 1, "", lab, stats[bd], stats[bd]]]];
  o = oracle[bd];
  verify[bd, bd, post, If[o === $Failed, Missing[], o], lab]];

NbFormatNotebook[nb_Notebook] := Module[{log = {}, walk},
  walk[Cell[CellGroupData[cs_List, r___], o___]] := Cell[CellGroupData[walk /@ cs, r], o];
  walk[c : Cell[content_BoxData, style : "Input" | "Code", o___]] := With[{res = NbFormatBoxes[content]},
    AppendTo[log, res];
    If[MemberQ[{"refused", "nofe"}, res["status"]], c, Cell[res["boxes"], style, o]]];
  walk[c_] := c;
  {Notebook[walk /@ First[nb], Sequence @@ Rest[List @@ nb]], log}];

(* ==== .wl / .m packages ==== *)

markerQ[l_String] := StringMatchQ[l, RegularExpression["\\(\\* ::[A-Za-z]+(::[A-Za-z]+)*:: \\*\\)\\s*"]];
markerStyle[l_String] := First[StringCases[l, RegularExpression["\\(\\* ::([A-Za-z]+)"] -> "$1"]];
wrappedQ[l_String] := StringLength[l] >= 4 && StringStartsQ[l, "(*"] && StringEndsQ[l, "*)"];
unwrap[l_String] := StringTake[l, {3, -3}];

(* Bare code between markers: cells break at blank lines, but only where the text so far is
   syntactically complete, so a blank line inside a Module does not split it. *)
codeChunks[t_String] := Module[{parts, out = {}, cur = ""},
  parts = StringSplit[t, s : RegularExpression["\\n([ \\t]*\\n)+"] :> s, All];
  Do[
    If[OddQ[i],
      cur = cur <> parts[[i]];
      If[StringTrim[cur] =!= "" && SyntaxQ[cur], AppendTo[out, cur]; cur = ""],
      If[cur =!= "", cur = cur <> parts[[i]]]],
    {i, Length[parts]}];
  If[StringTrim[cur] =!= "", AppendTo[out, cur]];
  trimCode /@ out];

NbPackageToCells[text_String] := Module[{lines, n, i = 1, j, out = {}, bare = {}, style, block, flush},
  lines = StringSplit[StringReplace[text, "\r\n" -> "\n"], "\n", All];
  n = Length[lines];
  flush[] := (
    If[StringTrim[StringRiffle[bare, "\n"]] =!= "",
      out = Join[out, {"Input", #, True} & /@ codeChunks[StringRiffle[bare, "\n"]]]];
    bare = {});
  While[i <= n,
    If[markerQ[lines[[i]]],
      flush[];
      style = markerStyle[lines[[i]]];
      i++;
      j = i;
      While[j <= n && lines[[j]] =!= "" && ! markerQ[lines[[j]]] && wrappedQ[lines[[j]]], j++];
      block = unwrap /@ lines[[i ;; j - 1]];
      Which[
        style === "Package" || block === {}, Null,
        MemberQ[{"Input", "Code"}, style], AppendTo[out, {"Input", StringRiffle[block, "\n"], True}],
        True, AppendTo[out, {style, StringRiffle[block, "\n"], False}]];
      i = j,
      AppendTo[bare, lines[[i]]];
      i++]];
  flush[];
  out];

(* ==== report ==== *)

NbSummary[log_List] := Module[{st = #["status"] & /@ log, b, a, lines, refused},
  If[log === {}, Return["code cells processed: 0"]];
  b = Total[#["before"] & /@ log];
  a = Total[#["after"] & /@ log];
  refused = Select[log, MemberQ[{"refused", "nofe"}, #["status"]] &];
  lines = Join[
    {"code cells processed: " <> ToString[Length[log]],
     "  changed and verified: " <> ToString[Count[st, "changed"]] <>
       " (strict ===: " <> ToString[Count[log, r_ /; r["status"] === "changed" && r["tier"] == 1]] <>
       ", equal only up to Times associativity: " <> ToString[Count[log, r_ /; r["status"] === "changed" && r["tier"] == 2]] <> ")",
     "  unchanged: " <> ToString[Count[st, "unchanged"]],
     "  refused, original kept: " <> ToString[Length[refused]]},
    ("    - [" <> #["reason"] <> "] " <> #["label"]) & /@ refused,
    ("  note [" <> #["reason"] <> "] " <> #["label"]) & /@ Select[log, #["status"] === "changed" && #["reason"] =!= "" &],
    KeyValueMap[("  " <> #1 <> ": " <> ToString[#2] <> " -> " <> ToString[a[#1]]) &, b]];
  StringRiffle[lines, "\n"]];

End[];
EndPackage[];
