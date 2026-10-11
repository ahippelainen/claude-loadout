#!/usr/bin/env python3
# PreToolUse (Edit|Write): while a loop runs, refuse edits to the files it is judged by. A loop lists its tests,
# reference values and tolerance files, one path per line (relative to the project or absolute, globs allowed),
# in LOOP/protected.txt; the file is looked up from the edited path upwards. Without that file this hook does nothing.
import fnmatch, json, os, sys
from pathlib import Path

data = json.load(sys.stdin)
target = data.get("tool_input", {}).get("file_path")
if not target:
    sys.exit(0)
path = Path(os.path.realpath(target))

for root in [path.parent, *path.parents]:
    listing = root / "LOOP" / "protected.txt"
    if listing.exists():
        break
else:
    sys.exit(0)

if path == listing.resolve():
    sys.exit(0)
for line in listing.read_text().splitlines():
    pattern = line.strip()
    if not pattern or pattern.startswith("#"):
        continue
    full = pattern if os.path.isabs(pattern) else str(root / pattern)
    if fnmatch.fnmatch(str(path), full) or str(path).startswith(full.rstrip("/") + "/"):
        print(f"Protected during the loop: {path} matches '{pattern}' in {listing}. Tests, reference values and "
              "tolerances are not changed while the loop runs; if one is wrong, stop and report it to the author.",
              file=sys.stderr)
        sys.exit(2)
