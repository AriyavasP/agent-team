---
name: impact-scan
description: Survey what one side (FE/BE) must integrate after the other side changed. For investigation questions not yet tied to a task or feature, e.g. "check what FE payment must integrate after the BE update". Produces a short report plus proposed next lanes; no gate artifact. Read by the orchestrator to scope the scan before delegating to sa in SCAN mode.
---

# Impact Scan

"Check what FE payment must integrate after the BE update" **is not an order to build anything.** Nothing has been decided; the only question is what currently differs. Never pull in `ba`/`tech-lead-plan` — that opens a gate with nothing to approve.

**The scan itself belongs to `sa` in SCAN mode, not to the orchestrator.** Reading a contract across layers (what BE changed → what FE must follow) is what `sa` already does: it reads `.agent/project.md`, knows both sides' conventions, and surveys with Glob/Grep. The orchestrator only defines the scope and hands it over. `sa`'s own file holds the full scan procedure and report format — do not restate it here.

## What the orchestrator does before calling sa

1. **Fix the scope of "the update" first.** If the request names no commit/branch/PR/date range to compare against, ask the human one question: "compared against what?"
   Guessing "latest" means comparing the wrong range, which makes the whole report wrong. If they truly cannot say, agree an explicit fallback (e.g. the last 20 commits on the changed side) and state which fallback you are using.
2. Call `sa` in SCAN mode with that scope inline. Never send less than this:
   ```
   sa:
     SCAN mode — check what <side to inspect, e.g. "FE payment"> must integrate
     Compared against: <agreed branch/commit/date range>
     Changed side: <BE/FE — say clearly who changed and who must follow>
   ```
3. Show `sa`'s report in chat as-is — do not re-summarize or trim it.
4. Do not set `gate: awaiting-pm`; there is no artifact to approve. End by asking the human which items to take forward and in which lane.

Persist a record only if the human asks: `docs/impact/<YYYY-MM-DD>-<slug>.md`, never under `docs/features/` — this is an investigation note, not a gated artifact.

## Never

- Start changing code in this lane — it ends at the report; the next lane is the human's choice
- Delegate the scan to a generic agent that does not know this project's conventions — `sa` has the tools and the context already
- Let MUST items be buried under SHOULD ones — what actually breaks comes first
