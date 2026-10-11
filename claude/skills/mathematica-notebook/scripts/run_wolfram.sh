#!/usr/bin/env bash
# run_wolfram.sh — locate a Wolfram kernel and invoke nb_tool.wls (create/extract) or
# nb_format.wls (format/from-wl).
#
# Probes for `wolframscript`, then `wolfram`, then `math` (in that order).
# Falls back to common macOS Mathematica.app / Wolfram*.app install paths.
#
# Deliberately does NOT use the desktop `Mathematica` binary — that's a frontend,
# not a kernel, and can't run scripts.

set -euo pipefail

# wolframscript silently drops every script argument that starts with "-", so flags travel as
# environment variables instead.
ARGS=()
for a in "$@"; do
  case "$a" in
    --no-format) export NB_NO_FORMAT=1 ;;
    --strict) export NB_STRICT=1 ;;
    --*) echo "Error: unknown flag $a (known: --no-format, --strict)" >&2; exit 1 ;;
    *) ARGS+=("$a") ;;
  esac
done
set -- ${ARGS[@]+"${ARGS[@]}"}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
case "${1:-}" in
  format|from-wl) WLS="$SCRIPT_DIR/nb_format.wls" ;;
  *) WLS="$SCRIPT_DIR/nb_tool.wls" ;;
esac

if [ ! -f "$WLS" ]; then
  echo "Error: script not found at $WLS" >&2
  exit 1
fi

find_wolfram() {
  local cmd
  for cmd in wolframscript wolfram math; do
    if command -v "$cmd" >/dev/null 2>&1; then
      echo "$cmd"
      return 0
    fi
  done
  # macOS app-bundle fallbacks
  local p
  for p in \
    /Applications/Mathematica.app/Contents/MacOS/wolframscript \
    /Applications/Wolfram.app/Contents/MacOS/wolframscript \
    /Applications/Wolfram\ Engine.app/Contents/MacOS/wolframscript \
    /Applications/Wolfram*.app/Contents/MacOS/wolframscript \
    /Applications/Mathematica.app/Contents/MacOS/WolframKernel \
    /Applications/Mathematica.app/Contents/MacOS/MathKernel; do
    if [ -x "$p" ]; then
      echo "$p"
      return 0
    fi
  done
  return 1
}

WOLFRAM=$(find_wolfram) || {
  echo "Error: no Wolfram kernel found on PATH (tried: wolframscript, wolfram, math)." >&2
  echo "       Install Wolfram Engine (free), Wolfram Desktop, or Mathematica with a command-line kernel." >&2
  echo "       The desktop Mathematica front-end alone is not sufficient." >&2
  exit 1
}

BASENAME="$(basename "$WOLFRAM")"

case "$BASENAME" in
  wolframscript)
    # wolframscript: -file runs a script; args to the script follow.
    exec "$WOLFRAM" -file "$WLS" "$@"
    ;;
  wolfram|math|WolframKernel|MathKernel)
    # Kernel binaries: -script runs a file. Args go to $ScriptCommandLine.
    exec "$WOLFRAM" -script "$WLS" "$@"
    ;;
  *)
    # Unknown binary — try -script, which works for most kernels.
    exec "$WOLFRAM" -script "$WLS" "$@"
    ;;
esac
