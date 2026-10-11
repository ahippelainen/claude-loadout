#!/usr/bin/env bash
# Thermal governor. Scope: only descendants of PARENT (the nightly.sh that started it), never
# other projects. While the CPU temperature is >= HOT it SIGSTOPs the newest busy descendant;
# at <= COOL it SIGCONTs the most recently paused one. On exit it resumes everything it paused.
# Sensor: x86_pkg_temp (Intel) or k10temp Tctl (AMD); without either it logs no-sensor and exits.
# Usage: thermal_governor.sh PARENT_PID [HOT] [COOL]; TEMP_FILE overrides the sensor (tests).
PARENT=$1; HOT=${2:-90}; COOL=${3:-80}; INTERVAL=${INTERVAL:-20}
RUN=${PROGRAM_RUN:-$(cd "$(dirname "$0")/.." && pwd)/run}
LOG=$RUN/thermal.log

sensor() {
    local z h
    for z in /sys/class/thermal/thermal_zone*; do
        [[ -r $z/type && $(<"$z/type") == x86_pkg_temp ]] && { echo "$z/temp"; return; }
    done
    for h in /sys/class/hwmon/hwmon*; do
        [[ -r $h/name && $(<"$h/name") == k10temp ]] && { echo "$h/temp1_input"; return; }
    done
}
SENSOR=${TEMP_FILE:-$(sensor)}
[[ -n $SENSOR ]] || { echo "$(date '+%F %T') governor no-sensor" >> "$LOG"; exit 0; }

descendants() {  # all descendant pids of $1, excluding this governor's own tree
    local c
    for c in $(pgrep -P "$1"); do [[ $c == "$$" ]] && continue; echo "$c"; descendants "$c"; done
}
paused=()
resume_all() {
    local p
    for p in "${paused[@]}"; do kill -CONT "$p" 2>/dev/null && echo "$(date '+%F %T') governor resume $p (exit)" >> "$LOG"; done
    pkill -P $$ sleep 2>/dev/null
    exit 0
}
trap resume_all TERM INT EXIT

while kill -0 "$PARENT" 2>/dev/null; do
    t=$(( $(<"$SENSOR") / 1000 ))
    if (( t >= HOT )); then
        mapfile -t pids < <(descendants "$PARENT")
        if (( ${#pids[@]} )); then
            pid=$(ps -o pid=,etimes=,pcpu=,stat= -p "$(IFS=,; echo "${pids[*]}")" \
                  | awk '$3 > 30 && $4 !~ /T/' | sort -k2 -n | head -1 | awk '{print $1}')
            if [[ -n $pid ]] && kill -STOP "$pid"; then
                paused+=("$pid"); echo "$(date '+%F %T') governor pause $pid ${t}C" >> "$LOG"
            fi
        fi
    elif (( t <= COOL && ${#paused[@]} )); then
        pid=${paused[-1]}; unset 'paused[-1]'
        kill -CONT "$pid" 2>/dev/null && echo "$(date '+%F %T') governor resume $pid ${t}C" >> "$LOG"
    fi
    sleep "$INTERVAL" & wait $!
done
