#!/usr/bin/env bash
# Headless agent loop for one role (supervised by ops/watchdog.sh via ops/loops.txt).
# DISABLED unless ops/agent-loops.enabled exists. That file is host-local (gitignored) and
# names the expected account as lines `email=...` and `org_id=...`; they are checked against
# `claude auth status --json` before any round, so a loop never spends another account's usage.
# Only a definite mismatch (logged in as another email/org) writes STOP; an unreachable or
# timed-out auth check, or a logged-out CLI, is a crash (restart budget applies).
# While $ROOT/LOOP/ACTIVE exists (an interactive orchestrator holds the repo) no round runs:
# status deferred, retried by the watchdog. It is re-checked before every round.
# Each round is a fresh `claude -p` with ops/prompts/<name>.txt (@ROOT@, @RESULT@ and @POLICY@ are
# substituted); the agent writes `worked` or `stopped <reason>` to the result file.
# Exit status in $PROGRAM_RUN/loops/<name>/status.json, acted on by ops/watchdog.sh:
#   stopped (STOP sentinel written: restarted only after the owner deletes STOP) |
#   usage_exhausted, deferred (retried hourly, not counted) | crashed (counted)
# Each round runs with PROGRAM_AGENT_ROUND=<name> in its environment, so ops/reaper.sh can
# recognise its orphans.
# The CLI reports API/usage errors as is_error with exit code 0 (anthropics/claude-code#79500),
# so the verdict comes from the JSON result, never from the exit code alone.
set -uo pipefail
NAME=$1
ROOT=${PROGRAM_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}
RUN=${PROGRAM_RUN:-$ROOT/run}
GITDIR=${PROGRAM_GIT_DIR-$(git -C "$ROOT" rev-parse --absolute-git-dir 2>/dev/null)}
ENABLE=${PROGRAM_AGENT_ENABLE:-$ROOT/ops/agent-loops.enabled}
POLICY=${PROGRAM_PUSH_POLICY:-$HOME/Git/dotfiles/claude/push-policy}
PROMPT=${PROGRAM_PROMPTS:-$ROOT/ops/prompts}/$NAME.txt
ACTIVE=${PROGRAM_ACTIVE:-$ROOT/LOOP/ACTIVE}
AUTH_TIMEOUT=${PROGRAM_AUTH_TIMEOUT:-60}
ROUND_TIMEOUT=${PROGRAM_ROUND_TIMEOUT:-21600}
PAUSE=${PROGRAM_ROUND_PAUSE:-120}
D=$RUN/loops/$NAME
LOG=$RUN/watchdog.log
mkdir -p "$D/rounds"
ev() { echo "$(date '+%F %T') $NAME $1${2:+ $2}" >> "$LOG"; }
status() {
    printf '{"status": "%s", "reason": "%s", "pid": %d, "ts": "%s"}\n' "$1" "${2//\"/\'}" $$ "$(date -Iseconds)" \
        > "$D/status.json.tmp" && mv "$D/status.json.tmp" "$D/status.json"
}
git_busy() {
    [[ -n $GITDIR ]] || return 1
    [[ -e $GITDIR/index.lock || -e $GITDIR/MERGE_HEAD || -e $GITDIR/CHERRY_PICK_HEAD \
       || -d $GITDIR/rebase-merge || -d $GITDIR/rebase-apply ]]
}
claude_bin() {  # cron's PATH is minimal, hence the fallbacks
    local c=${PROGRAM_CLAUDE_BIN:-$(command -v claude)}
    [[ -z $c && -x $HOME/.local/bin/claude ]] && c=$HOME/.local/bin/claude
    [[ -n $c ]] || c=$(printf '%s\n' "$HOME"/.vscode{,-oss,-server}/extensions/anthropic.claude-code-*/resources/native-binary/claude \
        | grep -v '\*' | sed 's|.*/anthropic\.claude-code-\([^/]*\)/.*|\1\t&|' | sort -V | tail -1 | cut -f2)
    echo "$c"
}
defer_if_active() {
    [[ -e $ACTIVE ]] || return 0
    status deferred "interactive orchestrator active"; ev deferred "interactive orchestrator active ($ACTIVE)"
    exit 0
}

[[ -e $ENABLE ]] || { echo "agent loops disabled: $ENABLE does not exist"; exit 0; }
[[ -e $D/STOP ]] && exit 0
exec 9>"$D/lock"
flock -n 9 || exit 0
status running ""
touch "$D/heartbeat"
( exec 9>&-; while sleep 60; do touch "$D/heartbeat"; done ) &  # must not hold the loop lock
HB=$!
trap 'pkill -P $HB 2>/dev/null; kill $HB 2>/dev/null' EXIT

defer_if_active
CLAUDE=$(claude_bin)
if [[ ! -x $CLAUDE ]]; then status crashed "claude binary not found"; ev crashed "claude binary not found"; exit 1; fi

# prints "<email> <org>", "- -" when logged out, nothing when unreachable or unparseable
read -r got_email got_org < <(timeout -k 5 "$AUTH_TIMEOUT" "$CLAUDE" auth status --json 2>/dev/null | python3 -c \
    'import json,sys; d=json.load(sys.stdin); print(d.get("email") or "-", d.get("orgId") or "-") if d.get("loggedIn") else print("- -")' 2>/dev/null)
if [[ -z ${got_email:-} ]]; then status crashed "auth status unreachable"; ev crashed "auth status unreachable"; exit 1; fi
if [[ $got_email == - ]]; then status crashed "claude CLI not logged in"; ev crashed "claude CLI not logged in"; exit 1; fi
want_email=$(grep -oP '^email=\K\S+' "$ENABLE"); want_org=$(grep -oP '^org_id=\K\S+' "$ENABLE")
if [[ -z $want_email || $got_email != "$want_email" || ( -n $want_org && ${got_org:--} != "$want_org" ) ]]; then
    touch "$D/STOP"; status stopped "account check failed"
    ev account-mismatch "headless CLI is not on the account named in $(basename "$ENABLE"); STOP written"
    exit 0
fi

classify() {  # out err rc -> "ok" | "usage <msg>" | "crash <msg>"
    python3 - "$@" <<'PY'
import json, re, sys
out, err, rc = sys.argv[1], sys.argv[2], int(sys.argv[3])
usage = re.compile(r"usage limit|hit your limit|limit reached|rate.?limit|out of extra usage|"
                   r"credit balance|resets? (at|in)\b|\b(429|529)\b|overloaded", re.I)
txt = open(out, errors="replace").read().strip()
blob = (txt + "\n" + open(err, errors="replace").read()).strip()
try:
    d = json.loads(txt.splitlines()[-1]) if txt else None
except (json.JSONDecodeError, IndexError):
    d = None
last = (blob.splitlines() or ["no output"])[-1][:160]
if rc == 124:
    print("crash round timeout")
elif isinstance(d, dict) and d.get("is_error"):
    msg = " ".join(str(d.get("result", "")).split())[:160]
    print(("usage " if usage.search(msg) else "crash ") + msg)
elif rc != 0 or not isinstance(d, dict):
    print(("usage " if usage.search(blob[-4000:]) else "crash ") + f"rc={rc} {last}")
else:
    print("ok")
PY
}

while :; do
    [[ -e $D/STOP ]] && { status stopped "STOP sentinel"; exit 0; }
    defer_if_active
    for _ in $(seq 20); do git_busy || break; sleep 30; done
    if git_busy; then status crashed "git operation in progress for 10 min"; ev crashed "git-lock"; exit 1; fi
    ts=$(date +%Y%m%d-%H%M%S)
    out=$D/rounds/$ts.json
    res=$D/round_result
    rm -f "$res"
    prompt=$(sed "s|@RESULT@|$res|g; s|@ROOT@|$ROOT|g; s|@POLICY@|$POLICY|g" "$PROMPT")
    echo "$(date '+%F %T') round start $CLAUDE" >> "$D/loop.log"
    (cd "$ROOT" && PROGRAM_AGENT_ROUND=$NAME CLAUDE_CODE_PRINT_BG_WAIT_CEILING_MS=0 timeout -k 60 "$ROUND_TIMEOUT" \
        "$CLAUDE" -p "$prompt" --model "${PROGRAM_MODEL:-opus}" --permission-mode auto --output-format json > "$out" 2> "$out.err")
    rc=$?
    verdict=$(classify "$out" "$out.err" "$rc")
    r=$(head -c 200 "$res" 2>/dev/null)
    echo "$(date '+%F %T') round end rc=$rc verdict=${verdict%% *} result=${r:-none}" >> "$D/loop.log"
    ls -1t "$D"/rounds/*.json 2>/dev/null | tail -n +21 | while read -r f; do rm -f "$f" "$f.err"; done
    case $verdict in
        usage*) status usage_exhausted "${verdict#usage }"; ev usage-exhausted "${verdict#usage }"; exit 0 ;;
        crash*) status crashed "${verdict#crash }"; ev crashed "${verdict#crash }"; exit 1 ;;
    esac
    case $r in
        worked*) ;;
        stopped*) touch "$D/STOP"; status stopped "${r#stopped }"; ev stopped "${r#stopped }"; exit 0 ;;
        *) status crashed "round ended without a result"; ev crashed "no round result (rc=$rc)"; exit 1 ;;
    esac
    sleep "$PAUSE"
done
