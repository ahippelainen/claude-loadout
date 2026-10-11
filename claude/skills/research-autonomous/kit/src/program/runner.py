"""Job runner: jobs/queue/*.yaml -> jobs/running/ -> jobs/done/.

Manifest (YAML), file stem = job id, jobs taken in name order (running/ first, i.e. resumes):
    task: example          # module program.tasks.<task> defining run(ctx) -> list[str] | None
    params: {n_items: 100, chunk: 10}  # passed to the task; part of the cache key
    seed: 0                # part of the cache key (default 0)
    checkpoint_s: 600      # optional; capped at 900 (checkpoint at least every 15 min)
    force: false           # recompute despite a cached result (logged, never silent)

Cache key = "<sha256(task, params, seed)[:12]>-<code hash[:8]>". Compact outputs go to
results/<task>/<key>/ (committed), bulk output to <raw>/<task>/<key>/, checkpoints and the job
log to <run>/work/<key>/. <run> is --run, else $PROGRAM_RUN, else <root>/run; <raw> is --raw,
else $PROGRAM_RAW, else <root>/results/raw (gitignored); both may live outside a synced folder. A finished key is never recomputed unless
`force` is set; a key whose params match an earlier key but whose code hash differs is
recomputed and logged as such. Every job ends with one JSON line (status, wall_s, items,
items_per_s, outputs, ...) on stdout and in <run>/runner.jsonl; done/<id>.json keeps it too.

Task contract (what makes kill/resume give identical output):
- all progress lives in ctx.state (JSON-serializable); call ctx.tick() after every chunk,
  and keep chunks to a few minutes so SIGTERM and the window end are honoured promptly;
- random numbers come only from ctx.rng(chunk_index), never from global state;
- files are written idempotently (ctx.write_bytes / ctx.write_json are atomic), so
  recomputing a chunk that was in flight when the job died overwrites it identically;
- compiled code runs through ctx.run(argv), which forwards SIGTERM to the child's
  process group; the child must checkpoint and exit 0 on SIGTERM.

Exit status (<run>/loops/runner/status.json, read by ops/watchdog.sh):
    stopped/window_end | stopped/queue_empty | stopped/signal | stopped/max_jobs | crashed
"""
from __future__ import annotations

import argparse
import fcntl
import hashlib
import importlib
import json
import os
import signal
import subprocess
import sys
import threading
import time
import traceback
from datetime import datetime, timedelta
from pathlib import Path

import numpy as np
import yaml

from program.codehash import code_hash

CHECKPOINT_MAX_S = 900
HEARTBEAT_S = 30
MAX_CRASHES = 3
STOP = threading.Event()


class Interrupted(Exception):
    """Raised by ctx.tick() after the checkpoint is saved, when a stop was requested."""


def now_iso() -> str:
    return datetime.now().astimezone().isoformat(timespec="seconds")


def atomic_write(path: Path, data: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_name(f".{path.name}.tmp{os.getpid()}")
    with open(tmp, "wb") as f:
        f.write(data)
        f.flush()
        os.fsync(f.fileno())
    os.replace(tmp, path)


def write_json(path: Path, obj) -> None:
    atomic_write(path, (json.dumps(obj, sort_keys=True, indent=1) + "\n").encode())


def params_key(task: str, params: dict, seed: int) -> str:
    blob = json.dumps({"task": task, "params": params, "seed": seed}, sort_keys=True)
    return hashlib.sha256(blob.encode()).hexdigest()[:12]


class Context:
    def __init__(self, root: Path, run: Path, raw: Path, job_id: str, manifest: dict, key: str,
                 ckpt: dict | None):
        self.root, self.job_id, self.key = root, job_id, key
        self.task = manifest["task"]
        self.params = manifest.get("params") or {}
        self.seed = int(manifest.get("seed", 0))
        self.checkpoint_s = min(float(manifest.get("checkpoint_s", 600)), CHECKPOINT_MAX_S)
        self.out_dir = root / "results" / self.task / key
        self.raw_dir = raw / self.task / key
        self.work_dir = run / "work" / key
        for d in (self.out_dir, self.raw_dir, self.work_dir):
            d.mkdir(parents=True, exist_ok=True)
            for stale in d.rglob(".*.tmp*"):  # left by a kill inside atomic_write
                stale.unlink()
        ckpt = ckpt or {}
        self.state: dict = ckpt.get("state", {})
        self.items: int = ckpt.get("items", 0)
        self.wall_prev: float = ckpt.get("wall_s", 0.0)
        self.t0 = time.monotonic()
        self.last_ckpt = self.t0
        self.child: subprocess.Popen | None = None
        self.log = open(self.work_dir / "job.log", "a", buffering=1)

    def wall(self) -> float:
        return self.wall_prev + time.monotonic() - self.t0

    def rng(self, chunk: int) -> np.random.Generator:
        """Counter-based stream: identical for a chunk however often the job is resumed."""
        return np.random.default_rng([self.seed, chunk])

    def add_items(self, k: int) -> None:
        self.items += k

    def checkpoint(self) -> None:
        write_json(self.work_dir / "checkpoint.json",
                   {"state": self.state, "items": self.items, "wall_s": self.wall(), "ts": now_iso()})
        self.last_ckpt = time.monotonic()

    def tick(self) -> None:
        if STOP.is_set():
            self.checkpoint()
            raise Interrupted
        if time.monotonic() - self.last_ckpt >= self.checkpoint_s:
            self.checkpoint()

    def write_bytes(self, path: Path, data: bytes) -> Path:
        atomic_write(path, data)
        return path

    def write_json(self, path: Path, obj) -> Path:
        write_json(path, obj)
        return path

    def run(self, argv: list[str], **kw) -> int:
        """Run compiled code in work_dir; SIGTERM is forwarded to its process group."""
        kw.setdefault("cwd", self.work_dir)
        kw.setdefault("stdout", self.log)
        kw.setdefault("stderr", subprocess.STDOUT)
        self.child = subprocess.Popen(argv, start_new_session=True, **kw)
        if STOP.is_set():
            os.killpg(self.child.pid, signal.SIGTERM)
        try:
            rc = self.child.wait()
        finally:
            self.child = None
        if rc != 0 and not STOP.is_set():
            raise subprocess.CalledProcessError(rc, argv)
        return rc


class Runner:
    def __init__(self, root: Path, run: Path, raw: Path, deadline: float | None, max_jobs: int | None):
        self.root, self.run, self.raw, self.deadline, self.max_jobs = root, run, raw, deadline, max_jobs
        self.jobs = root / "jobs"
        self.loop_dir = run / "loops" / "runner"
        self.loop_dir.mkdir(parents=True, exist_ok=True)
        self.code = code_hash()
        self.ctx: Context | None = None
        self.stop_reason = "signal"

    # -- supervision -----------------------------------------------------------------
    def status(self, status: str, reason: str = "") -> None:
        write_json(self.loop_dir / "status.json",
                   {"status": status, "reason": reason, "pid": os.getpid(), "ts": now_iso()})

    def request_stop(self, reason: str) -> None:
        if not STOP.is_set():
            self.stop_reason = reason
            STOP.set()
        ctx = self.ctx
        if ctx is not None and ctx.child is not None:
            try:
                os.killpg(ctx.child.pid, signal.SIGTERM)
            except ProcessLookupError:
                pass

    def monitor(self) -> None:
        hb = self.loop_dir / "heartbeat"
        while True:
            hb.touch()
            if self.deadline is not None and time.time() >= self.deadline:
                self.request_stop("window_end")
            wait = HEARTBEAT_S if self.deadline is None else max(0.2, min(HEARTBEAT_S, self.deadline - time.time()))
            time.sleep(wait)

    def emit(self, rec: dict) -> None:
        line = json.dumps(rec, sort_keys=True)
        print(line, flush=True)
        with open(self.run / "runner.jsonl", "a") as f:
            f.write(line + "\n")

    def note(self, msg: str) -> None:
        with open(self.run / "runner.log", "a") as f:
            f.write(f"{now_iso()} {msg}\n")

    # -- queue -------------------------------------------------------------------------
    def next_job(self) -> Path | None:
        for sub in ("running", "queue"):
            files = sorted((self.jobs / sub).glob("*.yaml"))
            if files:
                if sub == "running":
                    return files[0]
                dst = self.jobs / "running" / files[0].name
                os.rename(files[0], dst)
                return dst
        return None

    def finish(self, path: Path, rec: dict) -> None:
        done = self.jobs / "done"
        write_json(done / f"{path.stem}.json", rec)
        os.rename(path, done / path.name)

    def run_job(self, path: Path) -> dict:
        job_id = path.stem
        try:
            manifest = yaml.safe_load(path.read_text())
            task, params, seed = manifest["task"], manifest.get("params") or {}, int(manifest.get("seed", 0))
            pk = params_key(task, params, seed)
        except Exception as e:  # a malformed manifest is a job error, not a runner crash
            self.note(f"{job_id}: bad manifest: {type(e).__name__}: {e}")
            return {"job": job_id, "task": "?", "key": "-", "seed": None, "code_hash": self.code,
                    "status": "error", "error": f"bad manifest: {type(e).__name__}: {e}",
                    "wall_s": 0.0, "items": 0, "items_per_s": 0.0, "outputs": [], "ts": now_iso()}
        key = f"{pk}-{self.code[:8]}"
        base = {"job": job_id, "task": task, "key": key, "seed": seed, "code_hash": self.code}
        result_file = self.root / "results" / task / key / "result.json"
        if result_file.exists() and not manifest.get("force"):
            prev = json.loads(result_file.read_text())
            self.note(f"{job_id}: cache hit {key}, not recomputed")
            return {**base, "status": "cached", "wall_s": 0.0, "items": prev.get("items", 0),
                    "items_per_s": prev.get("items_per_s", 0.0), "outputs": prev.get("outputs", []), "ts": now_iso()}
        if result_file.exists():
            self.note(f"{job_id}: force=true, recomputing {key}")
        for old in (self.root / "results" / task).glob(f"{pk}-*/result.json"):
            if old.parent.name != key:
                self.note(f"{job_id}: params match {old.parent.name} but code hash changed; recomputing as {key}")
        for stale in (self.run / "work").glob(f"{pk}-*"):
            if stale.name != key and (stale / "checkpoint.json").exists():
                self.note(f"{job_id}: checkpoint {stale.name} is from other code; restarting from scratch")

        work = self.run / "work" / key
        ckpt_file, active, crashes_file = work / "checkpoint.json", work / "active", work / "crashes"
        work.mkdir(parents=True, exist_ok=True)
        crashes = int(crashes_file.read_text()) if crashes_file.exists() else 0
        if active.exists():
            crashes += 1
            crashes_file.write_text(str(crashes))
            self.note(f"{job_id}: previous attempt died uncleanly ({crashes}/{MAX_CRASHES})")
        if crashes >= MAX_CRASHES:
            return {**base, "status": "error", "error": f"died uncleanly {crashes} times",
                    "wall_s": 0.0, "items": 0, "items_per_s": 0.0, "outputs": [], "ts": now_iso()}
        ckpt = json.loads(ckpt_file.read_text()) if ckpt_file.exists() else None
        self.note(f"{job_id}: {'resume' if ckpt else 'start'} {key}")
        active.touch()
        ctx = self.ctx = Context(self.root, self.run, self.raw, job_id, manifest, key, ckpt)
        status, extra, outputs = "done", {}, []
        try:
            mod = importlib.import_module(f"program.tasks.{task}")
            ret = mod.run(ctx)
            outputs = sorted(str(Path(p).resolve().relative_to(self.root)) for p in (ret or []))
            ckpt_file.unlink(missing_ok=True)  # result.json is the record; force must start fresh
        except Interrupted:
            status = "interrupted"
        except Exception as e:  # a failing job must not take the queue down with it
            status = "error"
            extra = {"error": f"{type(e).__name__}: {e}"}
            ctx.log.write(traceback.format_exc())
        finally:
            self.ctx = None
            ctx.log.close()
            active.unlink(missing_ok=True)
        wall = ctx.wall()
        rec = {**base, **extra, "status": status, "wall_s": round(wall, 3), "items": ctx.items,
               "items_per_s": round(ctx.items / wall, 3) if wall > 0 else 0.0,
               "outputs": outputs, "ts": now_iso()}
        if status == "done":
            write_json(result_file, rec)
        return rec

    def main(self) -> int:
        lock = open(self.loop_dir / "lock", "w")
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            print(json.dumps({"status": "busy", "reason": "another runner holds the lock"}))
            return 0
        signal.signal(signal.SIGTERM, lambda *_: self.request_stop("signal"))
        signal.signal(signal.SIGINT, lambda *_: self.request_stop("signal"))
        self.status("running")
        threading.Thread(target=self.monitor, daemon=True).start()
        try:
            n = 0
            while not STOP.is_set():
                if self.deadline is not None and time.time() >= self.deadline:
                    self.request_stop("window_end")
                    break
                if self.max_jobs is not None and n >= self.max_jobs:
                    self.stop_reason = "max_jobs"
                    break
                path = self.next_job()
                if path is None:
                    self.stop_reason = "queue_empty"
                    break
                rec = self.run_job(path)
                self.emit(rec)
                n += 1
                if rec["status"] != "interrupted":
                    self.finish(path, rec)
            self.status("stopped", self.stop_reason)
            return 0
        except Exception:
            self.note("runner crashed:\n" + traceback.format_exc())
            self.status("crashed", traceback.format_exc().strip().splitlines()[-1][:200])
            return 1


def parse_until(s: str) -> float:
    """Epoch seconds, or HH:MM meaning its next occurrence."""
    if ":" not in s:
        return float(s)
    hh, mm = map(int, s.split(":"))
    now = datetime.now()
    t = now.replace(hour=hh, minute=mm, second=0, microsecond=0)
    if t <= now:
        t += timedelta(days=1)
    return t.timestamp()


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[2])
    ap.add_argument("--until", help="stop at this time (HH:MM or epoch seconds)")
    ap.add_argument("--run", type=Path, default=os.environ.get("PROGRAM_RUN") or None,
                    help="runtime directory (default $PROGRAM_RUN, else <root>/run)")
    ap.add_argument("--raw", type=Path, default=os.environ.get("PROGRAM_RAW") or None,
                    help="bulk output directory (default $PROGRAM_RAW, else <root>/results/raw)")
    ap.add_argument("--max-jobs", type=int)
    a = ap.parse_args(argv)
    deadline = parse_until(a.until) if a.until else None
    root = a.root.resolve()
    run, raw = (a.run or root / "run").resolve(), (a.raw or root / "results" / "raw").resolve()
    return Runner(root, run, raw, deadline, a.max_jobs).main()


if __name__ == "__main__":
    sys.exit(main())
