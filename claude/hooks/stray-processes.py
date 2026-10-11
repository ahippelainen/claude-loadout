#!/usr/bin/env python3
# Stop hook: before Claude finishes, list Wolfram kernels and LaTeX runs this session left behind (and orphaned
# ones), and ask Claude to kill them or say why they must keep running. Each process is reported once per session,
# so a deliberate long job does not block every later stop.
import json, os, sys
from pathlib import Path

NAMES = {"WolframKernel", "MathKernel", "wolframscript", "pdflatex", "lualatex", "xelatex", "latexmk", "bibtex", "biber"}
FRONTENDS = {"Mathematica", "WolframNB", "Wolfram"}

data = json.load(sys.stdin)
memo = Path(f"/tmp/claude-stray-{data.get('session_id', 'none')}")
reported = set(memo.read_text().split()) if memo.exists() else set()


def stat(pid):
    try:
        s = Path(f"/proc/{pid}/stat").read_text()
        comm = s[s.index("(") + 1 : s.rindex(")")]
        ppid = int(s[s.rindex(")") + 2 :].split()[1])
        return comm, ppid
    except (OSError, ValueError, IndexError):
        return None, 0


def ancestors(pid):
    """(pid, comm) for pid and each of its ancestors, nearest first."""
    out = []
    while pid > 1:
        comm, ppid = stat(pid)
        if comm is None:
            break
        out.append((pid, comm))
        pid = ppid
    return out


def is_claude(pid, comm):
    try:
        exe = os.readlink(f"/proc/{pid}/exe")
    except OSError:
        exe = ""
    return comm == "claude" or "/claude/versions/" in exe or exe.endswith("/native-binary/claude")


session = next((p for p, c in ancestors(os.getppid()) if is_claude(p, c)), None)
found = []
for d in Path("/proc").iterdir():
    if not d.name.isdigit() or d.name in reported:
        continue
    pid = int(d.name)
    comm, ppid = stat(pid)
    if comm not in NAMES:
        continue
    chain = ancestors(ppid)
    names = {c for _, c in chain}
    ours = session is not None and any(p == session for p, _ in chain)
    orphan = ppid == 1 or bool(chain and chain[0][1] == "systemd")
    if (ours or orphan) and not names & FRONTENDS:
        try:
            cmdline = Path(f"/proc/{pid}/cmdline").read_bytes().replace(b"\0", b" ").decode()[:120]
        except OSError:
            cmdline = comm
        found.append((pid, "this session" if ours else "orphaned", cmdline))

if found:
    memo.write_text(" ".join(sorted(reported | {str(p) for p, _, _ in found})))
    lines = "\n".join(f"  {p} ({who}): {c}" for p, who, c in found)
    print(json.dumps({"decision": "block", "reason": "These processes are still running:\n" + lines +
                      "\nKill the ones this work started (kill -9 <pid>) unless they are meant to keep running, "
                      "and say which you left and why; then finish."}))
