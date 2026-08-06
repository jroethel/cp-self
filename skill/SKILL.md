---
name: self-manual-regen
description: >
  Regenerate Jeremy's self-manual from raw history, not from memory. Use when the user says
  "regenerate my self-manual", "re-extract the operating manual", or "update self-manual", or when
  the lean manual feels stale after months of new sessions. Archives the current manuals, runs a
  clean-room extraction over chat history, distills full-to-lean with carry-forward, reports
  rule-level changes, and stages the install for Jeremy to fire. The irreversible install is always
  Jeremy's trigger, never the skill's.
user-invocable: true
---

# self-manual-regen: re-extract the operating manual from raw history

You regenerate the lean `self-manual.md` that ships into every session by re-reading what Jeremy
actually did, not by editing the existing manual in place.
The current manual is graded against fresh evidence; the clean room never sees the manual it is
grading.

The pipeline position:

```
Phase 1 Archive -> Phase 2 Clean-room extraction -> Phase 3 Distill + port -> Phase 4 Compare -> Phase 5 Review gate + install
```

Three steps are Jeremy's triggers, never the skill's: the install (HC2), the transplant test (HC3),
and any decision to compress rules past the size ceiling (HC1).
Run from the repo root (`~/repos/cp-self`) so relative paths and cwd line up.

## Checklist

Work the phases in order; a phase is done when its gate passes.

1. **Phase 1 Archive** the three live manuals, verified non-empty, before anything else.
2. **Phase 2 Clean-room extraction** of a new full evidence doc, temp-then-mv into place.
3. **Phase 3 Distill + port** into a new lean manual under the size ceiling.
4. **Phase 4 Compare** old vs new and emit the change report with full coverage.
5. **Phase 5 Review gate + install** at HC1, then stage the install (HC2) and the transplant test (HC3).

## Phase 1: Archive

Compute `TODAY=$(date +%F)` and `mkdir -p archive/$TODAY`.
Copy each of `self-manual.md`, `self-manual.full.bak.md`, and `SCAN_LOG.md` that exists into
`archive/$TODAY/`.
Fail loudly and list any expected input that is missing rather than half-archiving; a partial
archive is a defect, not a head start.
Before Phase 2 may start, hard-gate on a post-copy verification that every archived file exists and
is non-empty (`test -s`).

Same-day rerun (expected after a mid-run death): if `archive/$TODAY/` already exists and holds a
valid non-empty set, do not re-archive over it.
Treat the existing archive as the rollback point; restore the live `self-manual.md`,
`self-manual.full.bak.md`, and `SCAN_LOG.md` from it, then re-enter Phase 2.
Never re-archive over a good first archive.

## Phase 2: Clean-room extraction

Run the pinned command from the repo root so its cwd is the repo and its only outputs land there:

```
claude --safe-mode --model claude-opus-4-8 --dangerously-skip-permissions -p "$(cat skill/extraction-prompt.md)"
```

The model pin is on the one line above; tune it there if the judgment-heaviest step needs a
different model.
Safe mode disables all customizations, so the extractor never loads the current manual.
Fallbacks, in order: if the environment rejects `--dangerously-skip-permissions`, rerun with
`--permission-mode bypassPermissions`; if safe mode still restricts history reads, run a bare
`CLAUDE_CONFIG_DIR` sandbox pointed at a copy of the config dir with the manual imports removed.

Write each output to a temp path and `mv into place` only on subprocess success, so a killed run
(quota death) never truncates a live file.
Outputs: the new `self-manual.full.bak.md` and `SCAN_LOG.md`.

Preflight the substance floor before Phase 3 - a silent empty run is a defect, not a pass:
`SCAN_LOG.md` is non-empty and references `.claude/projects` paths;
`self-manual.full.bak.md` is non-empty and not drastically smaller than the archived prior;
a scan that read far fewer files than `archive/$TODAY/SCAN_LOG.md` fails this floor.

## Phase 3: Distill + port

In the main session (not the subprocess), read the new full doc plus `skill/ported.md`.
Write the new lean `self-manual.md` via temp-then-mv: behavior rules only, one sentence per line,
plain dashes.
Stamp its header `extraction <TODAY>` so freshness checks have a distinctive literal.
Append every section from `ported.md` verbatim; the clean room cannot see `ported.md`, so this is
how the Verification craft section survives a regeneration.

Size: keep the file at or under 8192 bytes.
If all classified rules plus the ported sections exceed the ceiling, do not silently drop a rule.
Stop and surface the overflow at HC1 for Jeremy to choose what to compress or merge.

## Phase 4: Compare

Derive the denominator mechanically from the archived old lean manual, not from the new output:

```
N=$(grep -cE '^\s*[-*] |^[0-9]+\. ' archive/$TODAY/self-manual.md)
```

Read that old manual and the new lean manual; emit `CHANGES-<TODAY>.md` with four buckets:
confirmed, new, dropped, contradicted.
Each new rule carries a verbatim evidence quote and its source file.
Each dropped rule carries the question "did behavior actually change?".
Each contradicted rule names the new evidence that points the other way.
Every one of the N old rules appears in exactly one bucket, keyed to a verbatim snippet of that old
rule.
End the report with the line `coverage: N/N old rules classified`, where the printed N equals the
mechanically derived count.

## Phase 5: Review gate + install

Present `CHANGES-<TODAY>.md` at HC1.
HC1 covers two things at once: old-rule classification correctness, and verification that every
new rule's cited evidence quote actually exists in the regenerated `self-manual.full.bak.md` /
`SCAN_LOG.md` (grep each quote).
An unverifiable new-rule quote is a blocking defect that sends the run back to Phase 3, not a
footnote.
If Phase 3 reported a size overflow, Jeremy decides here what to compress or merge.

On approval, stage the exact command for Jeremy (HC2):

```
./install.sh
```

Do not run it; it edits the real `CLAUDE.md` and changes what every future session sees, so it is
his irreversible trigger.
After he installs, assert the import is still single
(`test "$(grep -c 'self-manual.md' ~/.claude/CLAUDE.md)" -eq 1`), then prompt him to run the
transplant test (HC3):

```
claude -p "What should you watch out for when I hand you a plan I'm excited about?"
```

Pass: the answer comes from the manual's intuition map, not generic advice.

## Red flags - stop, you are rationalizing

| Thought                                              | Reality                                         |
|------------------------------------------------------|-------------------------------------------------|
| "I'll edit self-manual.md directly, faster"          | Editing in place grades the manual with itself; |
|                                                      | archive and re-extract                          |
| "The clean room can read the old manual for context" | That defeats the clean room; blindness is the   |
|                                                      | design                                          |
| "The new manual is bigger, I'll trim a rule quietly" | A size overflow surfaces at HC1; never silently |
|                                                      | drop a rule                                     |
| "Extraction returned something, ship it"             | Run the preflight; an empty or tiny run is a    |
|                                                      | defect                                          |
| "Coverage is roughly N"                              | Derive N mechanically with grep -cE; never guess|
|                                                      | the denominator                                 |
| "I'll install now and transplant later"              | Install is Jeremy's trigger (HC2); stage it and |
|                                                      | wait                                            |

## Process flow

```
Archive (verified non-empty) -> Clean-room extract (preflight) -> Distill + port -> Compare (coverage: N/N) -> HC1 -> HC2 install -> HC3 transplant
```
