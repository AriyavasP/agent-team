---
name: pm-gate
description: Checklist for the human acting as PM at each of the three gates - GATE 1 (requirements + design + tasks, before any code), GATE 2 (triage the verification findings), GATE 3 (ship). Run it when state.md shows gate awaiting-pm.
---

# PM Gate Checklist

You are the only part of this system with business context — agents have none. **Do not spend your time on what agents already check themselves.**

There are three gates: **GATE 1** before any code (requirements + design + tasks together), **GATE 2** after the single verification pass (you pick what gets fixed), **GATE 3** before ship. GATE 1 deserves 10-15 minutes because it is now the only stop before code; the other two should take 5. Longer means the artifact was not ready; send it back instead of forcing your way through it.

## GATE 1 — requirements + design + tasks, in one sitting

**The only stop before code is written**, and the most expensive one to wave through: a mistake here is amplified into wrong code across dozens of files, and the fix costs ten times more later. `sa` wrote the requirements and the design in one call, `tech-lead-plan` split them into tasks, and you are seeing all three together on purpose — scope reads differently when the task list next to it tells you what it costs.

Work top to bottom; if something fails early, stop and send it back rather than reading on.

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

**Cost — `03-tasks.md`**
- [ ] Does the task order start at the bottom layer and work up?
- [ ] Any task big enough to look like it will fail?
- [ ] How many `complexity: high`? More than half means the labels are noise — send it back
- [ ] Does every task's Definition of Done include a test for its own ACs? Without those, the single `qa` pass at the end has to author every test at once, and it will do it badly
- [ ] **Any task you want to cut from this round?** This is the cheapest moment to cut scope; the price rises at every later step
- [ ] Is a checkpoint command (`build` / `typecheck` / `test`) filled in under `.agent/project.md` → "Common commands"? The orchestrator runs it between tasks — it is the only guard while the whole batch is being built

One gate means one habit worth keeping: **read the requirements before the design.** Approving a solution to a problem you have not checked is how a feature ends up correct and useless at the same time.

## GATE 2 — triage: the one place you choose what gets fixed

The agents have run **one** verification pass — a feature-wide `tech-lead-review`, `qa` in CLOSE mode, and `/security-review` — and merged everything they found into one severity-ranked findings list. Nothing has been fixed yet, on purpose: fixing is one batch, after you choose.

Your job here is **not** to re-review the code. It is to answer, for each finding: fix now, or ship without it?

- [ ] Read the **blockers** first — a blocker you accept is a decision, so it belongs in `.agent/project.md` under "Decisions made", not just in chat
- [ ] For each `major`: is it on a path real users take? If not, it can wait for a later round
- [ ] `minor` findings: default to **not now**. A batch of 15 cosmetic fixes costs a full retest and buys nothing — group them into a cleanup task later
- [ ] Anything in the list that is really a **requirement** problem rather than a code problem? Send it to `01-requirements.md`, not to `developer`
- [ ] Read QA's "Requirement gaps" — an AC that never existed is scope, and scope is yours alone
- [ ] Does "End-to-end flows tested" cover the paths real users take most? If not, ask for that flow to be tested rather than more unit tests
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

**Almost every time, the problem is in an artifact, not in an agent's prompt.** Fix the template in the skill, not the agent file.
