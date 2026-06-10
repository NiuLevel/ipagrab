#!/usr/bin/env bash
# Installs (or uninstalls) `ipagrab` as a global command by symlinking this
# repo's script into a directory on your PATH. Run:  ./install.sh
# Uninstall with:  ./install.sh uninstall
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$DIR/ipagrab"
NAME="ipagrab"

# Pick a target bin dir: prefer an existing, writable one already on PATH.
on_path() { case ":$PATH:" in *":$1:"*) return 0;; *) return 1;; esac; }
pick_bindir() {
  local d
  for d in /opt/homebrew/bin /usr/local/bin "$HOME/.local/bin" "$HOME/bin"; do
    [ -d "$d" ] && [ -w "$d" ] && on_path "$d" && { echo "$d"; return; }
  done
  # nothing suitable writable & on PATH -> fall back to ~/.local/bin
  mkdir -p "$HOME/.local/bin"; echo "$HOME/.local/bin"
}

if [ "$1" = "uninstall" ]; then
  removed=0
  for d in /opt/homebrew/bin /usr/local/bin "$HOME/.local/bin" "$HOME/bin"; do
    if [ -L "$d/$NAME" ]; then rm -f "$d/$NAME" && echo "Removed $d/$NAME" && removed=1; fi
  done
  [ "$removed" = 0 ] && echo "No $NAME symlink found."
  exit 0
fi

[ -f "$SRC" ] || { echo "error: $SRC not found"; exit 1; }
chmod +x "$SRC"

BIN="$(pick_bindir)"
ln -sf "$SRC" "$BIN/$NAME"

echo "Installed: $BIN/$NAME -> $SRC"
if on_path "$BIN"; then
  echo "Done. Open a new terminal (or run \`hash -r\`) and type: $NAME"
else
  echo
  echo "NOTE: $BIN is not on your PATH yet. Add this to your shell profile:"
  echo "    export PATH=\"$BIN:\$PATH\""
  echo "Then open a new terminal and type: $NAME"
fi
