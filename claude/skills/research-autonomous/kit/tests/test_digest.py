"""Digest: failure section (error JSON + last 30 log lines) and the 80-line cap."""
from __future__ import annotations

import json
import time
from datetime import datetime

from program import digest


def _root(tmp, n_jobs: int, fail: bool):
    for d in ("jobs/queue", "jobs/running", "run/loops/runner"):
        (tmp / d).mkdir(parents=True, exist_ok=True)
    ts = datetime.now().astimezone().isoformat(timespec="seconds")
    recs = [{"job": f"j{i:03d}", "task": "example", "key": f"k{i}", "status": "done", "wall_s": 1.0,
             "items": 10, "items_per_s": 10.0, "outputs": [], "code_hash": "c" * 64, "ts": ts}
            for i in range(n_jobs)]
    if fail:
        recs.append({**recs[0], "job": "bad", "key": "kbad", "status": "error", "error": "ValueError: boom"})
        log = tmp / "run" / "work" / "kbad" / "job.log"
        log.parent.mkdir(parents=True)
        log.write_text("".join(f"log line {i}\n" for i in range(100)))
    (tmp / "run" / "runner.jsonl").write_text("".join(json.dumps(r) + "\n" for r in recs))
    (tmp / "run" / "loops" / "runner" / "status.json").write_text('{"status": "stopped", "reason": "window_end"}')
    return tmp


def test_failure_section(tmp_path):
    lines = digest.build(_root(tmp_path, 3, True), "2026-10-05", time.time() - 60)
    i = lines.index("## Failure")
    assert json.loads(lines[i + 1])["error"] == "ValueError: boom"
    body = lines[lines.index("```", i) + 1:-1]
    assert body == [f"log line {k}" for k in range(70, 100)]
    assert len(lines) <= digest.MAX_LINES


def test_cap_keeps_failure_intact(tmp_path):
    lines = digest.build(_root(tmp_path, 200, True), "2026-10-05", time.time() - 60)
    assert len(lines) <= digest.MAX_LINES
    assert lines[-2] == "log line 99" and "## Failure" in lines


def test_quiet_night(tmp_path):
    root = _root(tmp_path, 0, False)
    (root / "run" / "nightly.log").write_text("2026-10-04 06:30:05 nightly commit ok abc1234\n"
                                              "2026-10-04 06:30:09 nightly push failed\n")
    lines = digest.build(root, "2026-10-05", time.time() - 60)
    assert "## Jobs: 0 (none)" in lines and "## Failure" not in lines
    assert any(x.startswith("last git: ") and "push failed" in x for x in lines)
