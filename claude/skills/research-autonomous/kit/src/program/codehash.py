"""Content hash of the library source tree, used in result cache keys."""
from __future__ import annotations

import hashlib
import os
from pathlib import Path

SRC = Path(__file__).resolve().parents[1]
_SKIP_DIRS = {"__pycache__", "build", "target", ".pytest_cache"}
_SKIP_SUFFIXES = {".pyc", ".o", ".so", ".a"}


def code_hash(src: Path = SRC) -> str:
    """sha256 over (relative path, content) of every source file under src/, sorted.

    Build products are excluded, so rebuilding compiled code from unchanged sources keeps
    the hash; any source edit (committed or not) changes it.
    """
    h = hashlib.sha256()
    for dirpath, dirnames, filenames in os.walk(src):
        dirnames[:] = sorted(d for d in dirnames if d not in _SKIP_DIRS)
        for name in sorted(filenames):
            p = Path(dirpath, name)
            if p.suffix in _SKIP_SUFFIXES:
                continue
            h.update(str(p.relative_to(src)).encode() + b"\0")
            h.update(p.read_bytes() + b"\0")
    return h.hexdigest()
