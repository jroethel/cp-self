#!/usr/bin/env bash
# Encrypted sync for private/: plaintext stays local, git only ever sees .age blobs.
# Encrypts to every pubkey in private/recipients.txt: each host's passphrase-less
# age key (~/.ssh/age.key, automation) AND optionally the owner's ssh-ed25519 key
# (break-glass recovery: age -d -i ~/.ssh/id_ed25519 <blob>, passphrase prompt).
# Add a host = age-keygen -o ~/.ssh/age.key there, append its age pubkey + ssh
# pubkey to recipients.txt, then push from any host holding plaintext (rekeys all).
# Usage: ./vault.sh push | ./vault.sh pull
# ponytail: mtime-based change detection; pull overwrites local plaintext with
# pulled versions, so pull once before editing, push when done, never pull mid-edit.
set -euo pipefail
cd "$(dirname "$0")/private"
KEY="$HOME/.ssh/age.key"
REC="recipients.txt"

case "${1:-}" in
push)
  # encrypt new/changed plaintext; recipients.txt change rekeys everything
  find . \( -path ./vault -o -path ./.git \) -prune -o -type f \
       ! -name .gitignore ! -name "$REC" -print | while read -r f; do
    rel="${f#./}"
    out="vault/$rel.age"
    if [ ! -e "$out" ] || [ "$f" -nt "$out" ] || [ "$REC" -nt "$out" ]; then
      mkdir -p "$(dirname "$out")"
      age -R "$REC" -o "$out" "$f"
      echo "encrypted: $rel"
    fi
  done
  # drop blobs whose plaintext is gone (pruned evidence stays pruned)
  [ -d vault ] && find vault -type f -name '*.age' | while read -r v; do
    rel="${v#vault/}"; rel="${rel%.age}"
    [ -e "$rel" ] || { rm -f "$v"; echo "removed: $rel"; }
  done
  git add -A
  git diff --cached --quiet || git commit -m "vault: $(hostname -s) $(date +%F)"
  git push
  ;;
pull)
  git pull --rebase
  find vault -type f -name '*.age' | while read -r v; do
    rel="${v#vault/}"; rel="${rel%.age}"
    if [ ! -e "$rel" ] || [ "$v" -nt "$rel" ]; then
      mkdir -p "$(dirname "$rel")"
      age -d -i "$KEY" -o "$rel" "$v"
      echo "decrypted: $rel"
    fi
  done
  ;;
*)
  echo "usage: $0 push|pull" >&2
  exit 1
  ;;
esac
