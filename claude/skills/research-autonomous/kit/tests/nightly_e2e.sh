#!/usr/bin/env bash
# End-to-end nightly test in throwaway copies of this project; nothing touches the real
# digests/, jobs/, run/ or remote. Usage: tests/nightly_e2e.sh [MINUTES] (default 5)
# 1. git: a fresh repo with a local bare origin and its own push policy runs nightly.sh with a
#    MINUTES test window; checks the digest, the pathspec-limited commit and the push.
# 2. no git: a plain copy with PROGRAM_RUN and PROGRAM_RAW outside it; checks the digest, that
#    commit and push are skipped, and that no runtime or bulk file lands inside the project.
# Both use the venv $PROGRAM_VENV (default <project>/venv).
set -euo pipefail
SRC=$(cd "$(dirname "$0")/.." && pwd)
MIN=${1:-5}
NAME=${PROGRAM_NAME:-$(basename "$SRC")}
export PROGRAM_VENV=${PROGRAM_VENV:-$SRC/venv}
unset PROGRAM_RUN PROGRAM_RAW PROGRAM_WINDOW
T=$(mktemp -d "${TMPDIR:-/tmp}/$NAME-nightly-e2e.XXXXXX")
trap 'rm -rf "$T"' EXIT
fail() { echo "FAIL: $*"; exit 1; }
copy() {
    mkdir -p "$1"
    rsync -a --exclude .git --exclude venv --exclude run --exclude lit/pdf --exclude 'jobs/*/*.yaml' \
          --exclude 'jobs/done/*.json' --exclude 'results/*/' --exclude 'digests/*.md' "$SRC/" "$1/"
    mkdir -p "$1/jobs/queue" "$1/jobs/running" "$1/jobs/done" "$1/lit"
    [[ -f $1/STATE.md ]] || echo "Phase: E2E" > "$1/STATE.md"
}

echo "=== 1. git repo, ${MIN}-minute window"
git init -q --bare "$T/origin.git"
R=$T/repo
copy "$R"
cd "$R"
git init -q && git remote add origin "$T/origin.git"
git add -A && git commit -q -m "test: fixture snapshot" && git push -q origin HEAD
printf 'task: example\nparams: {n_items: 200, chunk: 20}\n' > jobs/queue/a_short.yaml
printf 'task: example\nparams: {n_items: 1000000, chunk: 100, sleep_s: 0.05}\ncheckpoint_s: 60\n' > jobs/queue/b_long.yaml
git add jobs/queue && git commit -q -m "test: queue two jobs" && git push -q origin HEAD
echo "interactive edit" >> STATE.md                       # must NOT be committed by nightly
echo "staged elsewhere" > lit/staged_by_other_session.txt && git add lit/staged_by_other_session.txt
echo "$R free" > "$T/policy"

t0=$(date +%s)
PROGRAM_PUSH_POLICY=$T/policy timeout -k 10 $(( MIN * 60 + 600 )) ./nightly.sh --test-window "$MIN"
echo "nightly.sh wall $(( $(date +%s) - t0 )) s"

D=digests/$(date +%F).md
[[ -f $D ]] || fail "no digest"
(( $(wc -l < "$D") <= 80 )) || fail "digest over 80 lines"
msg=$(git log -1 --format=%s)
[[ $msg == "chore: ["*"][nightly] digest $(date +%F)" ]] || fail "unexpected commit: $msg"
files=$(git show --name-only --no-renames --format= HEAD)
grep -qvE '^(results|digests|jobs/done|jobs/queue)/' <<< "$files" && fail "commit touched other paths: $files"
grep -qx 'jobs/queue/a_short.yaml' <<< "$files" || fail "queue deletion of finished job not committed"
grep -q 'b_long' <<< "$files" && fail "interrupted job leaked into the commit"
[[ -f jobs/running/b_long.yaml ]] || fail "interrupted job not left in running/"
git diff --quiet -- STATE.md && fail "interactive edit to STATE.md vanished"
git diff --cached --name-only | grep -qx lit/staged_by_other_session.txt || fail "other session's staged file lost"
[[ $(git -C "$T/origin.git" rev-parse HEAD) == $(git rev-parse HEAD) ]] || fail "push did not reach origin"
echo "--- digest ($(wc -l < "$D") lines)"; cat "$D"
echo "--- commit"; git log -1 --format='%h %s' && git show --stat --format= HEAD | tail -8
echo "--- nightly.log"; tail -8 run/nightly.log

echo "=== 2. no git, PROGRAM_RUN and PROGRAM_RAW outside the project"
P=$T/plain
copy "$P"
cd "$P"
printf 'task: example\nparams: {n_items: 200, chunk: 20}\n' > jobs/queue/a_short.yaml
echo "$P free" > "$T/policy"
PROGRAM_RUN=$T/plain-run PROGRAM_RAW=$T/plain-raw PROGRAM_PUSH_POLICY=$T/policy timeout -k 10 $(( MIN * 60 + 600 )) ./nightly.sh --test-window "$MIN"
git -C "$P" rev-parse --is-inside-work-tree >/dev/null 2>&1 && fail "fixture is unexpectedly inside a git work tree"
[[ -f digests/$(date +%F).md ]] || fail "no digest (no git)"
[[ -f jobs/done/a_short.json ]] || fail "job did not finish (no git)"
grep -q '"status": "done"' jobs/done/a_short.json || fail "job not done (no git)"
grep -q 'no git: commit skipped' "$T/plain-run/nightly.log" || fail "no 'no git' log line"
grep -q 'push' "$T/plain-run/nightly.log" && fail "push attempted without git"
[[ -e run ]] && fail "runtime files written inside the project despite PROGRAM_RUN"
[[ -e results/raw ]] && fail "bulk output written inside the project despite PROGRAM_RAW"
compgen -G "$T/plain-raw/example/*/chunk_*.bin" >/dev/null || fail "bulk output missing in PROGRAM_RAW"
[[ -f $T/plain-run/runner.jsonl && -f $T/plain-run/loops/runner/status.json ]] || fail "runtime files missing in PROGRAM_RUN"
echo "--- nightly.log"; tail -5 "$T/plain-run/nightly.log"
echo "PASS"
