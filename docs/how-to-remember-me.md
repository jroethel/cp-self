# how-to-remember-me

A ready-to-paste brainstorming prompt for a future session on agentic memory for my work.
Written 2026-08-08; paste the block below into a session and let /loop-brainstorm take it from there.

---

/loop-brainstorm

i want to design agentic memory for my work - memory that tracks me over time, not just facts about me.

the itch: my current self-knowledge stack (cp-self manual, OPINIONS.md, VOICE.md) is a snapshot.
it captures who i am at extraction time, and re-extraction every few months overwrites the old snapshot.
what it can't answer: how my work is changing, how my methods are changing, whether i'm actually growing.
i'm curious about my own progression - what i used to get wrong that i now get right, what i'm leaning on agents for less than i used to, where i've plateaued.

what i want memory to do:

- track situation, not just traits: what i'm working on, what constraints are live (quota, deadlines, org stuff), and let that expire when it expires.
  durable vs temporal is the distinction - the manual holds durable rules, this thing holds the moving picture (see cp-self docs/ideas/2026-08-08-durable-vs-temporal-distill.md).
- track progression: diffs between extractions, not just the latest extraction.
  the archived self-manuals and evidence files in cp-self private/ are already a time series nobody is reading.
- feed my growth: an agent that knows my trajectory can support my learning differently than one that knows my current state.
  where am i improving, where am i stuck, what should it push me on vs quietly handle for me.
- stay file-based and navigable: claude code auto-memory hasn't earned my trust - memories get lost in a pile and i have to ask for them to be replayed.
  if it's files at known paths, i can just go where i need to.
  but i'm open to auto-memory running in parallel as an experiment, if the file layer stays the source of record.
- work across hosts: same constraint as cp-self - corporate firewall, git-hosted encrypted sync, per-host stamps.

constraints and assets:

- the cp-self pipeline (evidence -> distill -> install) already exists and could grow this instead of a new tool existing beside it.
- quota limits kill sessions mid-flight; whatever this is, a half-updated memory must not corrupt the picture.
- token cost matters: memory that loads every session must earn every line - progressive disclosure, an index that points, not a dump that loads.
- i don't want to maintain it by hand: "kept up to date by CLAUDE and not ME."

open questions i want the brainstorm to push on:

- what's the minimal schema for a progression entry, and what cadence - per session, per project milestone, per re-extraction?
- who writes it: every session opportunistically, a periodic reflection pass over history, or only the cp-self pipeline?
- how does an agent USE it in a live session without burning tokens - when does trajectory actually change what the agent should do?
- how do i know it's working: what would i see after 3 months that i can't see today?
- is this a cp-self extension or its own thing? my default is extend, push back if that's wrong.

---

## Appendix: session context (verbatim agent response, 2026-08-08)

The response below is from the session that staged this prompt; kept verbatim as context for the future brainstorm.

All four done.

**#3 - OPINIONS.md and VOICE.md created.** Both live in `~/repos/cp-self/private/` (per the README: "All personal profile data lives in `private/`"), with `~/OPINIONS.md` and `~/VOICE.md` symlinked to them so the CLAUDE.md pointers now resolve. The evidence file moved to `private/` alongside them. I verified `vault.sh push` sweeps all plaintext in `private/`, so all three will encrypt and sync on your next push - your trigger. VOICE.md is structured as a register map: the prompting register is fully evidenced, and email/spoken are marked TO FILL for reconciliation on the other host, with a warning not to use the prompting register for anything outward. Two notes: the symlinks are host-local, so the other host will need the same two `ln -sf` lines (install.sh could grow them if you want); and your CLAUDE.md voice line says "see how **Kun** talks" - looks like a stray name, flagging rather than editing your CLAUDE.md.

**#4 - committed.** The three loop skills in `~/.agents/skills` turned out to be symlinks straight into `~/repos/loop-stack-session/skills/`, so the edits were already in the working tree. Committed on `main` as `013844c` ("Point markdown style rules at the CLAUDE.md house style instead of restating them"), plain message, no co-author. Not pushed - say push if you want it on the remote. Note: `no-ai-slop` is not in that repo; its fixed copy lives only in `~/.agents/skills`, which has no version control at all.

**#5a - refiled locally.** The idea now lives at `~/repos/cp-self/docs/ideas/2026-08-08-durable-vs-temporal-distill.md`, and I closed GitHub issue #1 with a comment pointing there. The outer cp-self repo has `docs/ideas/` and `docs/how-to-remember-me.md` untracked - you only asked for a commit on loop-stack, so I left cp-self uncommitted; `git -C ~/repos/cp-self add docs && git -C ~/repos/cp-self commit -m "Add ideas lane and memory brainstorm prompt"` when you want them in.

**#5b - brainstorm prompt staged.** `~/repos/cp-self/docs/how-to-remember-me.md` is a paste-ready `/loop-brainstorm` prompt in your prompting voice. It frames the itch as snapshot-vs-trajectory: cp-self captures who you are at extraction time, but the archived manuals in `private/` are already an unread time series of who you've been. It carries your constraints (file layer as source of record, auto-memory as a parallel experiment, quota-safe, cross-host, "kept up to date by CLAUDE and not ME") and five open questions ending with the extend-cp-self-or-new-thing call. I also updated my memory file with the nuance from your message: auto-memory is welcome in parallel for tracking progression, because your trajectory - not just your current state - should shape how I support you.
