#!/usr/bin/env bash
# One-time host setup for cp-self.
# Usage: ./setup-host.sh <private-remote-url>   join an existing private vault
#        ./setup-host.sh                        start a brand-new private vault
set -euo pipefail
cd "$(dirname "$0")"

command -v git >/dev/null || { echo "error: install git first"; exit 1; }
command -v age >/dev/null || { echo "error: install age first (brew install age / apt install age)"; exit 1; }

# per-host age key (passphrase-less; protected by file perms + disk encryption)
if [ ! -f "$HOME/.ssh/age.key" ]; then
  mkdir -p "$HOME/.ssh"
  age-keygen -o "$HOME/.ssh/age.key"
  chmod 600 "$HOME/.ssh/age.key"
  echo "minted host key: $HOME/.ssh/age.key"
fi
PUB=$(grep 'public key' "$HOME/.ssh/age.key" | sed 's/# public key: //')

# private vault repo: clone to join, init to start fresh
if [ ! -d private ]; then
  if [ -n "${1:-}" ]; then
    git clone "$1" private
  else
    mkdir private
    git -C private init -b master
    printf '/*\n!/vault/\n!/recipients.txt\n!/.gitignore\n' > private/.gitignore
  fi
fi

# register this host as a recipient
touch private/recipients.txt
if ! grep -qF "$PUB" private/recipients.txt; then
  echo "$PUB" >> private/recipients.txt
  git -C private add -A
  git -C private commit -m "recipients: add $(hostname -s)"
  git -C private push 2>/dev/null || \
    echo "note: no remote yet - create one: gh repo create <name> --private --source private --remote origin --push"
fi

echo "this host's recipient key: $PUB"
echo ""
echo "next steps:"
echo "  joined an existing vault? on a host that already holds plaintext, run:"
echo "      ./vault.sh pull && ./vault.sh push     # rekeys blobs so this host can decrypt"
echo "    then back here:"
echo "      ./vault.sh pull && ./install.sh"
echo "  brand-new vault? run /self-manual-evidence in a claude session to produce your first evidence."
