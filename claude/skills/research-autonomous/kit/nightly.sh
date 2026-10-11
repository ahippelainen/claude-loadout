#!/usr/bin/env bash
# Nightly pipeline: run the job queue at low priority until the end of the compute window
# $PROGRAM_WINDOW (default 22:00-06:30, the same value the watchdog and the crontab use), then
# write digests/<night>.md, commit compact results by explicit pathspec, and push only if this
# repo is `free` in the push policy. In a root that is not a git work tree the commit and push
# are skipped. Runtime files go to $PROGRAM_RUN (default <root>/run), bulk output to
# $PROGRAM_RAW (default <root>/results/raw), the venv is $PROGRAM_VENV (default <root>/venv).
# Usage: nightly.sh [--test-window MINUTES] [--end HH:MM] [--plan]
# --plan prints the computed night, since and end and exits; PROGRAM_NOW (epoch) fakes the
# clock for it (tests).
# Restartable: the watchdog may start it again inside the window; the digest then covers
# the whole night and is rewritten. Sentinel $PROGRAM_RUN/loops/runner/STOP disables it.
set -uo pipefail
ROOT=$(cd "$(dirname "$0")" && pwd)
RUN=${PROGRAM_RUN:-$ROOT/run}
RAW=${PROGRAM_RAW:-$ROOT/results/raw}
VENV=${PROGRAM_VENV:-$ROOT/venv}
WINDOW=${PROGRAM_WINDOW:-22:00-06:30}
NAME=${PROGRAM_NAME:-$(basename "$ROOT")}
POLICY=${PROGRAM_PUSH_POLICY:-$HOME/Git/dotfiles/claude/push-policy}
PY=$VENV/bin/python
L=$RUN/loops/runner
export PROGRAM_RUN=$RUN PROGRAM_RAW=$RAW PROGRAM_VENV=$VENV PROGRAM_WINDOW=$WINDOW
log() { echo "$(date '+%F %T') nightly $*" >> "$RUN/nightly.log"; }

START_HM=${WINDOW%-*}; END_HM=${WINDOW#*-}; TEST_MIN=; PLAN=
while (( $# )); do
    case $1 in
        --test-window) TEST_MIN=$2; shift 2 ;;
        --end) END_HM=$2; shift 2 ;;
        --plan) PLAN=1; shift ;;
        *) echo "unknown argument $1" >&2; exit 2 ;;
    esac
done

now=${PROGRAM_NOW:-$(date +%s)}
today=$(date -d @"$now" +%F)
if [[ -n $TEST_MIN ]]; then
    night=$today; since=$now; end=$(( now + TEST_MIN * 60 ))
else
    mins() { local h=${1%:*} m=${1#*:}; echo $(( 10#$h * 60 + 10#$m )); }
    s=$(mins "$START_HM"); e=$(mins "$END_HM"); n=$(mins "$(date -d @"$now" +%H:%M)")
    # in a window across midnight, a restart after midnight belongs to the night that started
    # the previous evening
    if (( s > e && n < e )); then night=$(date -d "$today -1 day" +%F); else night=$today; fi
    since=$(date -d "$night $START_HM" +%s); (( since > now )) && since=$now
    end=$(date -d "$today $END_HM" +%s); (( end <= now )) && end=$(date -d "$(date -d "$today +1 day" +%F) $END_HM" +%s)
fi
[[ -n $PLAN ]] && { echo "night=$night since=$since end=$end"; exit 0; }

mkdir -p "$L"
[[ -e $L/STOP ]] && { log "skip STOP sentinel present"; exit 0; }
exec 9>"$RUN/nightly.lock"
flock -n 9 || { log "skip another nightly holds the lock"; exit 0; }
log "start night=$night end=$(date -d @"$end" '+%F %T') pid=$$"

INH=()
if timeout -k 5 10 systemd-inhibit --what=sleep:idle --who="$NAME" --why=probe --mode=block true 2>/dev/null; then
    INH=(systemd-inhibit --what=sleep:idle --who="$NAME-nightly" --why="nightly compute" --mode=block)
    log "inhibit ok"
else
    log "inhibit unavailable (polkit refused); running without sleep inhibitor"
fi

"$ROOT/ops/thermal_governor.sh" $$ 9>&- &
GOV=$!
# timeout is outermost: it signals its whole process group, so a TERM forwarded to it
# reaches the runner (which checkpoints and exits) whatever systemd-inhibit does.
timeout -k 60 $(( end - now + 300 )) "${INH[@]}" nice -n 15 ionice -c2 -n7 \
    env PYTHONPATH="$ROOT/src" "$PY" -m program.runner --root "$ROOT" --run "$RUN" --raw "$RAW" --until "$end" >> "$RUN/runner.out" 2>&1 &
RP=$!
trap 'kill -TERM "$RP" 2>/dev/null' TERM INT
wait "$RP"; rc=$?
while kill -0 "$RP" 2>/dev/null; do wait "$RP"; rc=$?; done
trap - TERM INT
flock -w 180 "$L/lock" true || log "runner-lock still held 180 s after exit"
kill "$GOV" 2>/dev/null; wait "$GOV" 2>/dev/null
log "runner-exit rc=$rc status=$(tr -d '\n' < "$L/status.json" 2>/dev/null | grep -oP '"status": "\K[^"]+')"

PYTHONPATH="$ROOT/src" "$PY" -m program.digest --root "$ROOT" --run "$RUN" --night "$night" --since "$since" >/dev/null \
    || log "digest-failed"

GITDIR=$(git -C "$ROOT" rev-parse --absolute-git-dir 2>/dev/null)
git_busy() {  # an in-progress git operation in this repo: never commit through it
    [[ -e $GITDIR/index.lock || -e $GITDIR/MERGE_HEAD || -e $GITDIR/CHERRY_PICK_HEAD || -e $GITDIR/REVERT_HEAD \
       || -d $GITDIR/rebase-merge || -d $GITDIR/rebase-apply ]]
}

commit() {
    cd "$ROOT" || return 1
    if [[ -z $GITDIR ]]; then log "no git: commit skipped"; return 1; fi
    local i
    for i in $(seq 30); do git_busy || break; sleep 10; done
    if git_busy; then
        if [[ -e $GITDIR/index.lock ]] && ! pgrep -u "$(id -u)" -x git >/dev/null; then
            log "git-lock stale index.lock ($(( $(date +%s) - $(stat -c %Y "$GITDIR/index.lock") )) s old), not removed; commit skipped"
        else
            log "git-busy git operation in progress for 5 min; commit skipped"
        fi
        return 1
    fi
    local paths=() dels=() f p
    # a path git knows nothing about would make the pathspec-limited commit fail
    for p in results digests jobs/done; do
        [[ -e $p ]] && git add -- "$p" && [[ -n $(git ls-files -- "$p" | head -1) ]] && paths+=("$p")
    done
    # a manifest deleted from queue/ is committed only once its job has reached done/
    while IFS= read -r f; do
        [[ -e jobs/done/$(basename "$f") ]] && dels+=("$f")
    done < <(git ls-files --deleted -- jobs/queue)
    (( ${#dels[@]} )) && git rm -q --cached -- "${dels[@]}"
    if (( ${#paths[@]} + ${#dels[@]} == 0 )) || git diff --cached --quiet -- "${paths[@]}" "${dels[@]}"; then
        log "commit nothing to commit"; return 0
    fi
    local phase
    phase=$(grep -m1 -oP '^Phase:\s*\K\S+' STATE.md 2>/dev/null || echo "?")
    if git commit -q -m "chore: [$phase][nightly] digest $night" -- "${paths[@]}" "${dels[@]}"; then
        log "commit ok $(git rev-parse --short HEAD)"
    else
        log "commit failed"; return 1
    fi
}

push() {
    cd "$ROOT" || return 1
    if ! grep -qE "^$ROOT[[:space:]]+free([[:space:]]|$)" "$POLICY" 2>/dev/null; then
        log "push skipped: $ROOT is not free in $POLICY"; return 0
    fi
    if timeout -k 10 120 git push -q origin HEAD 2>> "$RUN/nightly.log"; then
        log "push ok"
    else
        log "push failed"
    fi
}

commit && push
log "end"
exit "$rc"
