---
name: pm-gate
description: Checklist for the human acting as PM at each gate - the outline gate (large work split into parts), GATE 1 (requirements + design + UX + tasks, before any code), an amendment stop mid-build, GATE 2 (triage the verification findings), GATE 3 (ship). Run it when state.md shows gate awaiting-pm.
---

# PM Gate Checklist

You are the only part of this system with business context — agents have none. **Do not spend your time on what agents already check themselves.**

There are three gates: **GATE 1** before any code (requirements + design + UX + tasks together), **GATE 2** after the single verification pass (you pick what gets fixed), **GATE 3** before ship. Large work adds an **outline gate** first, and then every part runs its own GATE 1-3. Mid-build there may be an **amendment stop** when a gap is too big to patch silently. GATE 1 deserves 10-15 minutes because it is now the only stop before code; the other two should take 5. Longer means the artifact was not ready; send it back instead of forcing your way through it.

## GATE 1 — requirements + design + tasks, in one sitting

**The only stop before code is written**, and the most expensive one to wave through: a mistake here is amplified into wrong code across dozens of files, and the fix costs ten times more later. `sa` wrote the requirements and the design in one call, `ux` wrote the flows and screen specs (UI features), `tech-lead-plan` split them into tasks, and you are seeing them together on purpose — scope reads differently when the task list next to it tells you what it costs.

Work top to bottom; if something fails early, stop and send it back rather than reading on.

**Size first.** The orchestrator opens GATE 1 with each file's word count and what the planning cost. A file over its budget (requirements ~2,500 words or 30 ACs, design ~3,000, UX ~2,500 or 15 criteria) is usually specifying the implementation — sending it back for a shorter version is cheaper than reading it, and far cheaper than building it.

**Scope — `01-requirements.md`**
- [ ] Read **"Out of scope" first** — does it match what you had in mind?
- [ ] Does the role/permission table (section 2) match business reality?
- [ ] Answer every open question in section 6 — do not leave agents to guess
- [ ] Any AC you cannot picture as a screen or a response? Then it is not specific enough

**Solution — `02-design.md`**
- [ ] Trade-off table (section 1) — do you agree with the reasons the rejected options were rejected?
- [ ] "Impact on existing code" (section 6) — any breaking change hitting other systems?
- [ ] Is the migration/rollback actually doable against production data?
- [ ] Section 4 UI contract — all four states (loading/empty/error/no permission) on every screen?
- [ ] Traceability (section 7) covers every AC — a quick scan is enough
- [ ] Section 8 threat model — is the owner of each record determined from the token rather than the request body?
- [ ] Anything called "existing" or "canonical" — does it cite a real path? An unbacked claim is the gap that stops a build mid-way

**Usability — `02b-ux.md`** (UI features only — this is where "it works but nobody can use it" is prevented)
- [ ] Section 1 — are these really your users' most frequent tasks, in the right order?
- [ ] Section 3 — walk the top 2-3 flows in your head. Is the step budget one a real user would accept?
- [ ] Section 4 — does each screen have the one primary action you would expect?
- [ ] Section 6 — date era, currency and wording right for your users?
- [ ] Any `CONFLICTS` the orchestrator flagged — decide them now

**Cost — `03-tasks.md`**
- [ ] Does the Coverage table list shared pieces (tokens, toast, layout shell) with a task each?
- [ ] Does the task order start at the bottom layer and work up?
- [ ] Any task big enough to look like it will fail?
- [ ] How many `complexity: high`? More than half means the labels are noise — send it back
- [ ] Tasks marked `mechanical` run on the cheapest model — does each one's **Exact change** really leave nothing to decide? A hidden decision there comes back `BLOCKED` and costs a second call
- [ ] Does every task's Definition of Done include a test for its own ACs? Without those, the single `qa` pass at the end has to author every test at once, and it will do it badly
- [ ] **Any task you want to cut from this round?** This is the cheapest moment to cut scope; the price rises at every later step
- [ ] Is a checkpoint command (`build` / `typecheck` / `test`) filled in under `.agent/project.md` → "Common commands"? The orchestrator runs it between tasks — it is the only guard while the whole batch is being built

One gate means one habit worth keeping: **read the requirements before the design.** Approving a solution to a problem you have not checked is how a feature ends up correct and useless at the same time.

## Outline gate — large work, before any part is specified (5 minutes)

`sa` judged the request too large to specify in one go and wrote only `00-outline.md`. Nothing else exists yet, on purpose: each part gets its full spec when its turn comes, against the code the parts before it actually built.

- [ ] Section 2 — does **P-01** give you something you could actually use or show? A first part that is "all the setup" delays the first useful result and hides mistakes until late
- [ ] Is the order right for your business — what do you need first?
- [ ] Any part you would cut, or postpone indefinitely? This is the cheapest moment
- [ ] Section 3 — are the shared decisions ones you agree to live with in every part?
- [ ] Section 4 — is anything deferred that you actually need decided now?

Then each part runs GATE 1 → GATE 3 on its own. At each part's GATE 3 you are asked whether to start the next one — reorder or stop there if what you learned says so.

## Amendment stop — mid-build

A developer found a gap the plan missed, and the fix is bigger than the orchestrator may apply alone. You see the gap, any design patch, and the proposed amendment.

- [ ] Is it really a gap, or a requirement you would rather drop? Dropping is often cheaper
- [ ] Does the amendment touch only what the gap needs?
- [ ] A **second** gap in the same feature means the plan missed a whole class of thing — consider asking for a re-plan instead of patching again

## GATE 2 — triage: the one place you choose what gets fixed

The agents have run **one** verification pass — a feature-wide `tech-lead-review`, `qa` in CLOSE mode, `ux` AUDIT on UI features, and `/security-review` — and merged everything they found into one severity-ranked findings list. Nothing has been fixed yet, on purpose: fixing is one batch, after you choose.

Your job here is **not** to re-review the code. It is to answer, for each finding: fix now, or ship without it?

- [ ] Read the **blockers** first — a blocker you accept is a decision, so it belongs in `.agent/project.md` under "Decisions made", not just in chat
- [ ] For each `major`: is it on a path real users take? If not, it can wait for a later round
- [ ] `minor` findings: default to **not now**. A batch of 15 cosmetic fixes costs a full retest and buys nothing — group them into a cleanup task later
- [ ] Anything in the list that is really a **requirement** problem rather than a code problem? Send it to `01-requirements.md`, not to `developer`
- [ ] Read QA's "Requirement gaps" — an AC that never existed is scope, and scope is yours alone
- [ ] Does "End-to-end flows tested" cover the paths real users take most? If not, ask for that flow to be tested rather than more unit tests
- [ ] `U-` findings from the UX audit: a `major` on a top task is worth fixing now even though nothing "breaks" — it is the difference between a feature people use and one they work around
- [ ] If a deploy path was touched: did `devops` write all four rollback lines, and can you run the rollback command yourself?

Then reply with the ids: **"fix F-01, F-03, F-06; leave the rest."** That is the whole handoff — `developer` fixes them in one call, `qa` retests once, and the run stops there whatever the result.

**Estimating the cost before you choose**: a fix batch is one `developer` call plus one `qa` retest, no matter how many ids you put in it. Adding a 4th id is nearly free; splitting the same work across two rounds doubles it. So decide once, and decide fully.

### If the retest still fails

You get the report and the run stops — the agents will not try again on their own (that loop is exactly what this pipeline removed). Three honest options:

| situation | do this |
|---|---|
| the fix was close but incomplete | one more batch; the orchestrator quotes the failing retest into it so nothing is retried blindly |
| the same finding survived two batches | the design is wrong, not the code — reopen `02-design.md` |
| it only fails on a `minor` | accept it, record it under "Decisions made", ship |

## GATE 3 — before shipping

- [ ] `04-test-report.md`'s latest verdict is PASS, or every remaining failure is one you consciously accepted
- [ ] Every finding in the board is `fix` (and done) or `wont-fix` (and recorded) — nothing left `pending`
- [ ] Did `/agent-team:retro` run, and do you agree with the lines it wants to add to `.agent/project.md`?
- [ ] A part of a large feature: start the next part, reorder, or stop here? Read outline section 5 first — it lists what building this part changed about the plan

`/security-review` ran over the built branch in VERIFY and its findings are rows in the same triage list — check that none of them are still `pending`.

## When an agent returns NEEDS-PM

The agent proposes options with trade-offs; you choose, then **write the decision into `.agent/project.md` under "Decisions made"** — not just in chat, because the next agent starts with empty context and cannot see what you typed. (Telling the orchestrator to write it is fine, but check that it did.)

## Signs the system is failing

| Symptom | Real cause is usually | Fix it in |
|---|---|---|
| the same finding comes back after a fix batch | unclear design, not a weak developer | `02-design.md` |
| the triage list is 20 rows, mostly `minor` | `.agent/project.md` conventions are too vague to code against | `project.md` |
| `qa` FAILs because an AC reads several ways | ambiguous AC written back at gate 1 | `01-requirements.md` |
| developer keeps returning BLOCKED for files outside its list | tasks split along the wrong boundaries | `03-tasks.md` |
| code is correct but does not fit the project | `.agent/project.md` is not detailed enough | `project.md` |
| developer keeps returning `GAP: missing-element` | the design called things "existing" that were not, or the Coverage table skipped shared pieces | `02-design.md` / `03-tasks.md` |
| every AC passes but the UI is hard to use | flows and step budgets were never agreed | `02b-ux.md` |

**Almost every time, the problem is in an artifact, not in an agent's prompt.** Fix the content in the agent file (the single source of templates — subagents read no external skills).
