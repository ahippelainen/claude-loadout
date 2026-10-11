#!/usr/bin/env bash
# Bootstrap script for a new machine.
# Symlinks config files from this repo into the locations tools expect.
# Safe to re-run: existing symlinks are replaced, real files are backed up.

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Required tools: the hooks use git, jq and python3; bail early if missing.
missing=()
for cmd in git jq python3; do
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
link "$DOTFILES_DIR/claude/commands"      "$HOME/.claude/commands"

# Claude Code skills — one symlink per skill directory, so locally-installed
# skills in ~/.claude/skills/ that are NOT in dotfiles remain untouched.
for skill_dir in "$DOTFILES_DIR/claude/skills/"*/; do
  skill_name="$(basename "$skill_dir")"
  link "$skill_dir" "$HOME/.claude/skills/$skill_name"
done

# Claude Code agents — one symlink per agent file, recursing into subdirectories
# (e.g. claude/agents/physics/). Files land flat in ~/.claude/agents/.
while IFS= read -r -d '' agent_file; do
  base="$(basename "$agent_file")"
  [[ "$base" == INDEX*.md ]] && continue
  link "$agent_file" "$HOME/.claude/agents/$base"
done < <(find "$DOTFILES_DIR/claude/agents" -type f -name '*.md' -print0)

# Rules: top-level files only (each scoped by `paths:` frontmatter); rules/latex/ is read by path from skills.
for rule in "$DOTFILES_DIR/claude/rules/"*.md; do
  [[ -e "$rule" ]] || continue
  link "$rule" "$HOME/.claude/rules/$(basename "$rule")"
done

# Drop dangling links into this repo, left behind when an item is deleted or renamed here.
for l in "$HOME"/.claude/{skills,agents,rules,contexts}/*; do
  [[ -L "$l" && ! -e "$l" && "$(readlink "$l")" == "$DOTFILES_DIR"/* ]] || continue
  rm "$l"
  echo "Pruned $l"
done

python3 "$DOTFILES_DIR/claude/tools/check.py" || echo "check.py reported problems (see above)."
echo "Done."
