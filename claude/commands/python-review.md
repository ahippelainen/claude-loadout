---
description: Comprehensive Python code review via the python-pro agent
argument-hint: "[optional: path or file to review, defaults to git-changed files]"
---

Run a comprehensive Python review on $ARGUMENTS (if given) or on the Python files changed in this working tree (if not).

Steps:
1. If $ARGUMENTS is empty, use `git diff --name-only HEAD` to find changed `.py` files. If none, say so and stop.
2. Invoke the `python-pro` agent with the list of files to review.
3. The agent runs static analysis and grades findings by severity: CRITICAL → HIGH → MEDIUM. It blocks on CRITICAL or HIGH.
4. Surface the agent's report verbatim. Do not add commentary.
