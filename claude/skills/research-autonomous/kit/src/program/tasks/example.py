"""Example task demonstrating the runner contract (see program.runner): all progress in ctx.state,
ctx.tick() after every chunk, random numbers only from ctx.rng(chunk), atomic idempotent writes.
Also the task the runner tests and tests/nightly_e2e.sh use.

params: n_items (int), chunk (int), sleep_s (float, per chunk, to make runs killable).
Outputs: raw chunk files in raw_dir and summary.json (sha256 over all chunks) in out_dir.
"""
from __future__ import annotations

import hashlib
import time

import numpy as np


def run(ctx) -> list:
    n, chunk = int(ctx.params["n_items"]), int(ctx.params["chunk"])
    sleep_s = float(ctx.params.get("sleep_s", 0.0))
    nchunks = -(-n // chunk)
    st = ctx.state
    st.setdefault("next", 0)
    while st["next"] < nchunks:
        i = st["next"]
        x = ctx.rng(i).integers(0, 2**32, size=min(chunk, n - i * chunk), dtype="u8")
        ctx.write_bytes(ctx.raw_dir / f"chunk_{i:05d}.bin", x.tobytes())
        st["next"] = i + 1
        ctx.add_items(x.size)
        if sleep_s:
            time.sleep(sleep_s)
        ctx.tick()
    h = hashlib.sha256()
    total = 0
    for i in range(nchunks):
        b = (ctx.raw_dir / f"chunk_{i:05d}.bin").read_bytes()
        h.update(b)
        total += int(np.frombuffer(b, dtype="u8").sum())  # < 2^32 per item, no overflow below 2^32 items
    out = ctx.write_json(ctx.out_dir / "summary.json",
                         {"n_items": n, "chunks": nchunks, "sha256": h.hexdigest(), "sum": total})
    return [out]
