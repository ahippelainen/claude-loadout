# claude-loadout

My Claude Code loadout — skills, commands, hooks, and agents I run
every day, plus the global rules in `CLAUDE.md`. Versioned so it
stays in sync across machines.

The real files live in this repo; `install.sh` symlinks them into
the locations Claude Code expects under `~/.claude/`. Edits to either
path edit the same underlying file.

Note: you must edit some of these files to suit your purpose for best results. In particular, the overall guide CLAUDE.md is very likely not usable for your purposes without modifications.

Some of the files in this repo have been written or edited by my clanker (recursively of course, being powered by these very files). If you find this repo useful, please share with your friends as well and drop a star. 

## Credits

This repo is a **curated mix** combined with original and editing work. Most of what's
here comes from community projects that were stitched together,
trimmed, and tuned to personal taste. The skills and agents trace
back to (among others):

- **academic-research-skills** — academic-paper, academic-paper-reviewer,
  academic-pipeline, deep-research-academic, physics-review
- **everything-claude-code** — broad swath of Claude Code skills and
  commands
- **superpowers** — agentic-engineering, brainstorming,
  subagent-driven-development, executing-plans, test-driven-development,
  verification-before-completion, writing-skills, etc.
- **get-shit-done** — workflow / shipping skills
- and other community contributions
- **ralph** — an autonomous "while-loop" offered by Anthropic

If you recognize your work here and want a more specific credit, open
an issue and I'll wire in a reference. I apologize in advance for all authors whose work I have forgotten to credit.

## What's here

- `claude/CLAUDE.md` — global rules sent to every Claude Code session
- `claude/settings.json` — model, permissions, hooks
- `claude/skills/` — slash-invocable skills
- `claude/commands/` — bundled `/`-commands
- `claude/agents/` — agent definitions
- `claude/hooks/` — `PreToolUse` / `PostToolUse` / `Stop` hook scripts
- `claude/contexts/`, `claude/rules/` — reusable prompt fragments
- `install.sh` — symlinks the above into `~/.claude/`

## Install

You will need [Claude Code](https://github.com/anthropics/claude-code)
installed and working before any of this matters. You may either work directly from the CLI or from a VSCode extension, which is a more user friendly path for beginners; I suggest starting with this, at least if you plan on using CC. For absolute beginners, start by reading either of the guides located under claude/ to get an idea of what this repo is about.

### 1. Prerequisites

`install.sh` checks for `git`, `jq`, and `ruff` on `PATH` and bails
early with a list of anything missing.

- **macOS (Homebrew):** `brew install git jq ruff`
- **Debian/Ubuntu:** `sudo apt install git jq` and `pipx install ruff`
- **Other:** install however you normally do.

### 2. Clone

```bash
git clone https://github.com/ahippelainen/claude-loadout.git ~/Git/dotfiles
cd ~/Git/dotfiles
```

You can clone anywhere, but `claude/settings.json` references hooks
at `$HOME/Git/dotfiles/...`. If you pick a different path, edit
`claude/settings.json` to match before or after running the
installer.

### 3. Run the installer

```bash
./install.sh
```

What it does:

- Symlinks `claude/CLAUDE.md` and `claude/settings.json` to
  `~/.claude/`, then symlinks each item inside `claude/commands/`,
  `claude/skills/`, and `claude/agents/` to the matching path
  under `~/.claude/`.
- Backs up any pre-existing real files at those paths to
  `<path>.backup.<timestamp>` before replacing them.
- Re-running is safe — existing symlinks are replaced cleanly,
  real files are backed up again.

Locally-installed commands, skills, and agents in `~/.claude/`
that are *not* in this repo are left untouched.

### 4. Verify

```bash
ls -l ~/.claude/CLAUDE.md
# expected: ~/.claude/CLAUDE.md -> ~/Git/dotfiles/claude/CLAUDE.md
```

Open a Claude Code session and run `/help` — the bundled commands
(e.g. `/ship`, `/lint`, `/code-review`) should appear.

### 5. Customize

- Edit `claude/CLAUDE.md` (or `~/.claude/CLAUDE.md` — same file via
  symlink). The shipped rules reflect personal taste; rewrite them.
- If you cloned outside `~/Git/dotfiles`, replace `$HOME/Git/dotfiles`
  in `claude/settings.json` with your actual path.

### 6. Update later

```bash
cd ~/Git/dotfiles && git pull
```

Symlinks already point into the repo, so no re-install is needed.

## Porting to other harnesses

The content here is plain Markdown — portable in spirit, not in
mechanism. Translation map:

- **`claude/CLAUDE.md`** → rename or symlink to `AGENTS.md` for
  harnesses that follow that convention (e.g. Codex CLI), or to
  `.cursor/rules/main.mdc` for Cursor.
- **Skills, commands, agents** → no cross-harness standard. Prompt
  bodies port directly; the invocation mechanism does not. Re-author
  per harness (Cursor custom modes, Aider macros, shell aliases, etc.).
- **Hooks** → Claude Code-specific. Re-implement against the target
  harness's hook system if it has one, otherwise drop.

`install.sh` only wires up Claude Code paths. For other harnesses,
fork it or symlink manually.

## What is NOT tracked

- `~/.claude/projects/` — per-project conversation history
- `~/.claude/sessions/`, `~/.claude/shell-snapshots/` — runtime state
- `~/.claude/.credentials.json` — API credentials
- `.claude/settings.local.json` in any project — per-machine
  permissions (also gitignored here)

## License

MIT — see [LICENSE](LICENSE). Upstream projects retain their own
licenses; this repo's MIT covers the curation and any local edits.
