This run is a clean room: you have no customizations loaded, so you cannot read the manuals you are grading.
Scan `~/.claude/projects/*/` user messages only, my memory files, my prompt history, the global `CLAUDE.md` (each rule I wrote marks a past pain point), every `learning_guide.html` file, and the docs/plans/READMEs of my git repos.
Keep the scan non-invasive: `.claude` dirs and project folders (identified by `.git`) only.
You write exactly two files into the current directory and nothing else: `self-manual.evidence.md` (the full evidence doc, dated today) and `SCAN_LOG.md` (every file you read).
Modify no git-tracked file and create no other file.
Never open `self-manual.md`, any `self-manual.evidence*.md` file, or any file `@`-imported by the global `CLAUDE.md` section that imports the self-manual - those are the artifact being graded, and reading them would defeat the clean room.

> Build an operating manual about me - the human - for the models that work with me.
> Title it with my name (given at the top of this prompt) and use the name throughout where it helps the reader.
> Scan my Claude Code chat histories (`~/.claude/projects/*/`, user messages only), my memory files, my prompt history, my global CLAUDE.md (each rule I wrote marks a past pain point), all `learning_guide.html` files, and the docs/plans/READMEs of my own git repos.
> Keep the scan non-invasive: `.claude` dirs and project folders (identified by `.git`) only, and log every file you read into `SCAN_LOG.md`.
> From the evidence, not from flattery, extract: 1. What I'm actually good at - where my intuition can be trusted and my pushback is usually right. 2. Where my intuition is unreliable and the model should push back or verify instead of complying. 3. My recurring failure patterns - the things I have to be saved from again and again. 4. How I frame requests, and how to read what I actually need beneath what I typed. 5. What I under-invest in and quietly hope the model covers. 6. How to disagree with me so that it lands. 7. What finished looks like to me, and what I will reject even if it is technically correct.
> For each point: the pattern, the evidence behind it (short verbatim quotes), and the concrete behavior the model should adopt.
> Be honest. A manual that protects my ego is useless. End with a short self-test the model runs before handing me anything.
