---
name: self-manual-evidence
description: >
  Per-host clean-room evidence extraction for Jeremy's self-manual. Run on each host where Claude
  Code has chat history: archives that host's prior evidence, scans local history in a safe-mode
  clean room, and emits hostname-stamped evidence files ready to collect for /self-manual-distill.
  Use when the user says "collect self-manual evidence", "scan this host's history", "run the
  evidence extraction", or kicks off a self-manual regeneration on any host. Never distills or
  installs anything - that is /self-manual-distill's job.
user-invocable: true
---

# self-manual-evidence: clean-room evidence extraction, per host

You produce this host's evidence files for Jeremy's self-manual.
You never distill, compare, or install - that is `/self-manual-distill`, run once on one host after
every host's evidence is collected there.
The extraction is a clean room: the extractor observes raw history and never reads the manuals it
is grading.

```
Phase 1 Archive -> Phase 2 Clean-room extract -> Phase 3 Rename + preflight -> Hand off
```

Run from the repo root (`~/create/skills/cp-self`) so relative paths and cwd line up.
Compute once, up front: `TODAY=$(date +%F)` and `HOST=$(hostname -s)`.

## Phase 1: Archive

`mkdir -p archive/$TODAY`, then copy every `self-manual.evidence*.md` and `SCAN_LOG*.md` that
exists into `archive/$TODAY/`.
A fresh host with no prior evidence archives nothing; that is fine.
Whatever was copied must verify non-empty (`test -s`) before Phase 2 starts; a partial archive is
a defect, not a head start.

Same-day rerun (expected after a mid-run death): if `archive/$TODAY/` already holds this host's
valid non-empty evidence files, do not re-archive over them.
Treat that archive as the rollback point; restore the live evidence files from it, then re-enter
Phase 2.

## Phase 2: Clean-room extraction

Run the pinned command from the repo root so its cwd is the repo and its only outputs land there:

```
claude --safe-mode --model claude-opus-4-8 --dangerously-skip-permissions -p "$(cat skill/evidence/extraction-prompt.md)"
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

Stamp the outputs with this host, unconditionally - even on a single-host setup, so downstream
globs and provenance stay uniform:

```
mv self-manual.evidence.md self-manual.evidence.$HOST.md
mv SCAN_LOG.md SCAN_LOG.$HOST.md
```

Then preflight the substance floor - a silent empty run is a defect, not a pass:
`SCAN_LOG.$HOST.md` is non-empty and references `.claude/projects` paths;
`self-manual.evidence.$HOST.md` is non-empty and not drastically smaller than this host's archived
prior;
a scan that read far fewer files than this host's archived prior scan log fails this floor.
The floor is always per host: never compare against another host's files.

## Hand off

If this host will run the distill: nothing to move; invoke `/self-manual-distill` once every other
host has reported in.
Otherwise, stage the exact transfer for Jeremy:

```
scp self-manual.evidence.$HOST.md SCAN_LOG.$HOST.md <distill-host>:~/create/skills/cp-self/
```

Never transport evidence via git; the files are gitignored on purpose (personal profile data stays
out of the repo).

## Red flags - stop, you are rationalizing

| Thought                                              | Reality                                         |
|------------------------------------------------------|-------------------------------------------------|
| "The clean room can read the old manual for context" | That defeats the clean room; blindness is the   |
|                                                      | design                                          |
| "Extraction returned something, ship it"             | Run the preflight; an empty or tiny run is a    |
|                                                      | defect                                          |
| "Single host, skip the hostname rename"              | Stamp it anyway; distill globs and provenance   |
|                                                      | depend on uniform names                         |
| "Evidence is ready, I'll go ahead and distill"       | Distill is /self-manual-distill, once, after    |
|                                                      | every host reports in                           |
