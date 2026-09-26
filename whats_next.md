# cp-self: what's next (written 2026-09-26, post-molt; state updated 2026-09-26 after step 1)

## State

Step 1 below is DONE (2026-09-26): the two Aug 8 docs are committed, skill/distill/SKILL.md now carries the durability gate, the molt-rulings input, and the empty-carry-forward guard, and the emptied carry-forward.md is committed per molt D1.
Next is step 2 (full regeneration) when quota allows.
The vault still has nothing newer than 2026-08-07; do not distill from the Aug 7 evidence - it predates loop-stack, molt, and the Fable 5 to 5.1 shift.
private/molt-rulings-2026-09-26.md holds the owner-accepted rulings the next distill will consume.

## Step 1 prompt (skill upgrade, this host, run any time)

cd ~/repos/cp-self. Finish the Aug 8 session that died here and wire in the molt handoff. Context, all verifiable on disk: git status shows two staged docs from 2026-08-08 (docs/how-to-remember-me.md, docs/ideas/2026-08-08-durable-vs-temporal-distill.md) plus a deliberately emptied skill/distill/carry-forward.md (molt finding D1, 2026-09-26: its ported verification-craft section duplicated the fable manual; the emptiness is final, do not repopulate it). private/molt-rulings-2026-09-26.md holds owner-accepted rulings for the next distill run.

Do, in order:
1. Read docs/ideas/2026-08-08-durable-vs-temporal-distill.md and implement it in skill/distill/SKILL.md: a durability test on every candidate rule (enters the manual only if it would still be true a year from now absent a life change); temporal facts are dropped or emitted to a clearly dated, expiring "current context" section, never into the manual body; optionally have skill/evidence tag candidates durable/temporal at extraction so distill inherits the label.
2. Wire owner rulings into the distill flow: Phase 2 of skill/distill/SKILL.md must also read any private/molt-rulings-*.md files and apply them as binding constraints on the emitted manual (they are owner-accepted audit findings, not evidence; they never resurrect pruned evidence).
3. Guard against the empty-input trip: if the collect/fail-loudly step treats an empty carry-forward.md as a missing input, fix it to accept empty as valid.
4. Leave docs/how-to-remember-me.md untouched - it is a ready-to-paste brainstorm prompt for a separate session, commit it as-is.
5. Commit: the two staged docs as one commit ("docs: durable-vs-temporal idea + remember-me brainstorm prompt, from 2026-08-08 session"), the skill changes as a second ("distill: durability test + owner-rulings input; carry-forward emptied per molt D1"). Plain messages, no co-author line. Do not push; do not run the distill; never hand-edit ~/.claude/self-manual.md.

## Step 2 (full regeneration, when quota allows, after step 1)

1. On RIT-UADV2213: /self-manual-evidence, then ./vault.sh push
2. On RIT-UADV2223 (here): /self-manual-evidence, then ./vault.sh push
3. Here, after both pushes: cd ~/repos/cp-self && ./vault.sh pull, then /self-manual-distill

The distill will then consume the molt rulings and the durability test together.
Note: the live ~/.claude/self-manual.md carries one post-generation hand annotation (2026-09-24 stale-constraint note); the rulings file already retires that constraint, and the distill archives the old manual before overwriting.

## Separate, unscheduled

docs/how-to-remember-me.md is its own /loop-brainstorm session on agentic progression-memory; run it whenever, independent of the pipeline.
