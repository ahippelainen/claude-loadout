#!/usr/bin/env bash
# Copy this kit into a project: scaffold.sh <project-root> [<name>]
# Substitutes @NAME@ everywhere and the paths and window in ops/crontab.txt (scripts find their
# root at run time; the prompts are substituted per round). gitignore becomes .gitignore, merged
# line by line into an existing one. Never overwrites a file; idempotent. Git is optional.
# Read from the environment at scaffold time (defaults in brackets): PROGRAM_RUN [<root>/run],
# PROGRAM_RAW [<root>/results/raw], PROGRAM_VENV [<root>/venv], PROGRAM_WINDOW [22:00-06:30].
set -euo pipefail
KIT=$(cd "$(dirname "$0")" && pwd)
(( $# >= 1 && $# <= 2 )) || { echo "usage: $0 <project-root> [<name>]" >&2; exit 2; }
WINDOW=${PROGRAM_WINDOW:-22:00-06:30}
[[ $WINDOW =~ ^([01][0-9]|2[0-3]):[0-5][0-9]-([01][0-9]|2[0-3]):[0-5][0-9]$ ]] \
    || { echo "PROGRAM_WINDOW must be HH:MM-HH:MM, got $WINDOW" >&2; exit 2; }
mkdir -p "$1"
DEST=$(cd "$1" && pwd)
NAME=${2:-$(basename "$DEST")}
RUN=${PROGRAM_RUN:-$DEST/run}
RAW=${PROGRAM_RAW:-$DEST/results/raw}
VENV=${PROGRAM_VENV:-$DEST/venv}
WIN_H=$((10#${WINDOW:0:2})); WIN_M=$((10#${WINDOW:3:2}))
[[ $DEST == "$KIT" || $DEST == "$KIT"/* ]] && { echo "refusing to scaffold into the kit itself" >&2; exit 2; }
esc() { printf '%s' "$1" | sed 's/[\\|&]/\\&/g'; }

copied=(); skipped=(); merged=0
while IFS= read -r -d '' f; do
    rel=${f#./}
    dst=$rel; [[ $rel == gitignore ]] && dst=.gitignore
    if [[ $dst == .gitignore && -e $DEST/.gitignore ]]; then
        while IFS= read -r line; do
            [[ -z $line ]] && continue
            grep -qxF -- "$line" "$DEST/.gitignore" || { echo "$line" >> "$DEST/.gitignore"; merged=$((merged + 1)); }
        done < "$KIT/gitignore"
        (( merged )) || skipped+=(".gitignore (all lines present)")
        continue
    fi
    if [[ -e $DEST/$dst ]]; then skipped+=("$dst"); continue; fi
    mkdir -p "$(dirname "$DEST/$dst")"
    cp -p "$KIT/$rel" "$DEST/$dst"
    if grep -q '@NAME@' "$DEST/$dst"; then sed -i "s|@NAME@|$(esc "$NAME")|g" "$DEST/$dst"; fi
    if [[ $dst == ops/crontab.txt ]]; then
        sed -i "s|@ROOT@|$(esc "$DEST")|g; s|@RUN@|$(esc "$RUN")|g; s|@RAW@|$(esc "$RAW")|g; s|@VENV@|$(esc "$VENV")|g;
                s|@WINDOW@|$WINDOW|g; s|@WIN_H@|$WIN_H|g; s|@WIN_M@|$WIN_M|g" "$DEST/$dst"
    fi
    [[ $dst == *.sh ]] && chmod +x "$DEST/$dst"
    copied+=("$dst")
done < <(cd "$KIT" && find . \( -name __pycache__ -o -name venv \) -prune -o -type f ! -name scaffold.sh ! -name '*.pyc' -print0 | sort -z)
mkdir -p "$RUN"

echo "scaffolded $NAME into $DEST"
echo "copied ${#copied[@]} file(s)${copied[*]:+:}"; for f in "${copied[@]}"; do echo "  + $f"; done
(( merged )) && echo "merged $merged line(s) into .gitignore"
echo "skipped ${#skipped[@]} existing file(s)${skipped[*]:+:}"; for f in "${skipped[@]}"; do echo "  = $f"; done
cat <<EOF

next steps:
  1. cd "$DEST" && make venv && make smoke          (then: make e2e E2E_MIN=1)
     (if you set PROGRAM_VENV, export it in that shell too, so make uses the same venv)
  2. write your tasks as src/program/tasks/<task>.py (contract: src/program/runner.py, example.py)
  3. fill @TOPIC@ @ARXIV_QUERIES@ @WATCH@ @TARGET_FILES@ in ops/prompts/litsweep.txt
  4. agent loops and the lit sweep stay disabled until you create ops/agent-loops.enabled with
     email=<account> and org_id=<org> lines matching \`claude auth status --json\`
  5. review ops/crontab.txt, then: crontab -l | cat - ops/crontab.txt | crontab -
  6. the reaper only logs (DRY) until you touch ops/reaper.live
EOF
git -C "$DEST" rev-parse --is-inside-work-tree >/dev/null 2>&1 \
    || echo "note: $DEST is not a git work tree; nightly.sh and litsweep.sh will skip commit and push."
if [[ $DEST == "$HOME/Dropbox" || $DEST == "$HOME/Dropbox"/* || $DEST == "$HOME"/Dropbox\ * ]] \
   && [[ $RUN == "$DEST"/* || $RAW == "$DEST"/* || $VENV == "$DEST"/* ]]; then
    st="~/.local/state/$NAME"
    echo "note: $DEST is in Dropbox; keep runtime files, bulk output and the venv out of the synced"
    echo "      folder. Regenerate the crontab with them outside:"
    echo "  rm \"$DEST/ops/crontab.txt\" && PROGRAM_RUN=$st/run PROGRAM_RAW=$st/raw PROGRAM_VENV=$st/venv bash \"$KIT/scaffold.sh\" \"$DEST\" $NAME"
    echo "      and export the same three variables (e.g. in ~/.profile) for make and manual runs."
fi
