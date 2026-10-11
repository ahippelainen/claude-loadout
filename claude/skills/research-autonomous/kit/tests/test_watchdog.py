"""Watchdog + agent-loop tests with a fake `claude` binary; all state lives in tmp_path."""
from __future__ import annotations

import fcntl
import json
import os
import subprocess
import time
from datetime import datetime, timedelta
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[1]
WATCHDOG = ROOT / "ops" / "watchdog.sh"
AGENT_LOOP = ROOT / "ops" / "agent_loop.sh"

FAKE_CLAUDE = r"""#!/usr/bin/env bash
if [[ $1 == auth ]]; then
  case $(cat "$FAKE_DIR/auth" 2>/dev/null) in
    hang)    sleep 30 ;;
    garbage) echo "Error: could not reach the server" >&2; exit 1 ;;
    out)     echo '{"loggedIn": false}'; exit 1 ;;
    *)       echo '{"loggedIn": true, "email": "loop@example.org", "orgId": "org-test"}' ;;
  esac
  exit 0
fi
echo p >> "$FAKE_DIR/calls"
res=$(grep -oE '[^ ]*round_result' <<< "$2" | head -1)
n=$(wc -l < "$FAKE_DIR/calls")
case $(cat "$FAKE_DIR/mode") in
  usage)   echo '{"type":"result","subtype":"success","is_error":true,"result":"You'"'"'ve hit your limit · resets 3pm"}' ;;
  crash)   echo "Error: something internal broke" >&2; exit 1 ;;
  stopped) echo "stopped gate G0 reached, waiting for owner" > "$res"; echo '{"type":"result","is_error":false}' ;;
  rounds)  if (( n < 3 )); then echo worked > "$res"; else echo "stopped queue empty" > "$res"; fi; echo '{"is_error":false}' ;;
  slow)    sleep 4; echo "stopped done" > "$res"; echo '{"is_error":false}' ;;
  activate) touch "$FAKE_DIR/ACTIVE"; echo worked > "$res"; echo '{"is_error":false}' ;;
esac
"""

FAKE_RUNNER = r"""#!/usr/bin/env bash
d=$PROGRAM_RUN/loops/crun; mkdir -p "$d"; exec 9>"$d/lock"; flock -n 9 || exit 0
echo r >> "$FAKE_DIR/runner_calls"
echo '{"status": "crashed", "reason": "boom"}' > "$d/status.json"
"""


@pytest.fixture
def env(tmp_path):
    for d in ("run", "git", "jobs/queue", "jobs/running", "prompts"):
        (tmp_path / d).mkdir(parents=True)
    claude = tmp_path / "fakeclaude"
    claude.write_text(FAKE_CLAUDE)
    runner = tmp_path / "fakerunner"
    runner.write_text(FAKE_RUNNER)
    for f in (claude, runner):
        f.chmod(0o755)
    (tmp_path / "prompts" / "fake.txt").write_text("repo @ROOT@; write the result to @RESULT@\n")
    (tmp_path / "loops.txt").write_text(f"# test loops\nfake agent {AGENT_LOOP} fake\ncrun compute {runner}\n")
    (tmp_path / "enable").write_text("email=loop@example.org\norg_id=org-test\n")
    (tmp_path / "calls").touch()
    (tmp_path / "runner_calls").touch()
    clean = {k: v for k, v in os.environ.items() if not k.startswith("PROGRAM_")}
    e = {**clean, "FAKE_DIR": str(tmp_path), "PROGRAM_RUN": str(tmp_path / "run"),
         "PROGRAM_GIT_DIR": str(tmp_path / "git"), "PROGRAM_JOBS": str(tmp_path / "jobs"),
         "PROGRAM_LOOPS": str(tmp_path / "loops.txt"), "PROGRAM_AGENT_ENABLE": str(tmp_path / "enable"),
         "PROGRAM_CLAUDE_BIN": str(claude), "PROGRAM_PROMPTS": str(tmp_path / "prompts"),
         "PROGRAM_ROUND_PAUSE": "0", "PROGRAM_WINDOW": "00:00-23:59", "PROGRAM_ACTIVE": str(tmp_path / "ACTIVE"),
         "PROGRAM_AUTH_TIMEOUT": "1"}
    return tmp_path, e


def mode(tmp: Path, m: str) -> None:
    (tmp / "mode").write_text(m)


def loop_dir(tmp: Path, name: str = "fake") -> Path:
    return tmp / "run" / "loops" / name


LAUNCH_EVENTS = ("start", "restart", "usage-retry", "deferred-retry", "resume")


def launches(tmp: Path, name: str) -> int:
    return sum(len(events(tmp, ev, name)) for ev in LAUNCH_EVENTS)


def wait_done(tmp: Path, name: str, since: float, timeout: float = 20) -> None:
    """Wait until the loop launched after `since` has written its exit status and unlocked."""
    d = loop_dir(tmp, name)
    t_end = time.time() + timeout
    while time.time() < t_end:
        st = d / "status.json"
        if st.exists() and st.stat().st_mtime >= since and status(tmp, name) != "running":
            with open(d / "lock") as f:
                try:
                    fcntl.flock(f, fcntl.LOCK_EX | fcntl.LOCK_NB)
                    return
                except BlockingIOError:
                    pass
        time.sleep(0.05)
    raise TimeoutError(f"loop {name} did not finish")


def wd(e: dict, tmp: Path, name: str = "fake") -> None:
    """One watchdog check; if it launched the loop, wait for that run to finish."""
    n0, t0 = launches(tmp, name), time.time()
    subprocess.run(["timeout", "-k", "5", "60", str(WATCHDOG)], env=e, check=True)
    if launches(tmp, name) > n0:
        wait_done(tmp, name, t0)


def status(tmp: Path, name: str = "fake") -> str:
    return json.loads((loop_dir(tmp, name) / "status.json").read_text())["status"]


def events(tmp: Path, event: str, name: str = "fake") -> list[str]:
    log = tmp / "run" / "watchdog.log"
    lines = log.read_text().splitlines() if log.exists() else []
    return [x for x in lines if x.split()[2:4] == [name, event]]


def calls(tmp: Path) -> int:
    return len((tmp / "calls").read_text().splitlines())


def test_usage_exhausted_is_retried_without_budget(env):
    tmp, e = env
    mode(tmp, "usage")
    wd(e, tmp)
    assert status(tmp) == "usage_exhausted" and len(events(tmp, "usage-exhausted")) == 1
    wd(e, tmp)
    assert len(events(tmp, "usage-retry")) == 1 and len(events(tmp, "usage-exhausted")) == 2
    assert events(tmp, "restart") == [] and calls(tmp) == 2  # one minimal round per attempt


def test_crash_restart_budget_then_stuck(env):
    tmp, e = env
    mode(tmp, "crash")
    wd(e, tmp)  # first start
    assert status(tmp) == "crashed"
    for k in range(1, 7):
        wd(e, tmp)
        assert len(events(tmp, "restart")) == k and status(tmp) == "crashed"
    wd(e, tmp)
    assert status(tmp) == "stuck" and len(events(tmp, "stuck")) == 1
    wd(e, tmp)
    assert len(events(tmp, "restart")) == 6 and len(events(tmp, "stuck")) == 1 and calls(tmp) == 7
    assert "6/6 crashed: rc=1 Error: something internal broke" in events(tmp, "restart")[-1]


def test_stopped_is_never_restarted(env):
    tmp, e = env
    mode(tmp, "stopped")
    wd(e, tmp)
    assert status(tmp) == "stopped" and (loop_dir(tmp) / "STOP").exists()
    n_log = len((tmp / "run" / "watchdog.log").read_text().splitlines())
    wd(e, tmp)
    wd(e, tmp)
    assert calls(tmp) == 1 and len((tmp / "run" / "watchdog.log").read_text().splitlines()) == n_log


def test_worked_rounds_continue_until_stopped(env):
    tmp, e = env
    mode(tmp, "rounds")
    wd(e, tmp)
    assert calls(tmp) == 3 and status(tmp) == "stopped"


def test_single_instance(env):
    tmp, e = env
    mode(tmp, "slow")
    t0 = time.time()
    subprocess.run([str(WATCHDOG)], env=e, check=True)
    time.sleep(1)
    subprocess.run([str(WATCHDOG)], env=e, check=True)
    wait_done(tmp, "fake", t0)
    assert calls(tmp) == 1 and len(events(tmp, "start")) == 1


def test_git_lock_defers_restart(env):
    tmp, e = env
    mode(tmp, "crash")
    wd(e, tmp)
    (tmp / "git" / "index.lock").touch()
    wd(e, tmp)
    assert len(events(tmp, "restart-deferred")) == 1 and calls(tmp) == 1
    (tmp / "git" / "index.lock").unlink()
    wd(e, tmp)
    assert len(events(tmp, "restart")) == 1 and calls(tmp) == 2


def test_agent_loops_disabled_by_default(env):
    tmp, e = env
    mode(tmp, "stopped")
    (tmp / "enable").unlink()
    subprocess.run([str(WATCHDOG)], env=e, check=True)
    out = subprocess.run([str(AGENT_LOOP), "fake"], env=e, capture_output=True, text=True, check=True).stdout
    assert "disabled" in out and calls(tmp) == 0 and not (loop_dir(tmp) / "status.json").exists()


def test_account_mismatch_stops_before_any_round(env):
    tmp, e = env
    mode(tmp, "stopped")
    (tmp / "enable").write_text("email=someone-else@example.org\n")
    wd(e, tmp)
    assert status(tmp) == "stopped" and (loop_dir(tmp) / "STOP").exists() and calls(tmp) == 0
    assert len(events(tmp, "account-mismatch")) == 1


def _window_excluding_now() -> str:
    a, b = datetime.now() + timedelta(hours=2), datetime.now() + timedelta(hours=3)
    return f"{a:%H:%M}-{b:%H:%M}"


def test_compute_restart_needs_window_and_work(env):
    tmp, e = env
    d = loop_dir(tmp, "crun")
    d.mkdir(parents=True)
    (d / "status.json").write_text('{"status": "crashed", "reason": "boom"}\n')
    runner_calls = lambda: len((tmp / "runner_calls").read_text().splitlines())  # noqa: E731
    subprocess.run([str(WATCHDOG)], env=e, check=True)  # in window, but no work
    (tmp / "jobs" / "queue" / "j.yaml").write_text("task: example\n")
    subprocess.run([str(WATCHDOG)], env={**e, "PROGRAM_WINDOW": _window_excluding_now()}, check=True)
    time.sleep(0.5)
    assert runner_calls() == 0
    subprocess.run([str(WATCHDOG)], env=e, check=True)
    time.sleep(0.5)
    assert runner_calls() == 1 and len(events(tmp, "restart", "crun")) == 1


def test_no_git_dir_does_not_block_restarts(env):
    tmp, e = env
    e = {**e, "PROGRAM_GIT_DIR": ""}  # empty: the root is not a git work tree
    mode(tmp, "crash")
    wd(e, tmp)
    wd(e, tmp)
    assert len(events(tmp, "restart")) == 1 and calls(tmp) == 2 and events(tmp, "restart-deferred") == []



def reason(tmp: Path, name: str = "fake") -> str:
    return json.loads((loop_dir(tmp, name) / "status.json").read_text())["reason"]


def test_owner_removing_stop_resumes_agent_loop(env):
    tmp, e = env
    mode(tmp, "stopped")
    wd(e, tmp)
    assert status(tmp) == "stopped" and calls(tmp) == 1
    (loop_dir(tmp) / "STOP").unlink()
    wd(e, tmp)
    assert len(events(tmp, "resume")) == 1 and calls(tmp) == 2 and events(tmp, "restart") == []
    assert status(tmp) == "stopped" and (loop_dir(tmp) / "STOP").exists()


@pytest.mark.parametrize("auth,why", [("hang", "auth status unreachable"), ("garbage", "auth status unreachable"),
                                      ("out", "claude CLI not logged in")])
def test_auth_failure_is_a_counted_crash_without_stop(env, auth, why):
    tmp, e = env
    mode(tmp, "stopped")
    (tmp / "auth").write_text(auth)
    wd(e, tmp)
    assert (status(tmp), reason(tmp)) == ("crashed", why) and calls(tmp) == 0
    assert not (loop_dir(tmp) / "STOP").exists()
    wd(e, tmp)
    assert len(events(tmp, "restart")) == 1 and "1/6" in events(tmp, "restart")[0]
    (tmp / "auth").unlink()
    wd(e, tmp)
    assert status(tmp) == "stopped" and calls(tmp) == 1


def test_interactive_orchestrator_defers_rounds(env):
    tmp, e = env
    mode(tmp, "stopped")
    (tmp / "ACTIVE").touch()
    wd(e, tmp)
    assert (status(tmp), reason(tmp)) == ("deferred", "interactive orchestrator active") and calls(tmp) == 0
    wd(e, tmp)
    assert len(events(tmp, "deferred-retry")) == 1 and events(tmp, "restart") == [] and calls(tmp) == 0
    assert not (loop_dir(tmp) / "STOP").exists()
    (tmp / "ACTIVE").unlink()
    wd(e, tmp)
    assert status(tmp) == "stopped" and calls(tmp) == 1


def test_active_is_rechecked_before_every_round(env):
    tmp, e = env
    mode(tmp, "activate")  # the first round's agent creates ACTIVE, as an interactive session would
    wd(e, tmp)
    assert calls(tmp) == 1 and status(tmp) == "deferred"


REAPER = ROOT / "ops" / "reaper.sh"
SLEEPER = "import time; time.sleep(30)"


def test_reaper_flags_only_marked_orphans(tmp_path):
    root, run = tmp_path / "root", tmp_path / "run"
    root.mkdir()
    clean = {k: v for k, v in os.environ.items() if not k.startswith("PROGRAM_")}
    # bash exits at once, so both sleepers are reparented (to init or a subreaper) with no timeout ancestor
    spawn = (f"cd {root}; PROGRAM_AGENT_ROUND=fake setsid python3 -c '{SLEEPER}' >/dev/null 2>&1 & echo $!; "
             f"setsid python3 -c '{SLEEPER}' >/dev/null 2>&1 & echo $!")
    marked, plain = map(int, subprocess.run(["bash", "-c", spawn], env=clean, capture_output=True,
                                            text=True, check=True).stdout.split())
    try:
        time.sleep(1.5)
        subprocess.run([str(REAPER), "0"], env={**clean, "DRY": "1", "PROGRAM_ROOT": str(root),
                                                 "PROGRAM_RUN": str(run)}, check=True, timeout=30)
        log = (run / "reaper.log").read_text() if (run / "reaper.log").exists() else ""
        assert f"WOULD kill pid={marked} [orphan]" in log
        assert f"pid={plain} " not in log
    finally:
        for pid in (marked, plain):
            try:
                os.kill(pid, 9)
            except ProcessLookupError:
                pass
