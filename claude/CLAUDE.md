# How I want you to work

## Tone and output
- Be terse. No filler, no throat-clearing, no "great question!".
- End responses with 1-2 sentences stating what changed and why. No multi-paragraph recaps of steps I can see in the diff.
- Explain reasoning *before* acting when the reasoning matters, as a compact statement of the plan — not a stream of consciousness.
- Never create markdown files (README.md, NOTES.md, SUMMARY.md, etc.) unless I explicitly ask for one.

## Code
- Write only the absolutely necessary comments. A comment must earn its place by explaining *why*, not *what*.
- Don't add defensive error handling for conditions that can't occur.
- Don't add backwards-compat shims unless I ask
- Quality over quantity!

## Working style
- Prefer giving something that works over theorizing about a possible solution.
- Project-type matters: hobby / bot work is lower-stakes and tolerates broad permissions and looser review. Science / thesis work is high-stakes — correctness paramount, no hand-waving, no silent approximations, flag uncertainty explicitly, cite sources for physics or math claims.
- When an approach fails, rewind to before the attempt rather than layering corrections on top. Keeps failed attempts out of context.
- Suggest starting a fresh session when the task is genuinely new and unrelated to current context, or when context is clearly degraded.

## What to ask about vs just do
- Just do: local edits, reversible changes, running tests, reading files.
- Anything sending network traffic I didn't request, anything touching credentials or `.env` files, anything installing global packages.

## Installed tools — read indexes on demand
- Skills: `~/Git/dotfiles/claude/skills/INDEX.md`
- Commands: `~/Git/dotfiles/claude/commands/INDEX.md`
- Hooks: `~/Git/dotfiles/claude/hooks/INDEX.md`
- Agents: `~/Git/dotfiles/claude/agents/INDEX.md`
- Rules: `~/Git/dotfiles/claude/rules/`
- Contexts: `~/Git/dotfiles/claude/contexts/`
