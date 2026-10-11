"""Runner tests in throwaway roots (never the repo's jobs/ or results/)."""
from __future__ import annotations

import json
import os
import signal
import subprocess
import sys
import time
from pathlib import Path

import pytest
import yaml

SRC = Path(__file__).resolve().parents[1] / "src"
# PROGRAM_* from the caller's shell (e.g. a Dropbox setup) must not redirect test output
ENV = {**{k: v for k, v in os.environ.items() if not k.startswith("PROGRAM_")}, "PYTHONPATH": str(SRC)}
LONG = {"task": "example", "params": {"n_items": 3000, "chunk": 20, "sleep_s": 0.015}, "seed": 7, "checkpoint_s": 0.3}


def make_root(tmp: Path, jobs: dict[str, dict]) -> Path:
    for d in ("queue", "running", "done"):
        (tmp / "jobs" / d).mkdir(parents=True, exist_ok=True)
    for name, m in jobs.items():
        (tmp / "jobs" / "queue" / f"{name}.yaml").write_text(yaml.safe_dump(m))
    return tmp


def start(root: Path, *args: str) -> subprocess.Popen:
    return subprocess.Popen([sys.executable, "-m", "program.runner", "--root", str(root), *args],
                            env=ENV, stdout=subprocess.PIPE, text=True)


def finish(p: subprocess.Popen, timeout: float = 60) -> list[dict]:
    out, _ = p.communicate(timeout=timeout)
    return [json.loads(line) for line in out.splitlines() if line.startswith("{")]


def checkpoint_next(root: Path) -> int:
    for c in (root / "run" / "work").glob("*/checkpoint.json"):
        try:
            return json.loads(c.read_text())["state"].get("next", 0)
        except (json.JSONDecodeError, FileNotFoundError):
            return 0
    return 0


def outputs(root: Path) -> dict[str, bytes]:
    res = root / "results"
    return {str(p.relative_to(res)): p.read_bytes() for p in sorted(res.rglob("*"))
            if p.is_file() and p.name != "result.json"}


def interrupt_and_resume(root: Path, sig: int) -> list[dict]:
    p = start(root)
    deadline = time.time() + 30
    while checkpoint_next(root) < 40:
        assert time.time() < deadline and p.poll() is None
        time.sleep(0.05)
    p.send_signal(sig)
    first = finish(p)
    assert list((root / "jobs" / "running").glob("*.yaml")), "interrupted job must stay in running/"
    return first + finish(start(root))


def test_queue_to_done(tmp_path):
    root = make_root(tmp_path, {"a": {"task": "example", "params": {"n_items": 100, "chunk": 10}}})
    (rec,) = finish(start(root))
    assert rec["status"] == "done" and rec["items"] == 100 and rec["items_per_s"] > 0
    assert rec["outputs"] == [f"results/example/{rec['key']}/summary.json"]
    assert {"wall_s", "code_hash", "ts"} <= rec.keys()
    assert (root / "jobs" / "done" / "a.yaml").exists() and (root / "jobs" / "done" / "a.json").exists()
    assert not list((root / "jobs" / "queue").glob("*.yaml"))
    st = json.loads((root / "run" / "loops" / "runner" / "status.json").read_text())
    assert (st["status"], st["reason"]) == ("stopped", "queue_empty")


@pytest.mark.parametrize("sig", [signal.SIGTERM, signal.SIGKILL])
def test_kill_resume_identical(tmp_path, sig):
    ref = make_root(tmp_path / "ref", {"j": LONG})
    (r0,) = finish(start(ref))
    assert r0["status"] == "done"
    root = make_root(tmp_path / "cut", {"j": LONG})
    recs = interrupt_and_resume(root, sig)
    assert recs[-1]["status"] == "done" and recs[-1]["key"] == r0["key"]
    if sig == signal.SIGTERM:
        assert recs[0]["status"] == "interrupted"
    assert recs[-1]["items"] >= r0["items"]  # a chunk in flight at SIGKILL is recomputed
    assert outputs(root) == outputs(ref)


def test_stale_temp_files_removed_on_resume(tmp_path):
    ref = make_root(tmp_path / "ref", {"j": LONG})
    (r0,) = finish(start(ref))
    root = make_root(tmp_path / "cut", {"j": LONG})
    p = start(root)
    while checkpoint_next(root) < 20:
        time.sleep(0.05)
    p.send_signal(signal.SIGKILL)
    finish(p)
    for sub in ("results/example", "results/raw/example"):
        (root / sub / r0["key"] / ".chunk_00099.bin.tmp12345").write_bytes(b"partial")
    finish(start(root))
    assert outputs(root) == outputs(ref)


def test_cache_hit_and_force(tmp_path):
    small = {"task": "example", "params": {"n_items": 50, "chunk": 10}}
    root = make_root(tmp_path, {"a": small, "b": small, "c": {**small, "force": True}})
    recs = finish(start(root))
    assert [r["status"] for r in recs] == ["done", "cached", "done"]
    assert len({r["key"] for r in recs}) == 1
    log = (root / "run" / "runner.log").read_text()
    assert "cache hit" in log and "force=true, recomputing" in log


def test_error_job_does_not_stop_queue(tmp_path):
    root = make_root(tmp_path, {"a": {"task": "no_such_task", "params": {}},
                                "b": {"task": "example", "params": {"n_items": 10, "chunk": 5}}})
    recs = finish(start(root))
    assert [r["status"] for r in recs] == ["error", "done"]
    assert "ModuleNotFoundError" in recs[0]["error"]


def test_bad_manifest_is_a_job_error(tmp_path):
    root = make_root(tmp_path, {"b": {"task": "example", "params": {"n_items": 10, "chunk": 5}}})
    (root / "jobs" / "queue" / "a.yaml").write_text("task: [unclosed\n")
    recs = finish(start(root))
    assert [r["status"] for r in recs] == ["error", "done"] and "bad manifest" in recs[0]["error"]
    assert (root / "jobs" / "done" / "a.yaml").exists()


def test_window_end(tmp_path):
    root = make_root(tmp_path, {"j": LONG})
    recs = finish(start(root, "--until", str(time.time() + 1.5)))
    assert recs[0]["status"] == "interrupted"
    st = json.loads((root / "run" / "loops" / "runner" / "status.json").read_text())
    assert st["reason"] == "window_end"
    assert json.loads(next((root / "run" / "work").glob("*/checkpoint.json")).read_text())["state"]["next"] > 0


def test_single_instance(tmp_path):
    root = make_root(tmp_path, {"j": LONG})
    p = start(root)
    time.sleep(1.0)
    (busy,) = finish(start(root))
    assert busy["status"] == "busy"
    p.send_signal(signal.SIGTERM)
    finish(p)


def test_program_run_moves_runtime_files(tmp_path):
    root = make_root(tmp_path / "proj", {"a": {"task": "example", "params": {"n_items": 10, "chunk": 5}}})
    run = tmp_path / "elsewhere"
    p = subprocess.Popen([sys.executable, "-m", "program.runner", "--root", str(root)],
                         env={**ENV, "PROGRAM_RUN": str(run)}, stdout=subprocess.PIPE, text=True)
    (rec,) = finish(p)
    assert rec["status"] == "done" and not (root / "run").exists()
    assert (run / "runner.jsonl").exists() and (run / "loops" / "runner" / "status.json").exists()
    assert (root / "results" / "example" / rec["key"] / "summary.json").exists()


def test_program_raw_moves_bulk_output(tmp_path):
    root = make_root(tmp_path / "proj", {"a": {"task": "example", "params": {"n_items": 10, "chunk": 5}}})
    raw = tmp_path / "rawstore"
    p = subprocess.Popen([sys.executable, "-m", "program.runner", "--root", str(root)],
                         env={**ENV, "PROGRAM_RAW": str(raw)}, stdout=subprocess.PIPE, text=True)
    (rec,) = finish(p)
    assert rec["status"] == "done" and not (root / "results" / "raw").exists()
    assert sorted(p.name for p in (raw / "example" / rec["key"]).iterdir()) == ["chunk_00000.bin", "chunk_00001.bin"]
