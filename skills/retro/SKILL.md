---
name: retro
description: Turn a finished feature's reviews and test report into durable project knowledge in .agent/project.md. Run after the fix batch retest, before the ship gate. Also use when the same kind of review block or QA failure keeps recurring across features.
---

# Retro

Everything this team learns is already written down — and then thrown away. `05-review.md` records every finding, `04-test-report.md` records every bug and requirement gap, `state.md`'s findings board records what the human chose to fix and what they accepted. None of it reaches the next feature, because subagents start with empty context and read only `.agent/project.md`.

This step moves the few lines that matter from those artifacts into that file.

## The budget comes first

`.agent/project.md` is read by every agent on every call. An append-only log there makes every future call more expensive, forever — the most costly file in the system is the one nobody thinks of as costly.

- **Keep `.agent/project.md` under ~200 lines.** Over budget means something must merge or leave, not that the budget bends.
- **Merge, never append.** A new rule that overlaps an existing one rewrites that line; it does not sit next to it.
- **One line per rule.** If it needs a paragraph, it belongs in the design template, not here.
- **Delete what is now false.** A superseded decision is worse than no decision.

Two tiers, and only one of them costs tokens:

| Goes in `.agent/project.md` | Stays in `docs/features/<slug>/` |
|---|---|
| A rule that applies to features not yet written | Anything true only of this feature |
| Something an agent would get wrong on its next call | A bug that is now fixed |
| A convention discovered from real code | The reasoning behind one design choice |

The test for a line: **would this have prevented the problem, and will it apply again?** Both, or it does not go in.

## Steps

1. **Read this feature's evidence** — do not rely on memory of the session:
   - `docs/features/<slug>/05-review.md` — every finding, and which category repeats
   - `docs/features/<slug>/04-test-report.md` — "Requirement gaps" and every bug QA found
   - `.agent/state.md` findings board — especially the `wont-fix` rows: an accepted finding is a convention nobody wrote down

2. **Diagnose before writing.** Repetition points at the artifact that failed, not at the agent:

   | Pattern | Real cause | Where the fix goes |
   |---|---|---|
   | The same review category appears across several tasks | project conventions are not written down | `.agent/project.md` |
   | QA found what the ACs never asked for | part A of `sa` SPEC mode is not digging in this area | the `sa` agent file |
   | developer kept hitting files outside its list | the task split was wrong | the `tech-lead-plan` file |

   Only the first row is a `project.md` edit. **The others are plugin changes, not project knowledge** — report them as a recommendation; do not edit the plugin from here.

3. **Propose at most 5 lines**, each with its destination section and whether it replaces an existing line:

   ```
   → Project conventions
     REPLACE "error handling: throw exceptions" with "error handling: throw a DomainError subclass; the global filter maps it to a status code (see src/common/filters/domain.filter.ts)"
     why: review blocked T-003 and T-007 on this
   → Business rules newcomers get wrong
     ADD "an order in PENDING state has no invoice yet — never read order.invoice.id without checking state first"
     why: BUG-02, and no AC covered it
   ```

4. **The human confirms each line.** They own this file; you propose, they decide. Write the approved lines yourself — do not leave it to them to remember.

5. **Check the budget after writing.** Over ~200 lines: merge the weakest lines in the longest section and say what you merged.

## Never

- Add a line describing what this feature does — that is what `docs/features/` is for
- Add a rule you cannot point to evidence for (a review block, a bug, a gap)
- Restate something the file already says in different words
- Edit the agent or skill files of the plugin from here — recommend the change and let the human decide
- Write anything into `.agent/project.md` without the human confirming it

## Report back

```
STATUS: OK
READ: <05-review.md, 04-test-report.md, state.md findings board>
PROPOSED: <n lines>  ACCEPTED: <n>
FILE: <line count of .agent/project.md> / ~200 budget
PLUGIN: <recommendations for the plugin's own agent files, or "none">
```
