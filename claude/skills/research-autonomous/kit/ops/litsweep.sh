#!/usr/bin/env bash
# Morning literature watcher (cron, ops/crontab.txt): one headless round of ops/prompts/litsweep.txt,
# then commit lit/daily/<date>.md by explicit path, and push only if this repo is `free` in the
# push policy. DISABLED unless ops/agent-loops.enabled exists: the same host-local file as for
# ops/agent_loop.sh, whose `email=` / `org_id=` lines are checked against `claude auth status
# --json` before the round, so the sweep never spends another account's usage. Any failed check
# (mismatch, logged out, auth unreachable) only skips today's sweep; nothing is written permanently.
# In a root that is not a git work tree the commit and push are skipped.
set -uo pipefail
ROOT=${PROGRAM_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}
RUN=${PROGRAM_RUN:-$ROOT/run}
ENABLE=${PROGRAM_AGENT_ENABLE:-$ROOT/ops/agent-loops.enabled}
POLICY=${PROGRAM_PUSH_POLICY:-$HOME/Git/dotfiles/claude/push-policy}
PROMPT=${PROGRAM_PROMPTS:-$ROOT/ops/prompts}/litsweep.txt
DATE=$(date +%F)
RES=$ROOT/lit/daily/$DATE.md
LOG=$RUN/litsweep.log
mkdir -p "$RUN" "$ROOT/lit/daily"
exec 9>"$RUN/litsweep.lock"; flock -n 9 || exit 0
[[ -s $RES ]] && exit 0
log() { echo "$(date '+%F %T') $*" >> "$LOG"; }
claude_bin() {  # cron's PATH is minimal, hence the fallbacks
    local c=${PROGRAM_CLAUDE_BIN:-$(command -v claude)}
    [[ -z $c && -x $HOME/.local/bin/claude ]] && c=$HOME/.local/bin/claude
    [[ -n $c ]] || c=$(printf '%s\n' "$HOME"/.vscode{,-oss,-server}/extensions/anthropic.claude-code-*/resources/native-binary/claude \
        | grep -v '\*' | sed 's|.*/anthropic\.claude-code-\([^/]*\)/.*|\1\t&|' | sort -V | tail -1 | cut -f2)
    echo "$c"
}

[[ -e $ENABLE ]] || { log "disabled: $ENABLE does not exist"; exit 0; }
if grep -qE '@(TOPIC|ARXIV_QUERIES|WATCH|TARGET_FILES)@' "$PROMPT"; then
    log "prompt placeholders not filled in $PROMPT"; exit 1
fi
CLAUDE=$(claude_bin)
[[ -x $CLAUDE ]] || { log "claude binary not found"; exit 1; }
read -r got_email got_org < <(timeout -k 5 "${PROGRAM_AUTH_TIMEOUT:-60}" "$CLAUDE" auth status --json 2>/dev/null | python3 -c \
    'import json,sys; d=json.load(sys.stdin); print(d.get("email") or "-", d.get("orgId") or "-") if d.get("loggedIn") else print("- -")' 2>/dev/null)
[[ -n ${got_email:-} ]] || { log "auth status unreachable"; exit 1; }
[[ $got_email != - ]] || { log "claude CLI not logged in"; exit 1; }
want_email=$(grep -oP '^email=\K\S+' "$ENABLE"); want_org=$(grep -oP '^org_id=\K\S+' "$ENABLE")
if [[ -z $want_email || ${got_email:--} != "$want_email" || ( -n $want_org && ${got_org:--} != "$want_org" ) ]]; then
    log "account mismatch (got $got_email)"; exit 1
fi

prompt=$(sed -e "s|@ROOT@|$ROOT|g" -e "s|@DATE@|$DATE|g" -e "s|@RESULT@|$RES|g" "$PROMPT")
cd "$ROOT" || exit 1
timeout -k 30 2400 "$CLAUDE" -p "$prompt" --model "${PROGRAM_MODEL:-opus}" --permission-mode auto --output-format json \
    > "$RUN/litsweep.out" 2> "$RUN/litsweep.err"
log "round end rc=$? lines=$(wc -l < "$RES" 2>/dev/null || echo 0)"
[[ -s $RES ]] || exit 1

GITDIR=$(git -C "$ROOT" rev-parse --absolute-git-dir 2>/dev/null) || { log "no git: commit skipped"; exit 0; }
for _ in 1 2 3 4 5 6; do
    [[ -e $GITDIR/index.lock || -e $GITDIR/MERGE_HEAD || -d $GITDIR/rebase-merge || -d $GITDIR/rebase-apply ]] || break
    sleep 20
done
if git add -- "$RES" && git commit -q -m "chore: [lit] daily sweep $DATE" -- "$RES" >> "$LOG" 2>&1; then
    log "commit ok"
else
    log "commit failed"; exit 1
fi
if ! grep -qE "^$ROOT[[:space:]]+free([[:space:]]|$)" "$POLICY" 2>/dev/null; then
    log "push skipped: $ROOT is not free in $POLICY"; exit 0
fi
{ timeout -k 10 120 git pull -q --rebase --autostash && timeout -k 10 120 git push -q; } >> "$LOG" 2>&1
log "push rc=$?"
