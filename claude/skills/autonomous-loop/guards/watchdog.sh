#!/bin/bash
# watchdog.sh <logfile> <pattern>...
# Backstop for per-command timeouts, checked every 60 s. Kills own-user processes that are
#   - older than LIMIT s with a <pattern> (substring, e.g. /home/me/Git/X/venv/bin/python) in the command line, or
#   - Claude Code shell wait-loops (command line has shell-snapshots, until/while and sleep) older than LOOPLIM s,
#     only when CWD_UNDER is set, so other Claude sessions' loops are never touched.
# A kill is TERM to the children and the process, KILL 3 s later, one log line each. The guard scripts never match.
# Env: LIMIT=3720  LOOPLIM=1200  CWD_UNDER=<dir> (only processes whose cwd is <dir> or below it)
[ $# -ge 2 ] || { echo "usage: watchdog.sh <logfile> <pattern>..." >&2; exit 2; }
LOG=$1; shift
LIMIT=${LIMIT:-3720}; LOOPLIM=${LOOPLIM:-1200}
in_scope() {
  [ -z "${CWD_UNDER:-}" ] && return 0
  local c; c=$(readlink "/proc/$1/cwd" 2>/dev/null) || return 1
  [[ $c == "$CWD_UNDER" || $c == "$CWD_UNDER"/* ]]
}
while true; do
  ps -u "$(id -u)" -o pid=,etimes=,args= | while read -r pid et args; do
    case $args in *watchdog.sh*|*stall_alarm.sh*|*thermal_governor.sh*) continue ;; esac
    kill_it=0
    if [ "$et" -gt "$LIMIT" ]; then
      for p in "$@"; do [[ $args == *"$p"* ]] && kill_it=1; done
    fi
    if [ -n "${CWD_UNDER:-}" ] && [ "$et" -gt "$LOOPLIM" ] && [[ $args == *shell-snapshots* && $args == *sleep* ]] && [[ $args == *"until "* || $args == *"while "* ]]; then
      kill_it=1
    fi
    if [ $kill_it = 1 ] && in_scope "$pid"; then
      echo "$(date '+%F %T') kill pid=$pid et=${et}s ${args:0:200}" >> "$LOG"
      pkill -TERM -P "$pid" 2>/dev/null; kill -TERM "$pid" 2>/dev/null; sleep 3; kill -KILL "$pid" 2>/dev/null
    fi
  done
  sleep 60
done
