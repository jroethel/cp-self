#!/usr/bin/env bash
# Installs Jeremy's self-manual into a Claude config dir.
# Usage: ./install.sh [config-dir]   (default: ~/.claude)
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)"
DEST="${1:-$HOME/.claude}"

[ -d "$DEST" ] || { echo "error: $DEST does not exist"; exit 1; }

cp "$SRC/self-manual.md" "$DEST/self-manual.md"

CLAUDE_MD="$DEST/CLAUDE.md"
IMPORT_LINE="@$DEST/self-manual.md"
if ! grep -qF "self-manual.md" "$CLAUDE_MD" 2>/dev/null; then
  printf "\n## Jeremy's Manual\nWhen you are working with Jeremy, read this to learn his strengths and how you can best support him:\n%s\n" "$IMPORT_LINE" >> "$CLAUDE_MD"
  echo "added import to $CLAUDE_MD"
else
  echo "import already present in $CLAUDE_MD"
fi

echo "installed: $DEST/self-manual.md"
