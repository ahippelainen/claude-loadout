#!/usr/bin/env python3
# PreToolUse (Bash): push policy and Mathematica guard in one pass.
# Pushes: a repo with .githooks/pre-push needs a .publish-ok; repos marked free in claude/push-policy push freely;
# any other push needs the user's explicit yes, recorded as the HEAD sha in <git dir>/claude-push-ok.
# --no-verify is refused. Wolfram programs must run under wlrun or `timeout -s KILL`.
import json, os, re, shlex, subprocess, sys
from pathlib import Path

POLICY = Path.home() / "Git/dotfiles/claude/push-policy"
WOLFRAM = {"wolframscript", "WolframKernel", "MathKernel", "math", "wolfram"}


def block(msg):
    print(msg, file=sys.stderr)
    sys.exit(2)


def git(top, *args):
    r = subprocess.run(["git", "-C", top, *args], capture_output=True, text=True)
    return r.stdout.strip() if r.returncode == 0 else ""


data = json.load(sys.stdin)
cwd = data.get("cwd") or os.getcwd()
# Heredoc bodies are data (file contents, scripts piped to an interpreter), not commands of this shell.
cmd = re.sub(r"<<-?\s*(['\"]?)(\w+)\1[^\n]*\n.*?\n\s*\2[ \t]*(?=\n|$)", "<<HEREDOC",
             data.get("tool_input", {}).get("command", ""), flags=re.S)
segments = re.split(r"&&|\|\||[;|\n]|\$\(", cmd)


def words(seg):
    try:
        return shlex.split(seg)
    except ValueError:
        return seg.split()


for seg in segments:
    w = [t for t in words(seg) if not re.match(r"^\w+=", t)]
    while w and w[0] in ("nohup", "nice", "time", "exec", "command"):
        w = w[1:]
    if not w:
        continue
    prog = os.path.basename(w[0])
    if prog in WOLFRAM:
        block("Mathematica guard: run Wolfram scripts as `~/Git/dotfiles/claude/tools/wlrun <seconds> <file>` "
              "(KILL timeout, memory cap, licence retry, no surviving kernel) or under `timeout -s KILL <seconds>`. "
              "A plain timeout sends SIGTERM, which a busy kernel ignores.")
    if prog == "timeout" and any(os.path.basename(t) in WOLFRAM for t in w[1:]):
        if not re.search(r"(-s|--signal)[= ]?(KILL|9)\b|-sKILL|-s9\b", seg):
            block("Mathematica guard: use `timeout -s KILL <seconds>` (or wlrun); SIGTERM does not stop a busy kernel.")

push = re.search(r"(?<![\w-])git\s+(?:[^\n;&|]*\s)?push(?:\s|$)", cmd)
if not push:
    sys.exit(0)
if "--no-verify" in cmd:
    block("Blocked: --no-verify would bypass the repository's push hooks.")

target = cwd
before = cmd[: push.start()]
cds = re.findall(r"(?:^|[;&|]\s*)cd\s+(\S+)", before)
if cds:
    target = cds[-1]
m = re.search(r"git\s+-C\s+(\S+)[^;&|]*push", cmd[push.start():])
if m:
    target = m.group(1)
target = os.path.normpath(os.path.join(cwd, os.path.expanduser(target.strip("'\""))))
top = git(target, "rev-parse", "--show-toplevel")
if not top:
    sys.exit(0)
head = git(top, "rev-parse", "HEAD")

if (Path(top) / ".githooks/pre-push").exists():
    ok = Path(top) / ".publish-ok"
    if ok.exists() and ok.read_text().strip() == head:
        sys.exit(0)
    block("Blocked: pushing this repo is gated. Run the repo's publish step; it writes the reviewed commit's hash to .publish-ok.")

free = set()
if POLICY.exists():
    for line in POLICY.read_text().splitlines():
        parts = line.split()
        if len(parts) == 2 and not line.startswith("#") and parts[1] == "free":
            free.add(os.path.normpath(os.path.expanduser(parts[0])))
if top in free:
    sys.exit(0)

gitdir = git(top, "rev-parse", "--absolute-git-dir")
token = Path(gitdir) / "claude-push-ok"
if token.exists() and token.read_text().strip() == head:
    sys.exit(0)
block(f"Push policy for {top} is 'ask'. Ask the user in chat. After an explicit yes for this push, record it in a "
      f"separate Bash call (`git -C {top} rev-parse HEAD > {token}`) and push again. If the user grants standing "
      f"approval, add `{top} free` to {POLICY}.")
