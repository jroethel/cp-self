# cp-self: Jeremy's Operating Manual, Portable

A profile of how Jeremy works, thinks, and decides - extracted 2026-07-16 by Claude Fable 5 from chat histories, learning guides, project docs, plans, and memory files.
Same idea as [cp-fable](../cp-fable): that repo captures how the model should work; this one captures who it is working with.
Injected into `CLAUDE.md` so every session starts already knowing where Jeremy is strong, where he needs backup, and when to push back.

## Contents

| File         | What it is                                                                      |
|--------------|---------------------------------------------------------------------------------|
| `private/`   | Nested private git repo: the manual, evidence docs, scan logs, archives.        |
| `skill/`     | The two regeneration skills: `evidence/` (per host) and `distill/` (once).      |
| `vault.sh`   | Encrypted sync for `private/`: push = encrypt-commit-push, pull = pull-decrypt. |
| `install.sh` | Idempotent installer. Copies the manual + skills, adds one import line.         |

All personal profile data lives in `private/`, a nested git repo the outer repo ignores entirely.
It syncs between hosts through its own private remote (corporate firewalls block scp; git hosting gets through), and the remote only ever sees `age`-encrypted blobs (`private/vault/*.age`).
Files are encrypted to every key in `private/recipients.txt`: each host's passphrase-less age key (`~/.ssh/age.key`) for automation, plus Jeremy's ssh-ed25519 key as break-glass recovery (`age -d -i ~/.ssh/id_ed25519 <blob>`).
Each host writes only its own hostname-stamped files, so pushes never conflict.

## Re-extraction

Rerun when enough new history has accumulated (a few months of sessions) or after a major shift in how you work.
Two skills, matching the two halves of the pipeline:

1. `/self-manual-evidence` - run on **each host** with Claude Code history.
   Archives that host's prior evidence, re-extracts in a clean room (a `claude --safe-mode` subprocess, so the extractor observes the raw history instead of being steered by the rules you already wrote about yourself), and pushes hostname-stamped evidence files to the private repo.
   Pre-push prune: anything that must never reach the remote - even in history - is deleted before the push.
2. `/self-manual-distill` - run **once, on any host**, after every host has pushed.
   Pulls the private repo, holds for your evidence prune, distills the Top-10 lean manual, reports thematic + rule-level changes, and stages `./install.sh` plus the pull-and-install propagation for your approval.

## Install

```bash
./install.sh                    # installs into ~/.claude
./install.sh /path/to/other-dir # if a session uses a non-default CLAUDE_CONFIG_DIR
```

New host setup - `setup-host.sh` mints the host's age key, joins (or creates) the private vault, and registers the host as a recipient:

```bash
brew install age   # or the distro equivalent
git clone https://github.com/jroethel/cp-self.git ~/create/skills/cp-self
cd ~/create/skills/cp-self
./setup-host.sh <private-remote-url>   # omit the URL to start a brand-new vault
# joining an existing vault: on a host that already holds plaintext, rekey with
#   ./vault.sh pull && ./vault.sh push
# then back on the new host:
./vault.sh pull && ./install.sh
```

Public users: fork this repo, run `./setup-host.sh` with no URL, create your own private remote when prompted, then run `/self-manual-evidence` - the extraction prompt scans *your* history, so the manual it builds is about you.

## Verify the transplant took

```bash
claude -p "What should you watch out for when I hand you a plan I'm excited about?"
```

Pass: it answers from the manual's intuition map (specific to Jeremy, not generic advice).
Fail: generic "communicate clearly" boilerplate - tighten the manual and reinstall.
