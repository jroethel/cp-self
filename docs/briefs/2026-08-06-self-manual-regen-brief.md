# Brief: self-manual regeneration skill

Date: 2026-08-06.
Stage: idea brief (loop-brainstorm output); implementation belongs to /loop-plan.

## Outcome

A repeatable regeneration lifecycle for the self-manual: one skill invocation archives the current manuals, re-extracts from raw history in a clean room, distills full to lean with carry-forward of non-evidence sections, reports rule-level changes, and installs after Jeremy's approval.
Presupposition verdict: "this skill" is today a prompt embedded in README.md, not a skill; evolving it means promoting it to a real skill that wraps that prompt.

## End artifact

A new skill (name TBD, e.g. `self-manual-regen`) in `~/.claude/skills/`.
From its first run: a fresh installed `self-manual.md`, regenerated `self-manual.full.bak.md` and `SCAN_LOG.md`, and a `CHANGES-2026-08-06.md` report.

## Done looks like

Jeremy invokes the skill in a normal session.
It archives the current manuals, runs the extraction headlessly in a clean room, distills, and presents the change report.
Jeremy approves; it reruns `./install.sh`.
Verify with the README's transplant test: `claude -p "What should you watch out for when I hand you a plan I'm excited about?"`.

## Assets and options

- README extraction prompt: becomes the clean-room payload, owned by the skill; README points to the skill. Chosen.
- `claude --safe-mode -p`: the clean-room transport so the extractor never sees the current manual. Chosen, but unverified (see Known vs guessed).
- `install.sh`: reused unchanged as the install step. Chosen.
- git as archive mechanism: declined - manuals are gitignored by design (privacy stance); dated archive dirs (`archive/<date>/`, gitignored) instead.
- cp-fable "Verification craft" section: carry-forward content, marked so the distiller preserves it instead of losing it. Chosen.
- Incremental scan (only history since 2026-07-17): declined - full re-scan, because behavior can change rather than just accumulate; the semantic diff absorbs the noise.

## Approach

Chosen: a skill that wraps a headless clean-room extraction, produces full + lean in one run, and compares via a semantic rule-level report (confirmed / new-with-evidence / dropped / contradicted), gated on Jeremy's review before install.
Alternatives considered and rejected at decision time:
- README-prompt-only evolution: keeps the manual two-terminal dance.
- In-session extraction with CLAUDE.md loaded: the manual grades its own homework (self-confirmation bias).
- Lean-only extraction: loses the audit trail that lets a rule be challenged later.
- Plain text diff as the comparison: a regeneration rephrases everything, so the diff is ~100% noise.
Context finding that shaped the approach: the current lean manual contains a section ("Verification craft", ported from cp-fable) that is absent from the full evidence doc, so a naive regenerate-and-distill would silently lose it; carry-forward must be first-class.
Reduction rationale (from the full-vs-lean comparison): the lean doc exists because the manual is injected into every session; evidence was externalized to the bak file and only behavior directives were kept.

## Success criteria

- [executed-check] `archive/<date>/` contains the prior `self-manual.md`, `self-manual.full.bak.md`, and `SCAN_LOG.md` before anything is overwritten.
- [executed-check] The new lean manual still contains the carried-forward Verification craft section (grep).
- [executed-check] The lean manual stays at or under 8KB.
- [executed-check] The change report covers every rule from the old lean manual (coverage check).
- [executed-check] The import line appears exactly once in CLAUDE.md after install.
- [judgment] Each old rule's classification (confirmed / dropped / contradicted) is correct; reformulation attempted, but classification correctness is inherently Jeremy's read.
- [judgment] The transplant test answers from the manual, not generically.

## Seams

Blast-radius order; each independently checkable.
1. Archive step.
2. Clean-room extraction (full doc + scan log).
3. Distillation + carry-forward.
4. Semantic comparison report.
5. Review gate + install.
A failure in seam 2 leaves seam 1's archive intact.

## Known vs guessed

- Verified this session: the manuals are gitignored; the lean doc contains a section absent from the full doc; install.sh has an idempotency guard; the current mechanism is a README prompt.
- Believed-unchecked: `claude --safe-mode` works headless (`-p`) with enough file permissions to scan `~/.claude/projects/`. If wrong, seam 2 swaps to a bare `CLAUDE_CONFIG_DIR` sandbox; nothing else breaks.
- Guessed: three weeks of new history is enough for a meaningful first report. If wrong, the report says "mostly confirmed", which is an acceptable shakedown of the machinery.

## Parking lot

- Restore the dropped "oooh.." delight signal to the lean manual?
- Multi-machine flow (the scp-to-machine-2 path) after a regeneration.
- Archive retention (keep every run forever vs prune).

## Out of scope

- Changing the privacy stance: manuals stay out of git.
- Editing cp-fable.
- Touching the loop-stack managed block in CLAUDE.md.

## Open questions for planning

- Exact clean-room invocation and permission flags.
- How carry-forward sections are marked (inline marker vs a separate `ported.md`).
- Skill name.
- Whether the change report also gets a lavish-rendered view.
