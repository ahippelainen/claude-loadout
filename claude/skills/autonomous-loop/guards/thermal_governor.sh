#!/bin/bash
# thermal_governor.sh <logfile> <pattern>...
# Every 20 s: while the CPU package is >= HOT degC, SIGSTOPs the newest busy (> 30 % CPU), not yet stopped,
# own-user process with a <pattern> (substring) in its command line, one more per tick while hot; at <= COOL
# it SIGCONTs them one per tick, last paused first. INT/TERM/HUP resumes everything it paused.
# Paused time still counts against the run's own KILL timeout.
# Env: HOT=90  COOL=80  ZONE=x86_pkg_temp (a /sys/class/thermal/thermal_zone*/type value)  CWD_UNDER=<dir>
[ $# -ge 2 ] || { echo "usage: thermal_governor.sh <logfile> <pattern>..." >&2; exit 2; }
LOG=$1; shift
HOT=${HOT:-90}; COOL=${COOL:-80}; ZONE=${ZONE:-x86_pkg_temp}
temp() {
  for z in /sys/class/thermal/thermal_zone*/; do
    [ "$(cat "${z}type")" = "$ZONE" ] && echo $(( $(cat "${z}temp") / 1000 )) && return
  done
}
in_scope() {
  [ -z "${CWD_UNDER:-}" ] && return 0
  local c; c=$(readlink "/proc/$1/cwd" 2>/dev/null) || return 1
  [[ $c == "$CWD_UNDER" || $c == "$CWD_UNDER"/* ]]
}
newest_busy() {
  ps -u "$(id -u)" -o pid=,etimes=,pcpu=,stat=,args= | while read -r pid et cpu st args; do
    case $args in *watchdog.sh*|*stall_alarm.sh*|*thermal_governor.sh*) continue ;; esac
    [[ $st == *T* ]] && continue
    [ "${cpu%.*}" -gt 30 ] || continue
    hit=0; for p in "$@"; do [[ $args == *"$p"* ]] && hit=1; done
    [ $hit = 1 ] && in_scope "$pid" && echo "$et $pid"
  done | sort -n | head -1 | cut -d' ' -f2
}
[ -n "$(temp)" ] || { echo "thermal_governor: no thermal zone of type $ZONE" >&2; exit 1; }
paused=()
trap 'for p in "${paused[@]}"; do kill -CONT "$p" 2>/dev/null; done; exit' INT TERM HUP
while true; do
  t=$(temp)
  if [ "$t" -ge "$HOT" ]; then
    pid=$(newest_busy "$@")
    if [ -n "$pid" ] && kill -STOP "$pid"; then
      paused+=("$pid"); echo "$(date '+%F %T') ${t}C pause $pid" >> "$LOG"
    fi
  elif [ "$t" -le "$COOL" ] && [ ${#paused[@]} -gt 0 ]; then
    pid=${paused[-1]}; unset 'paused[-1]'
    kill -CONT "$pid" 2>/dev/null && echo "$(date '+%F %T') ${t}C resume $pid" >> "$LOG"
  fi
  sleep 20
done
