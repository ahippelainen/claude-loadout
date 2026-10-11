#!/bin/bash
# stall_alarm.sh <pattern>...
# Run with run_in_background: it EXITS, printing one ALARM line (the exit re-invokes the orchestrator), when a
# busy (> CPU % CPU) own-user process with a <pattern> (substring) in its command line
#   - is older than LONG s, or
#   - is older than QUIET s and nothing under its cwd (depth 2) was modified in the last QUIET s.
# Checks every EVERY s. Re-arm after handling; put accepted runs in IGNORE or it alarms on them again at once.
# Env: LONG=2700  QUIET=1800  CPU=50  EVERY=120  IGNORE="<pid> ..."  CWD_UNDER=<dir>
[ $# -ge 1 ] || { echo "usage: stall_alarm.sh <pattern>..." >&2; exit 2; }
LONG=${LONG:-2700}; QUIET=${QUIET:-1800}; CPU=${CPU:-50}; EVERY=${EVERY:-120}
while true; do
  while read -r pid et cpu args; do
    case $args in *watchdog.sh*|*stall_alarm.sh*|*thermal_governor.sh*) continue ;; esac
    [[ " ${IGNORE:-} " == *" $pid "* ]] && continue
    [ "${cpu%.*}" -gt "$CPU" ] || continue
    hit=0; for p in "$@"; do [[ $args == *"$p"* ]] && hit=1; done
    [ $hit = 1 ] || continue
    cwd=$(readlink "/proc/$pid/cwd" 2>/dev/null) || continue
    [ -z "${CWD_UNDER:-}" ] || [[ $cwd == "$CWD_UNDER" || $cwd == "$CWD_UNDER"/* ]] || continue
    if [ "$et" -gt "$LONG" ]; then
      echo "ALARM long-run pid=$pid et=${et}s cpu=$cpu cwd=$cwd :: ${args:0:160}"; exit 0
    fi
    if [ "$et" -gt "$QUIET" ] && [ -z "$(find "$cwd" -maxdepth 2 -type f -mmin -$((QUIET / 60)) -print -quit 2>/dev/null)" ]; then
      echo "ALARM no-output-$((QUIET / 60))min pid=$pid et=${et}s cpu=$cpu cwd=$cwd :: ${args:0:160}"; exit 0
    fi
  done < <(ps -u "$(id -u)" -o pid=,etimes=,pcpu=,args=)
  sleep "$EVERY"
done
