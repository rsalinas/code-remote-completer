#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BIN_DIR="$HOME/.local/bin"
COMP_DIR="$HOME/.local/share/bash-completion/completions"

mkdir -p "$BIN_DIR" "$COMP_DIR"
install -m 0755 "$SCRIPT_DIR/code-remote" "$BIN_DIR/code-remote"
install -m 0644 "$SCRIPT_DIR/completions/code-remote.bash" "$COMP_DIR/code-remote"

echo "Instal·lat: $BIN_DIR/code-remote"
echo "Completació: $COMP_DIR/code-remote"
echo "Recorda recarregar Bash: source ~/.bashrc"
