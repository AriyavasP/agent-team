---
name: pm-gate
description: Checklist for the human acting as PM, for reviewing artifacts before letting the agents continue at each gate. Run it when state.md shows gate awaiting-pm.
---

# PM Gate Checklist

You are the only part of this system with business context — agents have none. **Do not spend your time on what agents already check themselves.**

A gate should take 5-10 minutes. Longer means the artifact was not ready; send it back instead of forcing your way through it.

## Gate 1 — after `ba` (most expensive to wave through)

A mistake here is amplified into wrong code across dozens of files; the fix costs ten times more later.

- [ ] Read **"Out of scope" first** — does it match what you had in mind?
- [ ] Does the role/permission table match business reality?
- [ ] Answer every open question in section 6 — do not leave agents to guess
- [ ] Any AC you cannot picture as a screen or a response? Then it is not specific enough

## Gate 2 — after `sa`

- [ ] Trade-off table — do you agree with the reasons the rejected options were rejected?
- [ ] "Impact on existing code" — any breaking change hitting other systems?
- [ ] Is the migration/rollback actually doable against production data?
- [ ] Section 4 UI contract — all four states (loading/empty/error/no permission) on every screen?
- [ ] Traceability covers every AC (a quick scan is enough)

## Gate 3 — after `tech-lead-plan`

- [ ] Does the task order start at the bottom layer and work up?
- [ ] Any task big enough to look like it will fail?
- [ ] How many `complexity: high`? More than half means the labels are noise — send it back
- [ ] **Any task you want to cut from this round?** This is the cheapest moment to cut scope; the price rises at every later step

## Gate 4 — before shipping

- [ ] `04-test-report.md` is PASS with no open bugs
- [ ] Does "End-to-end flows tested" cover the paths real users take most?
- [ ] Read QA's "Requirement gaps" — start another round, or accept the risk for now?
- [ ] If a deploy path was touched: did `devops` write all four rollback lines, and can you run the rollback command yourself?

## When an agent returns NEEDS-PM

The agent proposes options with trade-offs; you choose, then **write the decision into `.agent/project.md` under "Decisions made"** — not just in chat, because the next agent starts with empty context and cannot see what you typed. (Telling the orchestrator to write it is fine, but check that it did.)

## Signs the system is failing

| Symptom | Real cause is usually | Fix it in |
|---|---|---|
| `tech-lead-review` BLOCKs 3 rounds on one task | unclear design, not a weak developer | `02-design.md` |
| `qa` FAILs because an AC reads several ways | ambiguous AC written back at gate 1 | `01-requirements.md` |
| developer keeps returning BLOCKED for files outside its list | tasks split along the wrong boundaries | `03-tasks.md` |
| code is correct but does not fit the project | `.agent/project.md` is not detailed enough | `project.md` |

**Almost every time, the problem is in an artifact, not in an agent's prompt.** Fix the template in the skill, not the agent file.
