#!/usr/bin/env bash
# Installs the owner's self-manual into a Claude config dir.
# Usage: ./install.sh [config-dir]   (default: ~/.claude)
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)"
DEST="${1:-$HOME/.claude}"

[ -d "$DEST" ] || { echo "error: $DEST does not exist"; exit 1; }

cp "$SRC/private/self-manual.md" "$DEST/self-manual.md"

mkdir -p "$DEST/skills"
rm -rf "$DEST/skills/self-manual-regen" "$DEST/skills/self-manual-evidence" "$DEST/skills/self-manual-distill"
cp -R "$SRC/skill/evidence" "$DEST/skills/self-manual-evidence"
cp -R "$SRC/skill/distill" "$DEST/skills/self-manual-distill"
echo "installed: $DEST/skills/self-manual-evidence"
echo "installed: $DEST/skills/self-manual-distill"

CLAUDE_MD="$DEST/CLAUDE.md"
IMPORT_LINE="@$DEST/self-manual.md"
NAME="$(cat "$SRC/private/owner.txt" 2>/dev/null || echo "the user")"
if ! grep -qF "self-manual.md" "$CLAUDE_MD" 2>/dev/null; then
  printf "\n## Operating Manual\nWhen you are working with %s, read this manual to learn their strengths and how you can best support them:\n%s\n" "$NAME" "$IMPORT_LINE" >> "$CLAUDE_MD"
  echo "added import to $CLAUDE_MD"
else
  echo "import already present in $CLAUDE_MD"
fi

echo "installed: $DEST/self-manual.md"
