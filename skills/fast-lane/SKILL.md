---
name: fast-lane
description: Short route for bug fixes and small work not worth the full ba-sa-tech-lead-plan pipe. Use when the work touches at most 2 files, no schema, no API contract, and the correct behaviour fits in one sentence.
---

# Fast Lane

A system that makes a one-line bug walk through three gates is a system people stop using. This lane exists so the main pipe stays sacred.

## Entry criteria — **all** must hold; miss one and it is the full pipe

- [ ] At most 2 files under `src/`
- [ ] No database schema change, no migration
- [ ] No change to an API contract others call (request/response shape, status code, field names)
- [ ] No dependency added or upgraded
- [ ] Nothing touching auth, permissions, billing or personal data
- [ ] "What the correct behaviour is" fits in one sentence, with no "it depends"

**Do not negotiate with yourself.** Hesitating over whether it qualifies means it does not.

## Steps

1. **Write one small AC** into `docs/fixes/<YYYY-MM-DD>-<slug>.md` before touching code

   ```markdown
   # FIX-<slug> — <title>
   AC: Given <state> When <action> Then <expected>
   Reproduce: <steps>
   Files to touch: <list>
   ```

   Cannot write it = you do not understand the problem yet. Do not start fixing.

2. **Write a failing test first** so the symptom is visible from a test, not from a description. It must fail now and pass after the fix; if it passes before the fix, you are looking at the wrong place.

3. **Call `developer`** with the path of that fix file as the task definition.

4. **Call `tech-lead-review` in TASK mode** — never skipped. This is the one thing the fast lane shares with the full pipe: bug fixes create new bugs at a higher rate than features do, because whoever fixes them rarely knows why the old code was written that way.
   It runs **once** and writes its findings into the same fix file. Blockers and majors → one `developer` fix call, then stop and report. Minors → show them to the human and let them say. There is no review-fix-review ping-pong here either.

5. **Run the whole test suite**, not just the new test — regression is the main risk of fix work.

## When to fall back to the full pipe

Stop and open a normal feature if any of these appear mid-way. **Do not push through.**

- A third file has to change
- The fix breaks an existing test (what you think is a bug may be intentional)
- The real cause is in the design, not the code
- The one review pass found a blocker that is not a small correction, or the first fix call did not clear it

## Write it down

A fix that reveals an unwritten business rule gets one line added to `.agent/project.md` under "Decisions made" — that is how the knowledge outlives the session.
