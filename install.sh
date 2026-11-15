#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE="$SCRIPT_DIR/backend-cloud-troubleshoot-guide.sh"
INSTALL_DIR="$HOME/.local/bin"
COMMAND_NAME="guide"
FORCE="no"
UNINSTALL="no"
MARKER="Cloud Backend Troubleshooting Guide"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|--dir)
      [[ $# -ge 2 ]] || { echo "Error: --dir needs a folder"; exit 1; }
      INSTALL_DIR="$2"; shift 2 ;;
    -f|--force)     FORCE="yes"; shift ;;
    -u|--uninstall) UNINSTALL="yes"; shift ;;
    -h|--help)
      echo "Usage: ./install.sh [--dir DIR] [--force] [--uninstall]"
      echo "Installs the guide as the 'guide' command in ~/.local/bin (or DIR)."
      exit 0 ;;
    *) echo "Error: unknown option: $1 (try --help)"; exit 1 ;;
  esac
done

TARGET="$INSTALL_DIR/$COMMAND_NAME"

is_ours() { [[ -f "$1" ]] && grep -q "$MARKER" "$1"; }

if [[ "$UNINSTALL" == "yes" ]]; then
  if [[ ! -e "$TARGET" ]]; then
    echo "Nothing to remove: $TARGET does not exist."
    exit 0
  fi
  if ! is_ours "$TARGET"; then
    echo "Refusing to remove $TARGET: it is not the troubleshooting guide."
    exit 1
  fi
  echo "WARNING: deleting $TARGET"
  rm -- "$TARGET"
  echo "Removed. The 'guide' command is gone."
  exit 0
fi

[[ -f "$SOURCE" ]] || { echo "Error: can't find $SOURCE"; exit 1; }

if [[ -e "$TARGET" ]] && ! is_ours "$TARGET" && [[ "$FORCE" == "no" ]]; then
  echo "Error: $TARGET already exists and is not this guide."
  echo "Use --force to replace it, or --dir to install somewhere else."
  exit 1
fi

existing="$(command -v "$COMMAND_NAME" 2>/dev/null || true)"
if [[ -n "$existing" && "$existing" != "$TARGET" ]]; then
  echo "Note: another '$COMMAND_NAME' already exists at: $existing"
  echo "      Whichever folder comes first in your PATH will run when you type '$COMMAND_NAME'."
fi

mkdir -p "$INSTALL_DIR"
cp "$SOURCE" "$TARGET"
chmod +x "$TARGET"
echo "Installed: $TARGET"

case ":$PATH:" in
  *":$INSTALL_DIR:"*)
    echo "Done. Type '$COMMAND_NAME' in a terminal to open the guide." ;;
  *)
    echo ""
    echo "$INSTALL_DIR is not on your PATH yet. Add this line to your ~/.bashrc"
    echo "(or ~/.zshrc on macOS), then open a new terminal:"
    echo ""
    echo "    export PATH=\"$INSTALL_DIR:\$PATH\""
    echo ""
    echo "After that, type '$COMMAND_NAME' to open the guide." ;;
esac
