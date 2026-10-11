#!/usr/bin/env bash
# PostToolUse hook: auto-commit (never push) the one file an Edit/Write changed under ~/Git/dotfiles,
# also when it was edited through a ~/.claude/... symlink. A burst of edits within 30 s is folded
# into one commit, but only while that commit is still local. Exit 0 always; this is informational.

set -u

DOTFILES="$HOME/Git/dotfiles"
MARKER_TAG="[auto-commit-dotfiles]"
COALESCE_WINDOW=30

file=$(jq -r '.tool_input.file_path // empty')
[[ -z "$file" ]] && exit 0
file=$(realpath -m -- "$file")
[[ "$file" != "$DOTFILES"/* ]] && exit 0

cd "$DOTFILES" || exit 0
gitdir=$(git rev-parse --git-dir) || exit 0
for s in rebase-merge rebase-apply MERGE_HEAD CHERRY_PICK_HEAD; do
  [[ -e "$gitdir/$s" ]] && exit 0
done

git add -- "$file" 2>/dev/null || exit 0
git diff --cached --quiet && exit 0

last_msg=$(git log -1 --pretty=%s 2>/dev/null || echo "")
last_time=$(git log -1 --pretty=%ct 2>/dev/null || echo 0)
age=$(( $(date +%s) - last_time ))
pushed=0
git merge-base --is-ancestor HEAD origin/main 2>/dev/null && pushed=1

if [[ "$last_msg" == "$MARKER_TAG"* ]] && (( age < COALESCE_WINDOW && pushed == 0 )); then
  git commit --amend --no-edit --quiet >&2
  echo "$MARKER_TAG amended previous commit ($(basename "$file"))" >&2
else
  git commit -m "$MARKER_TAG $(basename "$file")" --quiet >&2
  echo "$MARKER_TAG new commit: $(basename "$file")" >&2
fi
exit 0
