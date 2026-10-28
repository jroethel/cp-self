---
name: self-manual-evidence
description: >
  Per-host clean-room evidence extraction for the user's self-manual. Run on each host where
  Claude Code has chat history: archives that host's prior evidence, scans local history in a
  safe-mode clean room, and emits hostname-stamped evidence files ready to collect for
  /self-manual-distill. Use when the user says "collect self-manual evidence", "scan this host's
  history", "run the evidence extraction", or kicks off a self-manual regeneration on any host.
  Never distills or installs anything - that is /self-manual-distill's job.
user-invocable: true
---

# self-manual-evidence: clean-room evidence extraction, per host

You produce this host's evidence files for the owner's self-manual.
You never distill, compare, or install - that is `/self-manual-distill`, run once on one host after
every host's evidence is collected there.
The extraction is a clean room: the extractor observes raw history and never reads the manuals it
is grading.

```
Phase 0 Owner identity -> Phase 1 Archive -> Phase 2 Clean-room extract -> Phase 3 Rename + preflight -> Hand off
```

Run from the repo root (the cp-self clone) so relative paths and cwd line up.
Compute once, up front: `TODAY=$(date +%F)` and `HOST=$(hostname -s)`.

All personal artifacts (evidence docs, scan logs, archives, the lean manual) live in `private/`, a
nested git repo with its own private remote, ignored entirely by the outer skill repo.
The remote only ever sees encrypted `.age` blobs: `./vault.sh push|pull` handles
encrypt-commit-push and pull-decrypt, and plaintext exists only on the hosts.
Each host writes only its own hostname-stamped files, so pushes never conflict by construction.

## Phase 0: Owner identity

Read the owner's name from `private/owner.txt`.
If the file is missing, ask the user for their name, confirm the spelling back to them, and write
it to `private/owner.txt`; it syncs across hosts through the vault like every other private file.
The name is injected into the extraction prompt so the evidence doc and the manual built from it
speak about a named person, not a generic "the user".

## Phase 1: Archive

`./vault.sh pull` first, so this host sees the current shared state (pull once, up front - never
mid-run; a pull overwrites local plaintext with pulled versions).
Then `mkdir -p private/archive/$TODAY` and copy this host's `self-manual.evidence.$HOST.md` and
`SCAN_LOG.$HOST.md` that exist into `private/archive/$TODAY/`.
A fresh host with no prior evidence archives nothing; that is fine.
Whatever was copied must verify non-empty (`test -s`) before Phase 2 starts; a partial archive is
a defect, not a head start.

Same-day rerun (expected after a mid-run death): if `private/archive/$TODAY/` already holds this
host's valid non-empty evidence files, do not re-archive over them.
Treat that archive as the rollback point; restore the live evidence files from it, then re-enter
Phase 2.

## Phase 2: Clean-room extraction

Run the pinned command from the repo root so its cwd is the repo and its only outputs land there:

```
claude --safe-mode --model opus --dangerously-skip-permissions -p "My name is $(cat private/owner.txt). $(cat skill/evidence/extraction-prompt.md)"
```

The model pin is on the one line above; tune it there if the judgment-heaviest step needs a
different model.
Safe mode disables all customizations, so the extractor never loads the current manual.
Fallbacks, in order: if the environment rejects `--dangerously-skip-permissions`, rerun with
`--permission-mode bypassPermissions`; if safe mode still restricts history reads, run a bare
`CLAUDE_CONFIG_DIR` sandbox pointed at a copy of the config dir with the manual imports removed.

The subprocess writes `self-manual.evidence.md` and `SCAN_LOG.md` into the cwd.
Do not touch them until the subprocess exits successfully, so a killed run (quota death) never
truncates an archived-and-restorable state.

## Phase 3: Rename + preflight

Stamp the outputs with this host and move them into the private repo, unconditionally - even on a
single-host setup, so downstream globs and provenance stay uniform:

```
mv self-manual.evidence.md private/self-manual.evidence.$HOST.md
mv SCAN_LOG.md private/SCAN_LOG.$HOST.md
```

Then preflight the substance floor - a silent empty run is a defect, not a pass:
`private/SCAN_LOG.$HOST.md` is non-empty and references `.claude/projects` paths;
`private/self-manual.evidence.$HOST.md` is non-empty and not drastically smaller than this host's
archived prior;
a scan that read far fewer files than this host's archived prior scan log fails this floor.
The floor is always per host: never compare against another host's files.

## Hand off

First, the pre-push prune: anything that must never reach the private remote at all - not even in
history - gets deleted from this host's evidence file NOW, before the push.
The HC0 prune on the distill host cleans the working tree; git history is forever.
Offer the owner the file for a quick look before staging the push.

Then sync - encryption, commit, and push in one step; the remote only ever sees ciphertext:

```
./vault.sh push
```

Never commit personal data to the outer skill repo; `private/` is ignored there on purpose, and
plaintext inside `private/` is ignored by the private repo too - only `vault/*.age` is tracked.
When every host has pushed, invoke `/self-manual-distill` on whichever host will distill.

## Red flags - stop, you are rationalizing

| Thought                                              | Reality                                         |
|------------------------------------------------------|-------------------------------------------------|
| "The clean room can read the old manual for context" | That defeats the clean room; blindness is the   |
|                                                      | design                                          |
| "Extraction returned something, ship it"             | Run the preflight; an empty or tiny run is a    |
|                                                      | defect                                          |
| "Single host, skip the hostname rename"              | Stamp it anyway; distill globs and provenance   |
|                                                      | depend on uniform names                         |
| "I'll commit another host's file too, tidier"        | Each host pushes only its own stamped files;    |
|                                                      | that is what keeps pushes conflict-free         |
| "Evidence is ready, I'll go ahead and distill"       | Distill is /self-manual-distill, once, after    |
|                                                      | every host reports in                           |
