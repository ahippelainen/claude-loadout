#!/usr/bin/env bash
# Hourly supervisor for the compute runner and headless agent loops (ops/loops.txt).
# Per loop, $PROGRAM_RUN/loops/<name>/ holds: heartbeat (mtime, touched by the live loop), status.json
# (written by the loop: running | crashed | usage_exhausted | deferred | stopped, plus stuck from here),
# lock (flock held while the loop runs: single instance) and STOP (sentinel: never restart).
# Responses: crashed (or died without a status) -> restart, at most N per loop per day, then
# stuck; usage_exhausted, deferred (interactive orchestrator active) -> retry at every check,
# not counted against N; STOP present -> never. An agent loop that is `stopped` but whose STOP
# the owner deleted is resumed (not counted); a stopped compute loop restarts only on new work.
# Nothing is restarted during a git operation (index.lock, merge, rebase, cherry-pick); in a
# root that is not a git work tree that check is a no-op.
# One line per event in $PROGRAM_RUN/watchdog.log: "<date> <time> <loop> <event> <detail>".
set -uo pipefail
ROOT=${PROGRAM_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}
RUN=${PROGRAM_RUN:-$ROOT/run}
GITDIR=${PROGRAM_GIT_DIR-$(git -C "$ROOT" rev-parse --absolute-git-dir 2>/dev/null)}
JOBS=${PROGRAM_JOBS:-$ROOT/jobs}
LOOPS=${PROGRAM_LOOPS:-$ROOT/ops/loops.txt}
ENABLE=${PROGRAM_AGENT_ENABLE:-$ROOT/ops/agent-loops.enabled}
N=${PROGRAM_RESTART_BUDGET:-6}
HB_MAX=${PROGRAM_HB_MAX:-900}
WINDOW=${PROGRAM_WINDOW:-22:00-06:30}
LOG=$RUN/watchdog.log
export PROGRAM_RUN=$RUN
mkdir -p "$RUN/loops"
ev() { echo "$(date '+%F %T') $1 $2${3:+ $3}" >> "$LOG"; }
exec 8>"$RUN/watchdog.lock"
flock -n 8 || exit 0
touch "$RUN/watchdog.last"

in_window() {
    local s=${WINDOW%-*} e=${WINDOW#*-} now
    s=$((10#${s/:/})); e=$((10#${e/:/})); now=$((10#$(date +%H%M)))
    if (( s <= e )); then (( now >= s && now < e )); else (( now >= s || now < e )); fi
}
work_available() { compgen -G "$JOBS/queue/*.yaml" >/dev/null || compgen -G "$JOBS/running/*.yaml" >/dev/null; }
git_busy() {
    [[ -n $GITDIR ]] || return 1
    [[ -e $GITDIR/index.lock || -e $GITDIR/MERGE_HEAD || -e $GITDIR/CHERRY_PICK_HEAD \
       || -d $GITDIR/rebase-merge || -d $GITDIR/rebase-apply ]]
}
field() { grep -oP "\"$2\": \"\\K[^\"]*" "$1/status.json" 2>/dev/null | head -1; }
set_status() {
    printf '{"status": "%s", "reason": "%s", "ts": "%s"}\n' "$2" "$3" "$(date -Iseconds)" \
        > "$1/status.json.tmp" && mv "$1/status.json.tmp" "$1/status.json"
}
restarts_today() { local c; c=$(grep -cE "^$(date +%F) [0-9:]{8} $1 restart " "$LOG" 2>/dev/null); echo "${c:-0}"; }

check() {
    local name=$1 kind=$2 d=$RUN/loops/$1 st reason counted=0 k age
    shift 2
    mkdir -p "$d"
    [[ -e $d/STOP ]] && return
    st=$(field "$d" status); st=${st:-none}
    [[ $st == stuck ]] && return
    if ! flock -n "$d/lock" true; then
        age=$(( $(date +%s) - $(stat -c %Y "$d/heartbeat" 2>/dev/null || echo 0) ))
        (( age > HB_MAX )) && ev "$name" stale-heartbeat "age=${age}s (alive per lock; bounded by its timeout)"
        return
    fi
    case $st in
        running) reason="died without writing a status"; counted=1 ;;
        crashed) reason="crashed: $(field "$d" reason)"; counted=1 ;;
        usage_exhausted) reason="usage retry" ;;
        deferred) reason="deferred retry" ;;
        stopped)
            if [[ $kind == agent ]]; then
                reason="owner removed STOP"
            else
                [[ $(field "$d" reason) == queue_empty ]] || return
                reason="new work after queue_empty"
            fi ;;
        none) [[ $kind == agent ]] || return; reason="first start" ;;
        *) ev "$name" unknown-status "$st"; return ;;
    esac
    if [[ $kind == compute ]]; then in_window && work_available || return; fi
    if git_busy; then ev "$name" restart-deferred "git operation in progress"; return; fi
    if (( counted )); then
        k=$(restarts_today "$name")
        if (( k >= N )); then
            set_status "$d" stuck "restart budget $N/day exhausted"
            ev "$name" stuck "after $k restarts today; last: $reason"
            return
        fi
        ev "$name" restart "$((k + 1))/$N $reason"
    elif [[ $st == usage_exhausted ]]; then
        ev "$name" usage-retry "$(field "$d" reason)"
    elif [[ $st == deferred ]]; then
        ev "$name" deferred-retry "$(field "$d" reason)"
    elif [[ $st == stopped && $kind == agent ]]; then
        ev "$name" resume "$reason (was: $(field "$d" reason))"
    else
        ev "$name" start "$reason"
    fi
    local cmd=$1; shift
    [[ $cmd == /* ]] || cmd=$ROOT/$cmd
    # 8>&-: the loop must not inherit the watchdog's own lock
    (cd "$ROOT" && setsid nohup "$cmd" "$@" >/dev/null 2>&1 < /dev/null 8>&- &)
}

while read -r name kind launcher; do
    [[ -z $name || $name == \#* ]] && continue
    [[ $kind == agent && ! -e $ENABLE ]] && continue
    # shellcheck disable=SC2086
    check "$name" "$kind" $launcher
done < "$LOOPS"

if [[ -e $ROOT/ops/reaper.live ]]; then "$ROOT/ops/reaper.sh"; else DRY=1 "$ROOT/ops/reaper.sh"; fi
