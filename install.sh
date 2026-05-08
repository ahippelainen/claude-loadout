#!/usr/bin/env bash
# Bootstrap script for a new machine.
# Symlinks config files from this repo into the locations tools expect.
# Safe to re-run: existing symlinks are replaced, real files are backed up.

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Required tools. Hooks depend on these; bail early if missing.
missing=()
for cmd in git jq ruff; do
  command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
done
if (( ${#missing[@]} > 0 )); then
  echo "Missing required tools: ${missing[*]}"
  echo "Install them first (e.g. apt install ${missing[*]}) and re-run."
  exit 1
fi

link() {
  local src="$1"
  local dst="$2"

  mkdir -p "$(dirname "$dst")"

  if [[ -L "$dst" ]]; then
    rm "$dst"
  elif [[ -e "$dst" ]]; then
    local backup="${dst}.backup.$(date +%Y%m%d-%H%M%S)"
    echo "Backing up existing $dst -> $backup"
    mv "$dst" "$backup"
  fi

  ln -s "$src" "$dst"
  echo "Linked $dst -> $src"
}

# Claude Code global config
link "$DOTFILES_DIR/claude/CLAUDE.md"     "$HOME/.claude/CLAUDE.md"
link "$DOTFILES_DIR/claude/settings.json" "$HOME/.claude/settings.json"

# Claude Code commands — one symlink per item, so INDEX docs are skipped
# and locally-installed commands not in this repo remain untouched.
# Drop any legacy whole-dir symlink from earlier versions of this script.
[[ -L "$HOME/.claude/commands" ]] && rm "$HOME/.claude/commands"
mkdir -p "$HOME/.claude/commands"
for cmd_path in "$DOTFILES_DIR/claude/commands/"*; do
  cmd_name="$(basename "$cmd_path")"
  [[ "$cmd_name" == "INDEX.md" || "$cmd_name" == "INDEX_SHORT.md" ]] && continue
  link "$cmd_path" "$HOME/.claude/commands/$cmd_name"
done

# Claude Code skills — one symlink per skill directory, so locally-installed
# skills in ~/.claude/skills/ that are NOT in this repo remain untouched.
for skill_dir in "$DOTFILES_DIR/claude/skills/"*/; do
  skill_name="$(basename "$skill_dir")"
  link "$skill_dir" "$HOME/.claude/skills/$skill_name"
done

# Claude Code agents — one symlink per agent file. INDEX docs are skipped.
for agent_file in "$DOTFILES_DIR/claude/agents/"*.md; do
  agent_name="$(basename "$agent_file")"
  [[ "$agent_name" == "INDEX.md" || "$agent_name" == "INDEX_SHORT.md" ]] && continue
  link "$agent_file" "$HOME/.claude/agents/$agent_name"
done

echo "Done."
