#!/usr/bin/env bash
# Installs (or uninstalls) `ipagrab` as a global command by symlinking this
# repo's script into a directory on your PATH. Run:  ./install.sh
# Uninstall with:  ./install.sh uninstall
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$DIR/ipagrab"
NAME="ipagrab"
TARGET=""

# Pick a target bin dir: prefer an existing, writable one already on PATH.
on_path() { case ":$PATH:" in *":$1:"*) return 0;; *) return 1;; esac; }
points_to_source() { [ -L "$1" ] && [ "$(readlink "$1")" = "$SRC" ]; }
pick_bindir() {
  local d
  for d in /opt/homebrew/bin /usr/local/bin "$HOME/.local/bin" "$HOME/bin"; do
    [ -d "$d" ] && [ -w "$d" ] && on_path "$d" && { echo "$d"; return; }
  done
  # nothing suitable writable & on PATH -> fall back to ~/.local/bin
  mkdir -p "$HOME/.local/bin"; echo "$HOME/.local/bin"
}

[ "$#" -le 1 ] || { echo "error: usage: ./install.sh [uninstall]" >&2; exit 2; }
case "${1:-}" in
  ''|uninstall) ;;
  *) echo "error: usage: ./install.sh [uninstall]" >&2; exit 2;;
esac

if [ "${1:-}" = "uninstall" ]; then
  removed=0
  for d in /opt/homebrew/bin /usr/local/bin "$HOME/.local/bin" "$HOME/bin"; do
    on_path "$d" || [ "$d" = "$HOME/.local/bin" ] || continue
    TARGET="$d/$NAME"
    if points_to_source "$TARGET"; then rm -f "$TARGET" && echo "Removed $TARGET" && removed=1; fi
  done
  [ "$removed" = 0 ] && echo "No $NAME link for this checkout found."
  exit 0
fi

[ -f "$SRC" ] || { echo "error: $SRC not found"; exit 1; }
chmod +x "$SRC"

BIN="$(pick_bindir)"
TARGET="$BIN/$NAME"
if [ -e "$TARGET" ] || [ -L "$TARGET" ]; then
  if points_to_source "$TARGET"; then
    echo "Already installed: $TARGET -> $SRC"
  else
    echo "error: refusing to overwrite existing path: $TARGET" >&2
    exit 1
  fi
else
  ln -s "$SRC" "$TARGET"
  echo "Installed: $TARGET -> $SRC"
fi

if on_path "$BIN"; then
  echo "Done. Open a new terminal (or run \`hash -r\`) and type: $NAME"
else
  echo
  echo "NOTE: $BIN is not on your PATH yet. Add this to your shell profile:"
  echo "    export PATH=\"$BIN:\$PATH\""
  echo "Then open a new terminal and type: $NAME"
fi
