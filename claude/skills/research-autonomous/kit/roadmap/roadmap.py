"""Roadmap of the @NAME@ program: known results, the program's results, open rungs, and the path to the goal.

Edit NODES/EDGES (statuses change as work progresses), then run:
    python3 roadmap/roadmap.py && dot -Tpdf roadmap/roadmap.dot -o roadmap/roadmap.pdf && dot -Tsvg roadmap/roadmap.dot -o roadmap/roadmap.svg
Arrows mean "is used by". Every node needs a source: ledgers/*.md, lit/*.md or a digest.
"""
from pathlib import Path

UPDATED = "YYYY-MM-DD"

STATUS = {
    "classic":   dict(fill="#d9f2d9", color="#2e7d32", style="filled",         label="proved, refereed literature"),
    "preprint":  dict(fill="#eef8d6", color="#689f38", style="filled,dashed",  label="proved in preprint (unrefereed, used by others)"),
    "claim":     dict(fill="#fff3c4", color="#b8860b", style="filled,dashed",  label="claimed, unrefereed (owner-accepted premise)"),
    "withdrawn": dict(fill="#eeeeee", color="#9e9e9e", style="filled,dotted",  label="withdrawn"),
    "v2":        dict(fill="#d6e6fb", color="#1565c0", style="filled,bold",    label="program: V2 (AI adversaries, no human check)"),
    "argued":    dict(fill="#eaf2fd", color="#1565c0", style="filled,dashed",  label="program: argued / candidate (one agent)"),
    "open":      dict(fill="#fde0dc", color="#c62828", style="filled",         label="open"),
    "goal":      dict(fill="#c62828", color="#7f0000", style="filled,bold",    label="final goal"),
}

# id: (status, cluster, label)
NODES = {
    "K1":   ("classic",  "lit",  "Known theorem A\n(refereed; cite it)"),
    "K2":   ("preprint", "lit",  "Known result B\n(preprint, unrefereed)"),
    "P1":   ("argued",   "prog", "Program result 1\n(one agent; not yet adversarially checked)"),
    "O1":   ("open",     "open", "Open rung toward the goal"),
    "GOAL": ("goal",     "goal", "THE GOAL\n(precise statement from CHARTER.md)"),
}

# (source, target, kind) — kind: use | alt (alternative input) | special (special case of) | via
EDGES = [
    ("K1", "P1", "use"), ("K2", "P1", "alt"),
    ("P1", "O1", "special"),
    ("O1", "GOAL", "via"),
]

EDGE_STYLE = {
    "use":     'color="#424242"',
    "alt":     'color="#9e9e9e", style=dashed, label="alternative"',
    "special": 'color="#c62828", style=dashed, arrowhead=empty, label="special case"',
    "via":     'color="#1565c0", penwidth=2, label="implies"',
    "prior":   'color="#9e9e9e", style=dashed, label="prior art (same mechanism)"',
}

CLUSTERS = {"lit": "Known results (literature)", "prog": "This program", "open": "Rungs toward the goal", "goal": ""}


def esc(s):
    return s.replace('"', r'\"').replace("\n", r"\n")


def build():
    out = ["digraph roadmap {",
           '  graph [rankdir=LR, newrank=true, nodesep=0.18, ranksep=0.9, splines=true, fontname="Helvetica", '
           f'label="@NAME@ program roadmap — arrows: \\"is used by\\" — updated {UPDATED}", labelloc=t, fontsize=20];',
           '  node [shape=box, style="rounded,filled", fontname="Helvetica", fontsize=10];',
           '  edge [fontname="Helvetica", fontsize=8, arrowsize=0.7];']
    for nid, (st, cl, lab) in NODES.items():
        s = STATUS[st]
        fc = "white" if st == "goal" else "black"
        out.append(f'  {nid} [label="{esc(lab)}", fillcolor="{s["fill"]}", color="{s["color"]}", '
                   f'style="rounded,{s["style"]}", fontcolor="{fc}"];')
    for cid in ("lit",):
        ids = [n for n, v in NODES.items() if v[1] == cid and not any(b == n for _, b, _ in EDGES)]
        out.append("  { rank=min; " + " ".join(ids) + "; }")
    for a, b, k in EDGES:
        assert a in NODES and b in NODES, (a, b)
        out.append(f"  {a} -> {b} [{EDGE_STYLE[k]}];")
    out.append('  subgraph cluster_legend { label="Legend"; fontsize=12; color="#bdbdbd"; style=rounded;')
    prev = None
    for st, s in STATUS.items():
        out.append(f'    leg_{st} [label="{s["label"]}", fillcolor="{s["fill"]}", color="{s["color"]}", '
                   f'style="rounded,{s["style"]}", fontcolor="{"white" if st == "goal" else "black"}", fontsize=9];')
        if prev:
            out.append(f"    leg_{prev} -> leg_{st} [style=invis];")
        prev = st
    out.append("  }")
    out.append("  { rank=max; GOAL; }")
    out.append("}")
    Path(__file__).with_name("roadmap.dot").write_text("\n".join(out) + "\n")


if __name__ == "__main__":
    build()
