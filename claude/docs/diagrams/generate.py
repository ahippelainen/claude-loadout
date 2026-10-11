#!/usr/bin/env python3
"""Flow charts of the two research setups, as self-contained 1600x900 SVGs (white background, so they
sit on any slide theme), plus PNG previews rendered with Inkscape when it is installed.

- research-physics.svg: the attended flow; Claude works in LLM/, the author checks and promotes
- research-math.svg: the autonomous program of skills/research-autonomous

Run with: python3 generate.py
"""

import pathlib
import shutil
import subprocess
from xml.sax.saxutils import escape

DIR = pathlib.Path(__file__).resolve().parent
W, H = 1600, 900
FONT = "Inter, 'Source Sans Pro', 'Source Sans 3', Helvetica, Arial, sans-serif"
MONO = "'JetBrains Mono', 'DejaVu Sans Mono', monospace"

INK = "#1f2933"
MUTED = "#52606d"
LINE = "#52606d"
CLAUDE = "#d97757"
PALETTE = {
    "you": ("#fdf3ea", "#e0a36f"),
    "claude": ("#eef4fb", "#7b9cc4"),
    "check": ("#f3eefb", "#9b85c9"),
    "yours": ("#f1f7ee", "#8fb67f"),
    "machine": ("#f4f5f7", "#9aa5b1"),
    "rail": ("#fbfbf3", "#c9c08f"),
    "killed": ("#fbeeee", "#c98f8f"),
}

# The Claude Code mascot as drawn in the slides' prompt boxes: (x, y) cells of an 11x5 grid.
MASCOT = [(x, 0) for x in range(1, 10)] + [(1, 1), (2, 1), (4, 1), (5, 1), (6, 1), (8, 1), (9, 1)] \
    + [(x, 2) for x in range(11)] + [(x, 3) for x in range(1, 10)] + [(1, 4), (3, 4), (7, 4), (9, 4)]


class Svg:
    def __init__(self, title: str):
        self.parts = [
            f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}" font-family="{FONT}">',
            f"<title>{escape(title)}</title>",
            '<defs><marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto">'
            f'<path d="M0,0 L10,5 L0,10 Z" fill="{LINE}"/></marker></defs>',
            f'<rect width="{W}" height="{H}" fill="#ffffff"/>',
        ]

    def add(self, s: str) -> None:
        self.parts.append(s)

    def text(self, x: float, y: float, s: str, size: int = 20, weight: int = 400, color: str = INK,
             anchor: str = "start", mono: bool = False, italic: bool = False) -> None:
        fam = f' font-family="{MONO}"' if mono else ""
        sty = ' font-style="italic"' if italic else ""
        self.add(f'<text x="{x:g}" y="{y:g}" font-size="{size}" font-weight="{weight}" fill="{color}" '
                 f'text-anchor="{anchor}" xml:space="preserve"{fam}{sty}>{escape(s)}</text>')

    def box(self, x: float, y: float, w: float, h: float, kind: str, dash: bool = False, rx: int = 16,
            width: float = 2) -> None:
        fill, stroke = PALETTE[kind]
        d = ' stroke-dasharray="8 6"' if dash else ""
        self.add(f'<rect x="{x:g}" y="{y:g}" width="{w:g}" height="{h:g}" rx="{rx}" fill="{fill}" '
                 f'stroke="{stroke}" stroke-width="{width}"{d}/>')

    def card(self, x: float, y: float, w: float, h: float, kind: str, title: str, lines: list[str],
             size: int = 18, title_size: int = 21, icon: str | None = None, dash: bool = False) -> None:
        """A box with a bold title and body lines; a line starting with '`' is set in monospace."""
        self.box(x, y, w, h, kind, dash=dash)
        tx = x + 18
        if icon == "claude":
            self.mascot(x + 18, y + 16, 3.2)
            tx = x + 18 + 11 * 3.2 + 12
        elif icon == "you":
            self.person(x + 34, y + 30)
            tx = x + 62
        self.text(tx, y + 34, title, title_size, 700)
        yy = y + 34 + title_size * 0.5 + size * 1.25
        for line in lines:
            mono = line.startswith("`")
            self.text(x + 18, yy, line.strip("`"), size - 1 if mono else size, color=INK if mono else MUTED,
                      mono=mono)
            yy += size * 1.35

    def chip(self, x: float, y: float, s: str, kind: str = "claude", size: int = 16, mono: bool = True) -> float:
        """A small rounded label; returns its width."""
        w = (len(s) * size * 0.62 if mono else sum(size * (0.7 if ch.isupper() else 0.52) for ch in s)) + 20
        self.box(x, y, w, size + 14, kind, rx=8, width=1.5)
        self.text(x + 10, y + size + 3, s, size, mono=mono)
        return w

    def mascot(self, x: float, y: float, cell: float) -> None:
        cells = "".join(f'<rect x="{x + cx * cell:g}" y="{y + cy * cell:g}" width="{cell:g}" height="{cell:g}"/>'
                        for cx, cy in MASCOT)
        self.add(f'<g fill="{CLAUDE}" shape-rendering="crispEdges">{cells}</g>')

    def person(self, cx: float, cy: float) -> None:
        stroke = PALETTE["you"][1]
        self.add(f'<circle cx="{cx:g}" cy="{cy - 7:g}" r="7" fill="{stroke}"/>'
                 f'<path d="M{cx - 13:g},{cy + 15:g} a13,11 0 0 1 26,0 z" fill="{stroke}"/>')

    def arrow(self, pts: list[tuple[float, float]], label: str = "", lx: float | None = None,
              ly: float | None = None, dash: bool = False, anchor: str = "middle", rotate: bool = False) -> None:
        d = " ".join(f"{'M' if i == 0 else 'L'}{x:g},{y:g}" for i, (x, y) in enumerate(pts))
        ds = ' stroke-dasharray="7 6"' if dash else ""
        self.add(f'<path d="{d}" fill="none" stroke="{LINE}" stroke-width="2.4"{ds} marker-end="url(#arrow)"/>')
        if label:
            if lx is None:
                (x0, y0), (x1, y1) = pts[0], pts[1]
                lx, ly = (x0 + x1) / 2, (y0 + y1) / 2 - 10
            if rotate:
                self.add(f'<g transform="rotate(-90 {lx:g} {ly:g})">')
            self.text(lx, ly, label, 17, color=MUTED, anchor=anchor, italic=True)
            if rotate:
                self.add("</g>")

    def save(self, name: str) -> pathlib.Path:
        path = DIR / name
        path.write_text("\n".join(self.parts + ["</svg>"]) + "\n", encoding="utf-8")
        return path


def physics() -> Svg:
    s = Svg("Research flow with the author in the loop: Claude works in LLM/, the author checks and promotes")

    s.card(30, 40, 290, 150, "you", "You", ["dictate the question", "in plain words"], icon="you")
    s.card(390, 30, 560, 170, "claude", "Claude Code session", [
        "reads your rules (CLAUDE.md) and",
        "the project's LLM/conventions.md;",
        "plans, asks before fixing a convention",
    ], icon="claude")
    s.arrow([(320, 115), (390, 115)])

    # Claude's sandbox
    s.box(30, 250, 1060, 400, "claude", dash=True)
    s.text(52, 286, "LLM/  — Claude's sandbox", 24, 700)
    s.text(52, 314, "specialist subagents, each in a fresh context", 18, color=MUTED)
    agents = [
        ("Literature", ["lit-sweep: arXiv, INSPIRE", "notes → LLM/, PDFs → Papers/"]),
        ("Derivations", ["holographist, fluctuation-", "analyst, radial-ode-specialist"]),
        ("Numerics", ["mathematica-pro, python-pro", "runs time-boxed (wlrun)"]),
    ]
    for i, (title, lines) in enumerate(agents):
        s.card(52 + i * 340, 334, 320, 130, "claude", title, lines, size=17, title_size=19)
    s.arrow([(670, 200), (670, 250)], "delegates", 690, 232, anchor="start")
    s.text(52, 500, "what lands here:", 18, 700, color=MUTED)
    x = 52
    for c in ["YYMMDD_Topic.wl", "run_topic.log", "Cache/*.mx"]:
        x += s.chip(x, 515, c) + 12
    x = 52
    for c in ["notebook_sources/*_src.wl", "YYMMDD_note.tex", "figures"]:
        x += s.chip(x, 565, c, mono=c != "figures") + 12
    s.text(52, 630, "a changed computation is a new dated script, never an edit of the old one", 17,
           color=MUTED, italic=True)

    # Independent checks
    s.card(1150, 250, 420, 210, "check", "Independent checks", [
        "physics-review verify: recomputes",
        "from scratch in a fresh context",
        "derivation-note: every step, compiled",
        "with your preamble",
        "academic-paper-reviewer: mock referees",
    ], size=17, title_size=21)
    s.arrow([(1090, 355), (1150, 355)])

    # The gate
    s.card(1150, 500, 420, 120, "you", "You check and promote", [
        "step through the notebook, read the note;",
        "nothing leaves LLM/ without you",
    ], size=17, icon="you")
    s.arrow([(1360, 460), (1360, 500)])
    s.arrow([(1150, 580), (1120, 580), (1120, 115), (950, 115)], "fix this, try that", 1135, 150, dash=True,
            anchor="start")

    # Your files
    s.card(1150, 680, 420, 190, "yours", "Your files", [
        "`Numerics/  Paper/  notes.tex",
        "the paper chain from here:",
        "academic-paper, /cite-check,",
        "journal-port, arxiv-package",
    ], size=17)
    s.arrow([(1360, 620), (1360, 680)], "promote", 1375, 655, anchor="start")

    # Rails
    s.box(30, 690, 1060, 180, "rail")
    s.text(52, 726, "Always on", 22, 700)
    s.text(190, 726, "rules in CLAUDE.md, and hooks that run every time (the model cannot skip them)", 18, color=MUTED)
    rails = [
        ["claims tagged measured / inferred / web-sourced / assumed", "a .tex edit → chktex warnings back to Claude"],
        ["Mathematica only with a kill timeout; leftover kernels killed", "git push only where you have approved it"],
    ]
    for r, row in enumerate(rails):
        for c, txt in enumerate(row):
            s.text(52 + c * 560, 770 + r * 40, "• " + txt, 17, color=INK)
    s.text(52, 852, "corrections you give go into memory at once, so the next session has them", 17,
           color=MUTED, italic=True)
    return s


def math() -> Svg:
    s = Svg("Autonomous research program: charter, ledgers and verification tiers, nightly compute, headless rounds")

    s.card(30, 30, 300, 210, "you", "You", [
        "give a folder + a problem",
        "approve the charter",
        "answer open questions",
        "sign off: tier V3",
    ], icon="you")
    s.card(400, 30, 560, 210, "claude", "Orchestrator", [
        "with you: an interactive session",
        "away: fresh headless rounds, one task each,",
        "supervised hourly by a watchdog;",
        "reads STATE.md, updates ledgers, commits",
    ], icon="claude")
    s.arrow([(330, 135), (400, 135)])
    s.card(1030, 30, 540, 210, "machine", "Files are the state", [
        "`CHARTER.md  claims tagged [K] [V] [H]",
        "`STATE.md    ≤ 150 lines, rewritten",
        "`tasks/      one card per task unit",
        "`lit/        one distilled note per source",
        "`digests/    one summary per night",
    ], size=18)
    s.arrow([(960, 135), (1030, 135)])

    # Roles
    s.box(30, 285, 930, 225, "claude", dash=True)
    s.text(52, 320, "Role agents, each fresh", 22, 700)
    roles = [("Librarian", "lit notes,", "novelty checks"), ("Engineer", "code, tests,", "job manifests"),
             ("Constructor", "proposes", "arguments"), ("Adversary", "attacks every", "claim before V2"),
             ("Auditor", "efficiency", "reviews")]
    for i, (t, a, b) in enumerate(roles):
        s.card(52 + i * 180, 340, 168, 150, "check" if t == "Adversary" else "claude", t, [a, b], size=16,
               title_size=18)
    s.arrow([(680, 240), (680, 285)], "dispatches", 695, 270, anchor="start")

    # Ledgers
    s.box(1030, 285, 540, 225, "yours")
    s.text(1052, 320, "Ledgers: nothing is ever deleted", 22, 700)
    x, cx = 1052, {}
    for t in ["IDEAS", "CANDIDATES", "VERIFIED"]:
        w = s.chip(x, 340, t, "yours", 16, mono=False)
        cx[t] = x + w / 2
        if t != "VERIFIED":
            s.arrow([(x + w + 3, 355), (x + w + 23, 355)])
        x += w + 28
    s.arrow([(cx["CANDIDATES"], 370), (cx["CANDIDATES"], 398)])
    s.chip(cx["CANDIDATES"] - 60, 400, "KILLED, with the reason", "killed", 15, mono=False)
    tiers = ["V0 computed once", "V1 independent code agrees", "V2 adversary + novelty check",
             "V3 you understood it"]
    for i, t in enumerate(tiers):
        s.text(1052 + (i % 2) * 260, 462 + (i // 2) * 28, t, 16, 700 if i == 3 else 400,
               CLAUDE if i == 3 else MUTED)
    s.arrow([(960, 400), (1030, 400)])

    # Machines
    s.box(30, 555, 930, 315, "machine")
    s.text(52, 592, "Machines, no LLM", 22, 700)
    s.text(330, 592, "agents design and verify code; machines search", 18, color=MUTED)
    s.card(52, 615, 280, 160, "machine", "22:00 cron", ["`nightly.sh", "job queue → runner", "low priority"], size=17)
    s.card(352, 615, 280, 160, "machine", "Runner", ["cache by code hash", "checkpoint ≤ 15 min", "resumable"], size=17)
    s.card(652, 615, 286, 160, "machine", "06:30 digest", ["script-written,", "≤ 80 lines,", "committed"], size=17)
    s.arrow([(332, 695), (352, 695)])
    s.arrow([(632, 695), (652, 695)])
    s.text(52, 810, "• hourly watchdog: restart a crash (≤ 6 a day), retry after a usage limit, never restart a stop",
           17)
    s.text(52, 845, "• optional 06:45 literature watch: one headless round → lit/daily/", 17)
    s.arrow([(300, 490), (300, 615)], "manifests", 312, 545, anchor="start")
    s.arrow([(938, 660), (985, 660), (985, 200), (960, 200)], "read each morning", 1006, 650, anchor="start",
            rotate=True)

    # Outputs
    s.card(1030, 555, 540, 315, "you", "For you, before anything is published", [
        "roadmap graph: known → proved here → open",
        "lecture notes from the basics",
        "companion note per headline result,",
        "read by two fresh referees first",
    ], size=18)
    s.text(1052, 755, "only V3 leaves the repository", 18, 700, CLAUDE)
    nodes = [("known", "#d9f2d9", "#2e7d32"), ("V2 here", "#d6e6fb", "#1565c0"), ("open", "#fde0dc", "#c62828"),
             ("goal", "#c62828", "#7f0000")]
    x = 1052
    for i, (t, fill, stroke) in enumerate(nodes):
        s.add(f'<rect x="{x}" y="790" width="104" height="44" rx="10" fill="{fill}" stroke="{stroke}" stroke-width="2"/>')
        s.text(x + 52, 818, t, 16, 700 if t == "goal" else 400, "#ffffff" if t == "goal" else INK, anchor="middle")
        if i < len(nodes) - 1:
            s.arrow([(x + 106, 812), (x + 128, 812)])
        x += 130
    s.arrow([(1300, 510), (1300, 555)])
    return s


def main() -> None:
    for fig, name in [(physics(), "research-physics.svg"), (math(), "research-math.svg")]:
        path = fig.save(name)
        if shutil.which("inkscape"):
            subprocess.run(["timeout", "-s", "KILL", "120", "inkscape", str(path), "--export-type=png",
                            f"--export-filename={path.with_suffix('.png')}", "--export-width=1600"],
                           check=True, capture_output=True)
        print(path)


if __name__ == "__main__":
    main()
