"""Nightly digest: digests/<night>.md, at most 80 lines, script-generated.

Reads only runtime files under <run> (--run, else $PROGRAM_RUN, else <root>/run): runner.jsonl
(one JSON line per job), loops/*/status.json, watchdog.log and nightly.log (one line per event:
"<date> <time> <loop> <event> ..."), thermal.log; and jobs/{queue,running} under <root>. On failure it appends the error JSON and the last
30 log lines of the failing job (or of the runner), nothing more.
"""
from __future__ import annotations

import argparse
import json
import os
import socket
from collections import Counter
from datetime import datetime
from pathlib import Path

MAX_LINES = 80
MAX_JOB_ROWS = 20


def _events(path: Path, since: float) -> list[str]:
    if not path.exists():
        return []
    out = []
    for line in path.read_text(errors="replace").splitlines():
        try:
            t = datetime.strptime(line[:19], "%Y-%m-%d %H:%M:%S").timestamp()
        except ValueError:
            continue
        if t >= since:
            out.append(line)
    return out


def _jobs(run: Path, since: float) -> list[dict]:
    f = run / "runner.jsonl"
    if not f.exists():
        return []
    recs = [json.loads(line) for line in f.read_text().splitlines() if line.strip()]
    return [r for r in recs if datetime.fromisoformat(r["ts"]).timestamp() >= since]


def _tail(path: Path, n: int = 30) -> list[str]:
    return path.read_text(errors="replace").splitlines()[-n:] if path.exists() else [f"({path} missing)"]


def build(root: Path, night: str, since: float, run: Path | None = None) -> list[str]:
    run = run or root / "run"
    jobs = _jobs(run, since)
    st_file = run / "loops" / "runner" / "status.json"
    st = json.loads(st_file.read_text()) if st_file.exists() else {"status": "never-ran", "reason": ""}
    nq = len(list((root / "jobs" / "queue").glob("*.yaml")))
    nr = len(list((root / "jobs" / "running").glob("*.yaml")))
    code = jobs[-1]["code_hash"][:8] if jobs else "-"
    L = [f"# Nightly digest {night}",
         f"host {socket.gethostname()} | since {datetime.fromtimestamp(since):%Y-%m-%d %H:%M} | "
         f"generated {datetime.now():%Y-%m-%d %H:%M} | code {code}",
         f"runner: {st['status']}{'/' + st['reason'] if st.get('reason') else ''} | "
         f"queue {nq} queued, {nr} running (resume next night)", ""]

    c = Counter(r["status"] for r in jobs)
    L.append(f"## Jobs: {len(jobs)} ({', '.join(f'{k} {v}' for k, v in sorted(c.items())) or 'none'})")
    if jobs:
        L.append("| job | task | status | wall s | items | items/s |")
        L.append("|---|---|---|---|---|---|")
        for r in jobs[:MAX_JOB_ROWS]:
            L.append(f"| {r['job']} | {r['task']} | {r['status']} | {r['wall_s']:.0f} | {r['items']} | {r['items_per_s']:.1f} |")
        if len(jobs) > MAX_JOB_ROWS:
            L.append(f"(+{len(jobs) - MAX_JOB_ROWS} more in run/runner.jsonl)")
        wall = sum(r["wall_s"] for r in jobs)
        L.append(f"total compute wall {wall / 3600:.2f} h, {sum(r['items'] for r in jobs)} items")
    L.append("")

    wd = _events(run / "watchdog.log", since)
    ng = _events(run / "nightly.log", since)
    th = _events(run / "thermal.log", since)
    ev = Counter(line.split()[3] for line in wd if len(line.split()) > 3)
    L.append("## Supervision")
    L.append("watchdog: " + (", ".join(f"{k} {v}" for k, v in sorted(ev.items())) or "no events"))
    for line in [x for x in wd if x.split()[3:4] and x.split()[3] in ("restart", "stuck", "usage-exhausted")][-8:]:
        L.append(f"  {line}")
    keep = ("inhibit", "git-lock", "git-busy")
    for line in [x for x in ng if len(x.split()) > 3 and x.split()[3] in keep][-4:]:
        L.append(f"nightly: {' '.join(line.split()[1:])}")
    # commit/push happen after the digest is written, so report the latest ones ever logged
    git = [x for x in _events(run / "nightly.log", 0) if x.split()[3:4] in (["commit"], ["push"])]
    L.append("last git: " + (" | ".join(git[-2:]) if git else "none yet"))
    L.append(f"thermal: {sum(' pause ' in x for x in th)} pauses, {sum(' resume ' in x for x in th)} resumes")
    for loop_status in sorted((run / "loops").glob("*/status.json")):
        if loop_status.parent.name != "runner":
            s = json.loads(loop_status.read_text())
            L.append(f"loop {loop_status.parent.name}: {s['status']} {s.get('reason', '')}".rstrip())

    F: list[str] = []
    failed = [r for r in jobs if r["status"] == "error"]
    if failed or st["status"] == "crashed":
        F += ["", "## Failure"]
        F += [json.dumps(r, sort_keys=True) for r in failed[:3]]
        if st["status"] == "crashed":
            F.append(json.dumps(st, sort_keys=True))
        log = (run / "work" / failed[0]["key"] / "job.log") if failed else run / "runner.log"
        F += ["```", *_tail(log, 30), "```"]

    room = MAX_LINES - len(F)
    if len(L) > room:  # the failure section is never cut
        L = L[:room - 1] + [f"(truncated {len(L) - room + 1} lines)"]
    return L + F


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[2])
    ap.add_argument("--night", required=True, help="YYYY-MM-DD, the date the window started")
    ap.add_argument("--since", type=float, required=True, help="epoch seconds, window start")
    ap.add_argument("--run", type=Path, default=os.environ.get("PROGRAM_RUN") or None)
    ap.add_argument("--out", type=Path)
    a = ap.parse_args(argv)
    lines = build(a.root, a.night, a.since, a.run)
    out = a.out or a.root / "digests" / f"{a.night}.md"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text("\n".join(lines) + "\n")
    print(out)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
