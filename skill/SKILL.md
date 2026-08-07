---
name: self-manual-regen
description: >
  Regenerate Jeremy's self-manual from raw history, not from memory. Use when the user says
  "regenerate my self-manual", "re-extract the operating manual", or "update self-manual", or when
  the lean manual feels stale after months of new sessions. Archives the current manuals, runs a
  clean-room extraction over chat history, holds for Jeremy's evidence prune, distills full-to-lean
  with carry-forward, reports thematic and rule-level changes, and stages the install for Jeremy to
  fire. The irreversible install is always Jeremy's trigger, never the skill's.
user-invocable: true
---

# self-manual-regen: re-extract the operating manual from raw history

You regenerate the lean `self-manual.md` that ships into every session by re-reading what Jeremy
actually did, not by editing the existing manual in place.
The current manual is graded against fresh evidence; the clean room never sees the manual it is
grading.

The pipeline position:

```
Phase 1 Archive -> Phase 2 Clean-room extraction -> HC0 Evidence prune -> Phase 3 Distill + port -> Phase 4 Compare -> Phase 5 Review gate + install
```

Four steps are Jeremy's triggers, never the skill's: the evidence prune sign-off (HC0), the
install (HC2), the transplant test (HC3), and any contested rule ranking (HC1).
Run from the repo root (`~/create/skills/cp-self`) so relative paths and cwd line up.

## Checklist

Work the phases in order; a phase is done when its gate passes.

1. **Phase 1 Archive** the three live manuals, verified non-empty, before anything else.
2. **Phase 2 Clean-room extraction** of a new full evidence doc, temp-then-mv into place, then
   hold at HC0 for Jeremy's evidence prune.
3. **Phase 3 Distill + port** the post-prune evidence doc into a new lean manual capped at the
   Top 10 rules.
4. **Phase 4 Compare** old vs new lean manuals and emit the change report, thematic delta first,
   with full rule coverage.
5. **Phase 5 Review gate + install** at HC1, then stage the install (HC2) and the transplant test (HC3).

## Phase 1: Archive

Compute `TODAY=$(date +%F)` and `mkdir -p archive/$TODAY`.
Copy each of `self-manual.md`, `self-manual.evidence.md`, and `SCAN_LOG.md` that exists into
`archive/$TODAY/`.
Fail loudly and list any expected input that is missing rather than half-archiving; a partial
archive is a defect, not a head start.
Before Phase 2 may start, hard-gate on a post-copy verification that every archived file exists and
is non-empty (`test -s`).

Same-day rerun (expected after a mid-run death): if `archive/$TODAY/` already exists and holds a
valid non-empty set, do not re-archive over it.
Treat the existing archive as the rollback point; restore the live `self-manual.md`,
`self-manual.evidence.md`, and `SCAN_LOG.md` from it, then re-enter Phase 2.
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
Outputs: the new `self-manual.evidence.md` and `SCAN_LOG.md`.

Preflight the substance floor before Phase 3 - a silent empty run is a defect, not a pass:
`SCAN_LOG.md` is non-empty and references `.claude/projects` paths;
`self-manual.evidence.md` is non-empty and not drastically smaller than the archived prior;
a scan that read far fewer files than `archive/$TODAY/SCAN_LOG.md` fails this floor.

**HC0 - evidence prune (Jeremy's trigger).**
Once the preflight passes, stop and hand the new `self-manual.evidence.md` to Jeremy for review.
This is his editing point: an incident he judges one-off (a single late-night frustration, a
settled quirk) gets deleted from the full doc here, and that deletion is final downstream.
Phase 3 starts only on his go, and distills from the full doc exactly as he left it.

## Phase 3: Distill + port

In the main session (not the subprocess), read the post-prune full doc plus `skill/ported.md`.
The post-prune full doc is the sole evidence source: never re-consult raw history or the archived
manuals to restore evidence Jeremy pruned; a pruned incident must not resurface as a rule.
Write the new lean `self-manual.md` via temp-then-mv: behavior rules only, one sentence per line,
plain dashes.
Stamp its header `extraction <TODAY>` so freshness checks have a distinctive literal.
Append every section from `ported.md` verbatim; the clean room cannot see `ported.md`, so this is
how the Verification craft section survives a regeneration.

Two gates control the manual's size; there is no byte ceiling.

Entry gate - earn-its-line: a rule competes for a slot only if it is backed by evidence in the
post-prune doc AND changes behavior - a competent model without the manual would act differently.
Generic craft ("verify claims", "write tests") is cut on sight.

Capacity gate - Top 10: the manual carries at most 10 behavioral rules, ranked by weight (impact,
frequency, propensity to trip Jeremy up) as ordinal judgment calls with one line of rationale
each - no numeric scoring formula.
The preamble (who Jeremy is, the skill map) is context, not a rule, and is exempt from the count;
so are the ported sections.
A new rule enters only by displacement: name the rule it outranks and why.
Rules keep their section grouping in the manual; the cap is global.
Nothing drops silently: every cut or displaced rule lands in the change report with its weight
call, and contested rankings are Jeremy's to settle at HC1.

## Phase 4: Compare

Read the archived old lean manual and the new lean manual; emit `archive/CHANGES-<TODAY>.md`.
The comparison is always lean-vs-lean: the short manual is the artifact that ships, so it is the
artifact that gets compared.

Lead the report with a thematic delta, because the question Jeremy is answering is "has my style
or ability changed over time?", not "which bullets moved".
Group the changes into themes (e.g. shell/git fluency, planning discipline, scope control,
cost awareness, tone), and for each theme call it strengthened, faded, or held, backed by one
old-vs-new evidence pair.
The displacement log is drift data in its own right: what fell out of the Top 10 since the prior
regen, and what pushed it out, is the sharpest signal of change.

Then the rule-level backstop, so nothing drops silently.
Derive the denominator mechanically from the archived old lean manual, not from the new output:

```
N=$(grep -cE '^\s*[-*] |^[0-9]+\. ' archive/$TODAY/self-manual.md)
```

Classify into four buckets: confirmed, new, dropped, contradicted.
Each new rule carries a verbatim evidence quote and its source file.
Each dropped rule carries either the question "did behavior actually change?" or, if displaced by
ranking, the weight call that outranked it.
Each contradicted rule names the new evidence that points the other way.
Every one of the N old rules appears in exactly one bucket, keyed to a verbatim snippet of that old
rule.
End the report with the line `coverage: N/N old rules classified`, where the printed N equals the
mechanically derived count.

## Phase 5: Review gate + install

Present `CHANGES-<TODAY>.md` at HC1.
HC1 covers two things at once: old-rule classification correctness, and verification that every
new rule's cited evidence quote actually exists in the regenerated `self-manual.evidence.md` /
`SCAN_LOG.md` (grep each quote).
An unverifiable new-rule quote is a blocking defect that sends the run back to Phase 3, not a
footnote.
Contested rankings and displacement calls are settled here; Jeremy owns the final Top 10.

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
| "This rule is good, I'll squeeze in an 11th"         | The cap is the design; entry is by displacement |
|                                                      | with the weight call settled at HC1             |
| "Extraction returned something, ship it"             | Run the preflight; an empty or tiny run is a    |
|                                                      | defect                                          |
| "Jeremy pruned it, but the evidence was strong"      | Pruned is pruned; the post-prune full doc is    |
|                                                      | the only distill source                         |
| "Coverage is roughly N"                              | Derive N mechanically with grep -cE; never guess|
|                                                      | the denominator                                 |
| "I'll install now and transplant later"              | Install is Jeremy's trigger (HC2); stage it and |
|                                                      | wait                                            |

## Process flow

```
Archive (verified non-empty) -> Clean-room extract (preflight) -> HC0 prune -> Distill + port -> Compare (thematic + coverage: N/N) -> HC1 -> HC2 install -> HC3 transplant
```
