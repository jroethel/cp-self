# Self-Manual Regeneration Skill Implementation Plan

> For executors: tasks use checkbox syntax; execute in dependency order; a task is done when its
> acceptance check passes. No specific tooling, harness, or skills are assumed.

**Goal:** Promote the README re-extraction prompt into a real, version-controlled skill that archives the current manuals, re-extracts from raw history in a clean room, distills full-to-lean with carry-forward, reports rule-level changes, and installs after Jeremy's approval.
**Approach:** A skill directory in the cp-self repo holds the procedure (`SKILL.md`), the clean-room extraction payload (`extraction-prompt.md`), and the carry-forward content (`ported.md`); `install.sh` copies both the skill and the manual into a Claude config dir; the first live run is a shakedown that proves the machinery against real history.
The clean room (`claude --safe-mode`) runs the extraction with all customizations disabled so the extractor never sees the manual it is grading; distillation and comparison run in the main session because they must read the old lean manual and the ported content the clean room deliberately cannot.
**Tech stack:** Bash, Markdown, the `claude` CLI (v2.1.202, `--safe-mode` and `-p/--print` confirmed present).
**Source brief:** `docs/briefs/2026-08-06-self-manual-regen-brief.md`.

## Global constraints

- Manuals stay out of git: `self-manual.md`, `self-manual.full.bak.md`, `SCAN_LOG.md` are gitignored; the skill source (`skill/`) contains no profile data and IS tracked.
- Archives hold profile data: `archive/` is gitignored.
- The lean manual (`self-manual.md`) must stay at or under 8192 bytes (context-budget ceiling; it is injected into every session).
- The import line must appear exactly once in the target `CLAUDE.md` after install (baseline count is 1; the check guards against duplication).
- The clean-room run pins its model explicitly with `--model` (safe-mode may reset the default, and the extraction is the judgment-heaviest step); the pinned value lives on one line in `SKILL.md` and is tunable there.
- The clean-room subprocess runs unsandboxed with `--dangerously-skip-permissions` and scans the most PII-dense location on the machine; its scope is enforced only by the prompt, so the prompt must constrain it to writing exactly the two named output files, with the repo root as cwd, and must not modify any git-tracked file.
- One sentence per line, plain dashes, in every Markdown file this plan creates or edits.
- Do not touch the `loop-stack (managed)` block in the global `CLAUDE.md`; do not edit cp-fable.

## Open questions resolved (were in the brief)

- Clean-room invocation: `claude --safe-mode --model claude-opus-4-8 --dangerously-skip-permissions -p "$(cat <prompt>)"`, run with the repo as cwd; fallback `--permission-mode bypassPermissions` if the environment rejects the skip flag; second fallback, if safe-mode still restricts history reads, is a bare `CLAUDE_CONFIG_DIR` sandbox pointed at a copy of the config dir with the manual imports removed.
- Carry-forward marking: a standalone `skill/ported.md` appended verbatim by the distiller, chosen over an inline marker because a clean-room regeneration never sees the old lean manual, so an inline marker there would not survive.
- Skill name: `self-manual-regen`.
- Lavish-rendered change report: no for v1, Markdown only; parked (the report is read once at a review gate, and lavish would add a dependency).

## Dependency graph

```
Task 1 (payload files) ──> Task 2 (SKILL.md) ──> Task 3 (wiring: install.sh, README, .gitignore) ──> Task 4 (shakedown run + verify)
```

Strictly linear; no two tasks are parallel-eligible (each consumes the file layout or contract the prior one fixes).
The chain is short because the artifact is a single small skill; the brief's five seams map onto phases inside Task 2's procedure, not onto separate build tasks, because they share one owner file (`SKILL.md`) and a shared file cannot be split across parallel tasks.

## Human checkpoints

- HC1 (in Task 4): Jeremy reviews the `CHANGES-<date>.md` report, confirms each old rule's classification (confirmed / new / dropped / contradicted) is correct, and verifies that every NEW rule's cited evidence quote actually exists in the regenerated sources (an unverifiable quote is a blocking defect); if Phase 3 flagged a size overflow, he decides what to compress.
  This is the brief's `[judgment]` criterion on classification correctness plus the anti-hallucination gate; it never routes to an automated check.
- HC2 (in Task 4): the install step edits the target `CLAUDE.md` and changes what every future session sees; it is Jeremy's irreversible trigger.
  The skill stages the exact `./install.sh` command and waits; Jeremy runs it.
- HC3 (in Task 4): after install, Jeremy runs the transplant test and confirms the answer comes from the manual, not generic advice.
  This is the brief's `[judgment]` transplant criterion.

## How to run

From the repo root (`~/repos/cp-self`):

```bash
# Lint the skill frontmatter and body (no external tools; pure grep/test assertions in each task).
# Install into a throwaway config dir for testing:
bash install.sh /tmp/regen-test-claude
# Invoke the skill in a normal Claude Code session by typing:  /self-manual-regen
```

The clean-room extraction step is run by the skill itself; its literal command is pinned in Task 2's contract.

---

### Task 1: Extraction payload and carry-forward content

Depends on: none

**Files (exclusive ownership):**
- Create: `skill/extraction-prompt.md`
- Create: `skill/ported.md`
- Test: inline bash assertion (below)

**Interfaces:**
- Produces: `skill/extraction-prompt.md` - the self-contained clean-room payload; it instructs the extractor to scan history and write exactly two files (`self-manual.full.bak.md`, `SCAN_LOG.md`) into its cwd, carries an explicit blindness clause (it may read the global `CLAUDE.md` rules as evidence but must never open `self-manual.md`, `self-manual.full.bak.md`, or any file `@`-imported under the "Jeremy's Manual" section, because those are the artifact being graded), a write-scope clause (write only those two files, at repo-root cwd, never modify a git-tracked file), and NOTHING about the main-session steps that follow.
- Produces: `skill/ported.md` - one or more full Markdown sections (each a `## ` heading + body) that originate outside the extraction and must be appended verbatim to the regenerated lean manual; v1 content is the current `## Verification craft (ported from the Fable manual)` section, copied verbatim from `self-manual.md`.

**Acceptance check:** the assertion block below exits 0 `[executed-check]`

```bash
set -e
# Payload scopes the clean room to extraction only.
grep -q "SCAN_LOG.md" skill/extraction-prompt.md
grep -q "self-manual.full.bak.md" skill/extraction-prompt.md
grep -q "user messages only" skill/extraction-prompt.md
# Blindness clause: extractor must not open the manual it is grading.
grep -qi "never open" skill/extraction-prompt.md
grep -qi "Jeremy's Manual" skill/extraction-prompt.md
# Payload must NOT carry main-session concerns. `! grep` is inert under `set -e`,
# so use an explicit fail path; the pattern targets only unambiguous main-session tokens.
if grep -qiE "install\.sh|change report|distillation step" skill/extraction-prompt.md; then
  echo "FAIL: payload carries main-session concerns" >&2; exit 1
fi
# Ported content carries the Verification craft section verbatim.
grep -q "^## Verification craft" skill/ported.md
grep -q "re-deriving through a different route" skill/ported.md
echo "TASK1_OK"
```

- [ ] Step 1: Write the assertion block above to a scratch file and run it - expected FAIL (files do not exist yet).
- [ ] Step 2: Create `skill/extraction-prompt.md` from the current README re-extraction prompt (the blockquote at README lines 24-29, NOT line 31's `./install.sh` line), verbatim, then add a leading scoping paragraph: the run is a clean room; it must scan `~/.claude/projects/*/` user messages, memory files, prompt history, the global `CLAUDE.md`, all `learning_guide.html` files, and the docs/plans/READMEs of git repos; it writes only `self-manual.full.bak.md` (the full evidence doc, dated today) and `SCAN_LOG.md` (every file read) into the current directory and modifies no other file; and it must never open `self-manual.md`, `self-manual.full.bak.md`, or any `@`-imported file under CLAUDE.md's "Jeremy's Manual" section (reading those would defeat the clean room). Word the scoping so it does not itself contain the forbidden tokens `install.sh` or `change report`.
- [ ] Step 3: Create `skill/ported.md` by copying the `## Verification craft (ported from the Fable manual)` section (heading through its last bullet) verbatim from `self-manual.md`.
- [ ] Step 4: Run the assertion block - expected `TASK1_OK`.
- [ ] Step 5: Commit - `git add skill/extraction-prompt.md skill/ported.md && git commit -m "Add clean-room extraction payload and carry-forward content"`

---

### Task 2: Skill procedure (SKILL.md)

Depends on: Task 1

**Files (exclusive ownership):**
- Create: `skill/SKILL.md`
- Test: inline bash assertion (below)

**Interfaces:**
- Consumes: `skill/extraction-prompt.md` and `skill/ported.md` by relative path from the installed skill directory.
- Produces: a `/self-manual-regen` skill whose body defines five ordered phases, each phase named literally in the text so downstream tasks and reviewers can grep them: `Phase 1: Archive`, `Phase 2: Clean-room extraction`, `Phase 3: Distill + port`, `Phase 4: Compare`, `Phase 5: Review gate + install`.
- Produces: the pinned clean-room command literal `claude --safe-mode --model` … `--dangerously-skip-permissions -p` (with the `--permission-mode bypassPermissions` and `CLAUDE_CONFIG_DIR` sandbox fallbacks noted) that later tasks and the run itself depend on.
- Produces: the regenerated lean manual's required header line format `extraction <YYYY-MM-DD>` so Task 4's freshness check has a distinctive literal to assert.

**Behavior contract (what the phases must specify, not pre-written prose):**
- Phase 1 Archive: compute `TODAY=$(date +%F)`; `mkdir -p archive/$TODAY`; copy each of `self-manual.md`, `self-manual.full.bak.md`, `SCAN_LOG.md` that exists into it, failing loudly and listing any expected input that is missing rather than half-archiving; then hard-gate on a post-copy verification that every archived file exists and is non-empty (`test -s`) before Phase 2 may start.
  Same-day rerun: if `archive/$TODAY/` already exists and holds a valid non-empty set, do NOT dead-end; treat it as the rollback point, restore the live `self-manual.full.bak.md` / `SCAN_LOG.md` / `self-manual.md` from it, and re-enter Phase 2 (never re-archive over a good first archive).
- Phase 2 Clean-room extraction: run the pinned command with the repo as cwd, feeding `skill/extraction-prompt.md`; write each output to a temp path and `mv` into place only on subprocess success (no in-place truncation on quota death); it produces the new `self-manual.full.bak.md` and `SCAN_LOG.md`.
  Preflight: the run must have actually read history - assert `SCAN_LOG.md` is non-empty and references `.claude/projects` paths, and that `self-manual.full.bak.md` is non-empty and not drastically smaller than the archived prior; a scan that read far fewer files than `archive/$TODAY/SCAN_LOG.md` is a defect, not a pass.
- Phase 3 Distill + port: in the main session, read the new full doc plus `skill/ported.md`; write the new lean `self-manual.md` via temp-then-`mv` (behavior rules only, one sentence per line), stamp its header with `extraction <TODAY>`, and append every section from `ported.md` verbatim.
  Size: keep the file at or under 8192 bytes; if all rules classified plus the ported sections exceed the ceiling, do NOT silently drop a rule - stop and surface the overflow at HC1 for Jeremy to choose what to compress or merge.
- Phase 4 Compare: derive the denominator mechanically from the archived old lean manual (`N = grep -cE '^\s*[-*] |^[0-9]+\. ' archive/$TODAY/self-manual.md`, currently 46), not from the new output; read that old manual and the new lean manual; emit `CHANGES-<TODAY>.md` with four buckets - confirmed, new (each with a verbatim evidence quote and its source file), dropped (with the question "did behavior actually change?"), contradicted (new evidence points the other way) - such that every one of the N old rules appears in exactly one bucket, keyed to a verbatim snippet of that old rule; end with the line `coverage: N/N old rules classified` where the printed N equals the mechanically derived count.
- Phase 5 Review gate + install: present `CHANGES-<TODAY>.md` at HC1, which covers BOTH old-rule classification correctness AND verification that each NEW rule's cited evidence quote actually exists in the regenerated `self-manual.full.bak.md` / `SCAN_LOG.md` (unverifiable new-rule evidence is a blocking defect, not a footnote); on approval, stage the exact `./install.sh` command for Jeremy (HC2); after he installs, prompt him to run the transplant test (HC3).

**Acceptance check:** the assertion block below exits 0 `[executed-check]`

```bash
set -e
# Valid frontmatter naming and invocability.
grep -q "^name: self-manual-regen" skill/SKILL.md
grep -q "^user-invocable: true" skill/SKILL.md
# All five phases named literally.
for p in "Phase 1: Archive" "Phase 2: Clean-room extraction" "Phase 3: Distill + port" "Phase 4: Compare" "Phase 5: Review gate + install"; do
  grep -qF "$p" skill/SKILL.md
done
# Pinned clean-room command, model pin, and both fallbacks.
grep -qF "claude --safe-mode" skill/SKILL.md
grep -qF "dangerously-skip-permissions" skill/SKILL.md
grep -qF -- "--model" skill/SKILL.md
grep -qF "bypassPermissions" skill/SKILL.md
grep -qF "CLAUDE_CONFIG_DIR" skill/SKILL.md
# Archive verify, same-day restore, temp-then-mv, and the size ceiling are specified.
grep -qF "archive/" skill/SKILL.md
grep -qiE "restore" skill/SKILL.md
grep -qiE "temp|mv into place|mv into" skill/SKILL.md
grep -qF "8192" skill/SKILL.md
grep -qi "overflow" skill/SKILL.md
# Coverage derives N mechanically; new-rule evidence is verified at HC1.
grep -qF "coverage:" skill/SKILL.md
grep -qiE "mechanically|derive.*count|grep -cE" skill/SKILL.md
grep -qiE "new rule|new-rule" skill/SKILL.md
# Preflight substance floor and the three human checkpoints are specified.
grep -qiE "preflight|non-empty|\.claude/projects" skill/SKILL.md
grep -qiE "transplant" skill/SKILL.md
echo "TASK2_OK"
```

- [ ] Step 1: Write the assertion block to a scratch file and run it - expected FAIL (`skill/SKILL.md` absent).
- [ ] Step 2: Create `skill/SKILL.md` with frontmatter (`name: self-manual-regen`, a `description:` that triggers on "regenerate my self-manual", "re-extract the operating manual", "update self-manual", `user-invocable: true`) and a body implementing the five-phase behavior contract above, using the exemplar structure of `~/.claude/skills/loop-brainstorm/SKILL.md` (checklist, phase sections, red-flags table).
- [ ] Step 3: Run the assertion block - expected `TASK2_OK`.
- [ ] Step 4: Manually confirm the body prose matches the behavior contract (archive-first, clean-room-only extraction, main-session distill+port+compare, staged install as Jeremy's trigger).
- [ ] Step 5: Commit - `git add skill/SKILL.md && git commit -m "Add self-manual-regen skill procedure"`

---

### Task 3: Wiring - installer, README, gitignore

Depends on: Task 2

**Files (exclusive ownership):**
- Modify: `install.sh`
- Modify: `README.md`
- Modify: `.gitignore`
- Test: inline bash assertion (below)

**Interfaces:**
- Consumes: the skill directory `skill/` and the name `self-manual-regen` fixed by Tasks 1-2.
- Produces: an `install.sh` that, in addition to copying `self-manual.md`, copies `skill/` to `$DEST/skills/self-manual-regen/` (idempotent), preserving its existing self-manual copy and single-import behavior.
- Produces: a `README.md` whose re-extraction section points at `/self-manual-regen` instead of embedding the raw prompt, and a `.gitignore` that excludes `archive/`.

**Acceptance check:** the assertion block below exits 0 `[executed-check]`

```bash
set -e
rm -rf /tmp/regen-test-claude && mkdir -p /tmp/regen-test-claude
touch /tmp/regen-test-claude/CLAUDE.md
bash install.sh /tmp/regen-test-claude
# Skill installed at the right depth (not nested).
test -f /tmp/regen-test-claude/skills/self-manual-regen/SKILL.md
test -f /tmp/regen-test-claude/skills/self-manual-regen/extraction-prompt.md
test -f /tmp/regen-test-claude/skills/self-manual-regen/ported.md
# Manual still installed and import present exactly once.
test -f /tmp/regen-test-claude/self-manual.md
test "$(grep -c 'self-manual.md' /tmp/regen-test-claude/CLAUDE.md)" -eq 1
# Idempotent: a second run keeps the import at one AND does not nest a skill/ dir inside the skill.
bash install.sh /tmp/regen-test-claude
test "$(grep -c 'self-manual.md' /tmp/regen-test-claude/CLAUDE.md)" -eq 1
if test -e /tmp/regen-test-claude/skills/self-manual-regen/skill; then
  echo "FAIL: rerun nested the skill dir" >&2; exit 1
fi
# README points at the skill, not the inline prompt. `! grep` is inert under set -e; use a fail path.
grep -qF "/self-manual-regen" README.md
if grep -qF "Build an operating manual about me" README.md; then
  echo "FAIL: README still holds the inline prompt" >&2; exit 1
fi
# archive/ is gitignored.
grep -qxF "archive/" .gitignore
rm -rf /tmp/regen-test-claude
echo "TASK3_OK"
```

- [ ] Step 1: Write the assertion block to a scratch file and run it - expected FAIL (installer does not yet copy the skill; README still holds the inline prompt).
- [ ] Step 2: Edit `install.sh` to `mkdir -p "$DEST/skills"` then copy the skill idempotently with `cp -rT "$SRC/skill" "$DEST/skills/self-manual-regen"` (the `-T` treats the destination as the target dir, so a rerun overwrites in place instead of nesting a `skill/` subdir), leaving the existing `self-manual.md` copy and the single-import grep guard untouched.
- [ ] Step 3: Edit `README.md`: replace the embedded prompt block (the `> Build an operating manual...` lines) with a short pointer to run `/self-manual-regen`, and note that the skill archives, re-extracts in a clean room, distills, and reports changes; keep the surrounding "Re-extraction" guidance about when to rerun.
- [ ] Step 4: Add `archive/` to `.gitignore`.
- [ ] Step 5: Run the assertion block - expected `TASK3_OK`.
- [ ] Step 6: Commit - `git add install.sh README.md .gitignore && git commit -m "Install the skill and point README at it"`

---

### Task 4: Shakedown run and verification

Depends on: Task 3

**Files (exclusive ownership):**
- Creates at runtime (not source-owned): `archive/<TODAY>/`, regenerated `self-manual.full.bak.md`, regenerated `self-manual.md`, `SCAN_LOG.md`, `CHANGES-<TODAY>.md`
- Test: inline bash assertion (below), plus the three human checkpoints

**Interfaces:**
- Consumes: the installed `/self-manual-regen` skill and all files from Tasks 1-3.
- Produces: proof that every `[executed-check]` success criterion in the brief holds, and the material for HC1-HC3.

**Acceptance check:** the artifact assertion block below exits 0 `[executed-check]`; the `[judgment]` criteria route to HC1 and HC3, never to this block.

```bash
set -e
TODAY=$(date +%F)
# Phase 1 archived the three prior files before overwrite, and they are non-empty.
test -s "archive/$TODAY/self-manual.md"
test -s "archive/$TODAY/self-manual.full.bak.md"
test -s "archive/$TODAY/SCAN_LOG.md"
# Phase 2 produced non-empty evidence that actually read history (no silent empty run).
test -s self-manual.full.bak.md
test -s SCAN_LOG.md
grep -q ".claude/projects" SCAN_LOG.md
# New lean manual is genuinely regenerated (today's stamp) AND kept the ported section.
grep -qF "extraction $TODAY" self-manual.md
grep -qF "## Verification craft" self-manual.md
# Size ceiling holds.
test "$(wc -c < self-manual.md)" -le 8192
# Change report exists and its coverage denominator equals the archived old manual's real rule count.
test -f "CHANGES-$TODAY.md"
N_OLD=$(grep -cE '^\s*[-*] |^[0-9]+\. ' "archive/$TODAY/self-manual.md")
COV=$(grep -oE 'coverage: [0-9]+/[0-9]+' "CHANGES-$TODAY.md" | head -1)
NUM=${COV#coverage: }; LEFT=${NUM%/*}; RIGHT=${NUM#*/}
test "$LEFT" -eq "$RIGHT"
test "$RIGHT" -eq "$N_OLD"
echo "TASK4_ARTIFACTS_OK"
```

- [ ] Step 1: Run the assertion block before invoking the skill - expected FAIL (no archive, no dated report).
- [ ] Step 2: Invoke `/self-manual-regen` in a normal Claude Code session; let Phase 1 (archive) and Phase 2 (clean-room extraction) run.
- [ ] Step 3: Confirm the clean-room command actually launched with `--safe-mode` (the extractor must not have loaded the current manual); if the environment rejected `--dangerously-skip-permissions`, confirm the skill fell back to `--permission-mode bypassPermissions`.
- [ ] Step 4: Let Phase 3 (distill + port) and Phase 4 (compare) produce the new lean manual and `CHANGES-<TODAY>.md`.
- [ ] Step 5: Run the artifact assertion block - expected `TASK4_ARTIFACTS_OK`.
- [ ] Step 6: **HC1** - present `CHANGES-<TODAY>.md`; Jeremy confirms each old rule's classification is correct (a three-week gap may legitimately yield "mostly confirmed"), AND for every rule in the "new" bucket, confirm its cited evidence quote actually appears in the regenerated `self-manual.full.bak.md` / `SCAN_LOG.md` (grep each quote); an unverifiable new-rule quote is a blocking defect that sends the run back to Phase 3, not a footnote. If Phase 3 reported a size overflow, Jeremy decides here what to compress or merge.
- [ ] Step 7: **HC2** - stage the exact command `./install.sh` and hand it to Jeremy; he runs it (it edits the real `CLAUDE.md`).
- [ ] Step 8: After install, assert the import is still single: `test "$(grep -c 'self-manual.md' ~/.claude/CLAUDE.md)" -eq 1`.
- [ ] Step 9: **HC3** - Jeremy runs `claude -p "What should you watch out for when I hand you a plan I'm excited about?"` and confirms the answer comes from the manual, not generic advice.
- [ ] Step 10: Commit the tracked wiring only (manuals and archives stay gitignored) - nothing new to commit here unless the run surfaced a skill fix, in which case commit that fix.

---

## Notes for the executor

- The extraction is the expensive, judgment-heavy step and the one most exposed to quota death mid-run; the archive (Phase 1) is the rollback point, so it must complete and be verified (non-empty copies) before Phase 2 starts, and every regenerated file is written temp-then-`mv` so a killed subprocess never leaves a truncated live file.
- A same-day rerun is expected after a mid-run death: the existing `archive/$TODAY/` is treated as the rollback source (restore the live files from it, re-enter Phase 2), never re-archived over.
- The clean room deliberately cannot see the old lean manual or `ported.md`; that blindness is the design, and it is why distillation and comparison run in the main session, not in the `-p` subprocess.
- The size ceiling (8192) and import-count (==1) checks are invariant guards, not change-assertions; they pass on the baseline by design and exist to catch a regeneration that bloats the manual or an installer that duplicates the import.
