# Standards this plugin follows

The agents and skills here were written for this plugin, not taken from a widely used package. This file records what each one is anchored to, where it deliberately departs from Anthropic's official plugins, and what is still unverified, so a reviewer can check the plugin against something other than its own claims.

## What each role is anchored to

| role | standard | where it is applied |
|---|---|---|
| `sa`, `ba` — requirements | ISO/IEC/IEEE 29148 characteristics of a good requirement (necessary, unambiguous, complete, singular, feasible, verifiable, correct); Given/When/Then (Gherkin), one scenario per AC; a budget of 30 ACs per spec | `sa.md` / `ba.md` → "What makes an AC usable" (kept identical; the checker enforces it) |
| `sa` — design | Architecture-decision style option tables (every decision names a rejected option); STRIDE for the threat model | `sa.md` → design sections 1 and 8 |
| `ux` | ISO 9241-11 (effectiveness, efficiency, satisfaction); Nielsen's 10 usability heuristics; WCAG 2.2 level AA; UI-writing rules from the official `frontend-design` skill | `ux.md` → intro, DESIGN sections 6-7, AUDIT method |
| `tech-lead-plan` | INVEST, adapted to agent tasks (Independent, Valuable, Small, Testable); Definition of Done as runnable commands | `tech-lead-plan.md` → "Task size" |
| `impact-analyst` | contract-first change analysis: only interface changes (endpoints, shapes, codes, events, enums) are compared, classified MUST / SHOULD / WATCH by runtime impact | `impact-analyst.md` → steps 1-3 |
| `tech-lead-review` | Google Engineering Practices, "What to look for in a code review"; OWASP Top 10 (2021) for the security pass; confidence ≥ 80 filter from the official `pr-review-toolkit` reviewer | `tech-lead-review.md` → review order, confidence |
| `qa` | ISTQB test-design techniques: equivalence partitioning, boundary values, decision tables, state transitions | `qa.md` → "Always test these" |
| all agents | Anthropic `plugin-dev` agent guidance: second-person system prompt, explicit process, defined output format, least-privilege tools, `color` in frontmatter | every file in `agents/` |

Naming a standard is deliberate: the model already knows these, so one line pulls in a checklist far longer than we could inline, and a reviewer can hold the agent to it.

## Where this plugin departs from the official plugins, and why

Compared with `feature-dev` (explore → clarify → architect → implement → review) and `pr-review-toolkit`:

| official practice | this plugin | why |
|---|---|---|
| 2-3 explorer / architect / reviewer agents in parallel | one agent per stage; only `tech-lead-review` and `ux` AUDIT run together in VERIFY | agents here write files, and parallel writers clobber each other. Review and UX audit only read code, so they share a turn; `qa` writes tests, so it waits |
| clarifying questions asked and answered before any design | `sa` stops with `NEEDS-PM` only for high-impact questions; the rest go to requirements section 6 and are answered at GATE 1 | one stop before code instead of two. The risk: a medium-impact assumption gets designed around before a human sees it |
| review findings fixed right after review | findings from review, qa, UX audit and security are triaged once, by a human, then fixed in one batch | the per-task review ↔ qa loop cost ~11 calls per task in 1.x |
| `model: inherit` recommended | fixed models per role (opus for spec and review, sonnet elsewhere including `ux` and `impact-analyst`, haiku for `mechanical` tasks and qa RETEST) | cost control. A task's `complexity` picks haiku / sonnet / opus; a `mechanical` task that hits a decision or breaks the checkpoint is re-run once on sonnet rather than letting the small model guess |

## Known gaps

- **Not run end to end.** No feature has gone through the 2.2 pipeline in a real project. Everything above is checked structurally, not behaviourally.
- **No behavioural evals yet.** `claude plugin eval` is in early access and was not available on the maintainer's account. When it is, the first cases worth writing: `sa` returns `OUTLINE` for a large request and writes no requirements; `tech-lead-plan` adds a task for a design element claimed as "existing" that Grep cannot find; `developer` returns a `GAP:` line instead of building a missing shared component inside its own files.
- **`sa.md` is ~15k characters, `ux.md` ~12k**, above the ~10k guidance for one agent prompt. Moving the cross-layer survey out to `impact-analyst` brought `sa` down from ~18k; most of what remains is the requirements, design and outline templates `sa` writes from, which cannot leave the file while subagents cannot read each other's files.
- **`ux` AUDIT reads source and screenshots, not a running app**, unless the project names a screenshot command.

## Keeping the standard when you change the plugin

1. Run `python3 -I scripts/check-plugin.py` — it must report 0 errors. It checks the contracts between files: artifact names, template section numbers, GAP kinds, STATUS values, complexity → model mapping, developer's `sed` ranges against the task template, the AC rules shared by `sa` and `ba`, frontmatter, manifests, terms retired by earlier designs — and runs the guard scripts against must-block / must-allow inputs. A guard change needs a case in `GUARD_CASES` for what it newly blocks or allows.
2. Renaming or removing a concept? Add the old term to `RETIRED_TERMS` in the checker, so a half-finished rename fails.
3. Adding an artifact file? Add it to `ARTIFACTS` in the checker and to "Files per feature" in `hooks/orchestrator.md`.
4. Changing what a role does? Check its row in the first table above still holds, or update the row.
5. After a real feature, `/agent-team:retro` reports `PLUGIN:` recommendations. Those are field evidence of defects in this plugin — collect them in an issue rather than letting them disappear with the project.
6. Bump `version` in both manifests; `claude plugin validate .` must pass.
