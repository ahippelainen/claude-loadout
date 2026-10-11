"""nightly.sh window arithmetic (--plan with a faked clock): PROGRAM_WINDOW sets start and end."""
from __future__ import annotations

import os
import subprocess
from datetime import datetime
from pathlib import Path

import pytest

NIGHTLY = Path(__file__).resolve().parents[1] / "nightly.sh"


def ts(s: str) -> int:
    return int(datetime.strptime(s, "%Y-%m-%d %H:%M").timestamp())


def plan(tmp_path: Path, now: str, *args: str, window: str | None = None) -> dict[str, str]:
    env = {k: v for k, v in os.environ.items() if not k.startswith("PROGRAM_")}
    env |= {"PROGRAM_RUN": str(tmp_path / "run"), "PROGRAM_NOW": str(ts(now))}
    if window:
        env["PROGRAM_WINDOW"] = window
    out = subprocess.run([str(NIGHTLY), "--plan", *args], env=env, capture_output=True, text=True,
                         check=True, timeout=30).stdout
    return dict(kv.split("=") for kv in out.split())


@pytest.mark.parametrize("now,window,night,since,end", [
    ("2026-10-11 22:00", None, "2026-10-11", "2026-10-11 22:00", "2026-10-12 06:30"),
    ("2026-10-12 02:00", None, "2026-10-11", "2026-10-11 22:00", "2026-10-12 06:30"),  # watchdog restart
    ("2026-10-11 15:00", None, "2026-10-11", "2026-10-11 15:00", "2026-10-12 06:30"),  # manual daytime run
    ("2026-10-11 20:00", "20:00-04:00", "2026-10-11", "2026-10-11 20:00", "2026-10-12 04:00"),
    ("2026-10-12 03:00", "20:00-04:00", "2026-10-11", "2026-10-11 20:00", "2026-10-12 04:00"),
    ("2026-10-11 13:00", "13:00-17:00", "2026-10-11", "2026-10-11 13:00", "2026-10-11 17:00"),
])
def test_window(tmp_path, now, window, night, since, end):
    p = plan(tmp_path, now, window=window)
    assert p == {"night": night, "since": str(ts(since)), "end": str(ts(end))}
    assert not (tmp_path / "run" / "loops").exists()  # --plan has no side effects


def test_end_flag_overrides_window_end(tmp_path):
    assert plan(tmp_path, "2026-10-11 22:00", "--end", "05:00")["end"] == str(ts("2026-10-12 05:00"))
