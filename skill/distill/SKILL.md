---
name: self-manual-distill
description: >
  Distill the user's collected evidence docs into the lean Top-10 self-manual, compare thematically
  against the prior manual, and stage the install. Run once, on any single host, after
  /self-manual-evidence has run on every host and the per-host evidence files are collected here.
  Use when the user says "distill my self-manual", "regenerate my self-manual", "update
  self-manual", or wants to compare and install a new manual from already-collected evidence.
  The irreversible install is always the user's trigger, never the skill's.
user-invocable: true
---

# self-manual-distill: Top-10 distill, thematic compare, staged install

You turn the collected evidence docs into the lean `self-manual.md` that ships into every session.
Evidence collection is `/self-manual-evidence`, run per host; this skill runs once, on whichever
host holds the collected files.

```
Phase 1 Collect + archive -> HC0 Prune -> Phase 2 Distill + port -> Phase 3 Compare -> Phase 4 HC1 review -> HC2 install -> HC3 transplant
```

Four steps are the owner's triggers, never the skill's: the evidence prune sign-off (HC0), any
contested rule ranking (HC1), the install and propagation (HC2), and the transplant test (HC3).
Run from the repo root (the cp-self clone) so relative paths and cwd line up.
Compute `TODAY=$(date +%F)` up front.

All personal artifacts (evidence docs, scan logs, archives, the lean manual) live in `private/`, a
nested git repo with its own private remote, ignored entirely by the outer skill repo.
The remote only ever sees encrypted `.age` blobs: collection is `./vault.sh pull` (pull-decrypt),
propagation is `./vault.sh push` (encrypt-commit-push); never commit personal data to the outer
repo.

## Phase 1: Collect + archive

`./vault.sh pull` to collect and decrypt what every host pushed.
Pull exactly once, here - never mid-run; a pull overwrites local plaintext, which after HC0 would
clobber the owner's prunes.
List every `private/self-manual.evidence.*.md` present and name the hosts they came from; the
owner confirms the set is complete (all hosts reported in) before anything else happens.
At least one evidence doc must exist; zero is a hard stop pointing at `/self-manual-evidence`.
Read the owner's name from `private/owner.txt`; if it is missing, ask the user and write it, so
the manual is titled for a named person.

Then `mkdir -p private/archive/$TODAY` and copy `private/self-manual.md`, `private/CHANGES.md`
(if present - the prior run's change report), plus every `private/self-manual.evidence*.md` and
`private/SCAN_LOG*.md` into `private/archive/$TODAY/`.
Fail loudly and list any expected input that is missing rather than half-archiving; a partial
archive is a defect, not a head start.
Hard-gate on a post-copy verification that every archived file exists and is non-empty (`test -s`).

Same-day rerun (expected after a mid-run death): if `private/archive/$TODAY/` already holds a
valid non-empty set, do not re-archive over it; treat it as the rollback point, restore the live
files from it, and continue.

## HC0: Evidence prune (the owner's trigger)

Stop and hand every evidence doc to the owner for review.
This is their editing point: an incident they judge one-off (a single late-night frustration, a
settled quirk) gets deleted from the evidence here, and that deletion is final downstream.
Phase 2 starts only on the owner's go, and distills from the evidence exactly as they left it.

## Phase 2: Distill + port

Read every post-prune evidence doc (`private/self-manual.evidence*.md`), plus
`skill/distill/carry-forward.md` and every `private/molt-rulings-*.md` present.
The post-prune evidence docs are the sole evidence source: never re-consult raw history or the
archived manuals to restore evidence the owner pruned; a pruned incident must not resurface as a
rule.
The molt-rulings files are not evidence; they are owner-accepted audit findings, and each ruling is
a binding constraint on the emitted manual: the manual must comply with every ruling, but a ruling
never adds a rule the evidence does not support and never resurrects evidence the owner pruned at
HC0.
Write the new lean `private/self-manual.md` via temp-then-mv: behavior rules only, one sentence per
line, plain dashes.
Title it `<Owner>'s Operating Manual` using the name from `private/owner.txt`, and use the name
throughout where it helps the reader.
Stamp its header `extraction <TODAY>` so freshness checks have a distinctive literal.
Append every section from `carry-forward.md` verbatim; it holds rules about the model's craft, not
about the owner, so the clean room can never regenerate them - this appending is how they survive.
An empty `carry-forward.md` is a valid input, not a missing one: it means nothing currently carries
forward (it was deliberately emptied per molt finding D1), so append nothing and continue.

Three gates control what enters the manual; there is no byte ceiling.

Durability gate: a candidate enters the manual body only if it would still be true a year from now
absent a life change.
Temporal facts (subscriptions, deadlines, live constraints) never enter the manual body: drop them,
or if one is load-bearing, emit it to a "Current context" section at the end of the manual, dated
in its header and clearly marked as expiring.
If the evidence docs tag candidates durable/temporal at extraction, inherit the label; otherwise
judge durability here.

Entry gate - earn-its-line: a rule competes for a slot only if it is backed by evidence in the
post-prune doc AND changes behavior - a competent model without the manual would act differently.
Generic craft ("verify claims", "write tests") is cut on sight.

Capacity gate - Top 10: the manual carries at most 10 behavioral rules, ranked by weight (impact,
frequency, propensity to trip the owner up) as ordinal judgment calls with one line of rationale
each - no numeric scoring formula.
Cross-host recurrence weighs heavily: a pattern that shows up independently in two hosts' evidence
docs outranks a single-host pattern, all else equal.
The preamble (who the owner is, the skill map) is context, not a rule, and is exempt from the
count; so are the carry-forward sections.
A new rule enters only by displacement: name the rule it outranks and why.
Rules keep their section grouping in the manual; the cap is global.
Nothing drops silently: every cut or displaced rule lands in the change report with its weight
call, and contested rankings are the owner's to settle at HC1.

## Phase 3: Compare

Read the archived old lean manual and the new lean manual; emit `private/CHANGES.md`, dated in its
header; it lives beside the scan logs and gets archived into `archive/$TODAY/` by the next run's
Phase 1.
The comparison is always lean-vs-lean: the short manual is the artifact that ships, so it is the
artifact that gets compared.

Lead the report with a thematic delta, because the question the owner is answering is "has my
style or ability changed over time?", not "which bullets moved".
Group the changes into themes (e.g. shell/git fluency, planning discipline, scope control,
cost awareness, tone), and for each theme call it strengthened, faded, or held, backed by one
old-vs-new evidence pair.
The displacement log is drift data in its own right: what fell out of the Top 10 since the prior
regen, and what pushed it out, is the sharpest signal of change.

Then the rule-level backstop, so nothing drops silently.
Derive the denominator mechanically from the archived old lean manual, not from the new output:

```
N=$(grep -cE '^\s*[-*] |^[0-9]+\. ' private/archive/$TODAY/self-manual.md)
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

## Phase 4: Review gate + install

Present `private/CHANGES.md` at HC1.
HC1 covers two things at once: old-rule classification correctness, and verification that every
new rule's cited evidence quote actually exists in the collected `private/self-manual.evidence*.md`
/ `private/SCAN_LOG*.md` files (grep each quote).
An unverifiable new-rule quote is a blocking defect that sends the run back to Phase 2, not a
footnote.
Contested rankings and displacement calls are settled here; the owner owns the final Top 10.

On approval, stage the exact command for the owner (HC2):

```
./install.sh
```

Do not run it; it edits the real `CLAUDE.md` and changes what every future session sees, so it is
the owner's irreversible trigger.
After the owner installs, assert the import is still single
(`test "$(grep -c 'self-manual.md' ~/.claude/CLAUDE.md)" -eq 1`).

Then push the results so every host can pull them - the new manual, the pruned evidence, the
archive, and the change report all travel encrypted in the private repo, so the drift record stays
complete everywhere (this also makes the prunes stick: vault.sh drops blobs whose plaintext is
gone):

```
./vault.sh push
```

If other hosts exist, stage the propagation alongside (also the owner's trigger; it edits each
host's `CLAUDE.md` via its `install.sh`) - on each other host, from its cp-self clone:

```
./vault.sh pull && ./install.sh
```

Then prompt the owner to run the transplant test (HC3):

```
claude -p "What should you watch out for when I hand you a plan I'm excited about?"
```

Pass: the answer comes from the manual's intuition map, not generic advice.

## Red flags - stop, you are rationalizing

| Thought                                              | Reality                                         |
|------------------------------------------------------|-------------------------------------------------|
| "I'll edit self-manual.md directly, faster"          | Editing in place grades the manual with itself; |
|                                                      | distill from collected evidence only            |
| "The owner pruned it, but the evidence was strong"   | Pruned is pruned; the post-prune evidence docs  |
|                                                      | are the only distill source                     |
| "This rule is good, I'll squeeze in an 11th"         | The cap is the design; entry is by displacement |
|                                                      | with the weight call settled at HC1             |
| "Coverage is roughly N"                              | Derive N mechanically with grep -cE; never guess|
|                                                      | the denominator                                 |
| "One host's evidence is missing, close enough"       | The owner confirms the host set at Phase 1; a   |
|                                                      | missing host skews every frequency weight       |
| "I'll install now and transplant later"              | Install is the owner's trigger (HC2); stage it  |
|                                                      | and wait                                        |
