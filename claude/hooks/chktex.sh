#!/usr/bin/env bash
# PostToolUse (Edit|Write): run chktex on an edited .tex file and hand the substantive warnings back to Claude.
# Suppressed as noise (measured on a real paper, ~95% of all warnings): 1 2 3 8 12 13 24 36 44.
f=$(jq -r '.tool_input.file_path // empty')
[[ "$f" == *.tex && -f "$f" ]] || exit 0
command -v chktex >/dev/null || exit 0
out=$(chktex -q -v0 -n1 -n2 -n3 -n8 -n12 -n13 -n24 -n36 -n44 "$f" 2>/dev/null | head -15)
[[ -z "$out" ]] && exit 0
jq -n --arg c "chktex on $(basename "$f") (file:line:col:warning:message):"$'\n'"$out" \
  '{hookSpecificOutput: {hookEventName: "PostToolUse", additionalContext: $c}}'
