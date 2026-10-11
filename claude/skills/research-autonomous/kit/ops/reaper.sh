#!/usr/bin/env bash
# Stray-process reaper; one pass per call (the hourly watchdog calls it). A process is OURS
# only if it has a `timeout` ancestor (agent commands are wrapped in timeout) AND its cwd is
# inside this repo, so other projects on a shared host and editor processes are never
# touched. The nightly runner and loop scripts, and everything under them, are exempt.
# Rules: age > LIMIT s; stopped (state T) > 1800 s; agent shell wait-loop > LOOPLIM s.
# Orphans of a headless round: a process that carries PROGRAM_AGENT_ROUND in its environment
# (set by ops/agent_loop.sh for each round) but has lost its round, i.e. has neither a timeout
# nor an exempt ancestor any more, with cwd inside this repo: age > LIMIT s or stopped > 1800 s.
# DRY=1 only logs WOULD-kill lines (the watchdog uses DRY unless ops/reaper.live exists).
LIMIT=${1:-10800}; LOOPLIM=${2:-1200}
ROOT=${PROGRAM_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}
RUN=${PROGRAM_RUN:-$ROOT/run}
LOG=$RUN/reaper.log
mkdir -p "$RUN"

declare -A PPID_OF COMM_OF ARGS_OF
snapshot=$(ps -u "$(id -u)" -o pid=,ppid=,etimes=,stat=,comm=,args=)
while read -r pid ppid _ _ comm args; do
    PPID_OF[$pid]=$ppid; COMM_OF[$pid]=$comm; ARGS_OF[$pid]=$args
done <<< "$snapshot"

ancestry() {  # 0 exempt ancestor, 1 timeout ancestor (and no exempt one), 2 neither (one ps snapshot)
    local p=${PPID_OF[$1]:-0} t=2
    while [[ -n ${COMM_OF[$p]:-} ]]; do
        case ${ARGS_OF[$p]} in *"-m program.runner"*|*"$ROOT/nightly.sh"*|*"$ROOT/ops/agent_loop.sh"*|*"$ROOT/ops/watchdog.sh"*) echo 0; return ;; esac
        [[ ${COMM_OF[$p]} == timeout ]] && t=1
        p=${PPID_OF[$p]:-0}
    done
    echo "$t"
}
reap() {  # pid reason args
    if [[ ${DRY:-0} == 1 ]]; then echo "$(date '+%F %T') WOULD kill pid=$1 [$2] ${3:0:160}" >> "$LOG"; return; fi
    echo "$(date '+%F %T') kill pid=$1 [$2] ${3:0:160}" >> "$LOG"
    kill -TERM "$1" 2>/dev/null; sleep 3; kill -KILL "$1" 2>/dev/null
}

while read -r pid _ et stat comm args; do
    [[ $pid == "$$" ]] && continue
    cwd=$(readlink "/proc/$pid/cwd" 2>/dev/null) || continue
    [[ $cwd == "$ROOT" || $cwd == "$ROOT"/* ]] || continue
    case $args in *"-m program.runner"*|*"$ROOT/nightly.sh"*|*"$ROOT/ops/"*.sh*) continue ;; esac
    anc=$(ancestry "$pid")
    if [[ $anc == 2 ]] && tr '\0' '\n' < "/proc/$pid/environ" 2>/dev/null | grep -q '^PROGRAM_AGENT_ROUND='; then
        if (( et > LIMIT )); then reap "$pid" orphan "$args"
        elif [[ $stat == T* ]] && (( et > 1800 )); then reap "$pid" orphan-stop "$args"
        fi
        continue
    fi
    [[ $anc == 1 ]] || continue
    if (( et > LOOPLIM )) && [[ $args == *shell-snapshots* && $args == *sleep* ]] \
       && [[ $args == *"until "* || $args == *"while "* ]]; then
        reap "$pid" loop "$args"; continue
    fi
    case $comm in bash|sh|timeout|sleep|claude|*.sh) continue ;; esac
    if (( et > LIMIT )); then reap "$pid" age "$args"
    elif [[ $stat == T* ]] && (( et > 1800 )); then reap "$pid" stop "$args"
    fi
done <<< "$snapshot"
