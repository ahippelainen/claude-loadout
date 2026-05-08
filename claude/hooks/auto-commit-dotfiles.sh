#!/usr/bin/env bash
# PostToolUse hook: auto-commit (but not push) writes under ~/Git/dotfiles/.
# If the previous commit was made by this hook within the last 30 seconds,
# amend it instead of creating a new commit — this coalesces bursts of
# edits into a single commit.
#
# Never pushes. Never runs linters. Exit 0 always; this is informational.

set -u

DOTFILES="$HOME/Git/dotfiles"
MARKER_TAG="[auto-commit-dotfiles]"
COALESCE_WINDOW=30

file=$(jq -r '.tool_input.file_path // empty')

# Bail silently if not a dotfiles write.
[[ -z "$file" ]] && exit 0
[[ "$file" != "$DOTFILES"/* ]] && exit 0

cd "$DOTFILES" || exit 0

# Bail if there is nothing to commit (the write was a no-op or untracked-ignored).
if git diff --quiet && git diff --cached --quiet && [[ -z "$(git ls-files --others --exclude-standard)" ]]; then
  exit 0
fi

git add -A

# Decide: amend the last commit, or create a new one.
last_msg=$(git log -1 --pretty=%s 2>/dev/null || echo "")
last_time=$(git log -1 --pretty=%ct 2>/dev/null || echo 0)
now=$(date +%s)
age=$((now - last_time))

if [[ "$last_msg" == "$MARKER_TAG"* ]] && (( age < COALESCE_WINDOW )); then
  git commit --amend --no-edit --quiet >&2
  echo "$MARKER_TAG amended previous commit ($(basename "$file"))" >&2
else
  msg="$MARKER_TAG $(basename "$file")"
  git commit -m "$msg" --quiet >&2
  echo "$MARKER_TAG new commit: $msg" >&2
fi

exit 0
