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
| `tech-lead-review` | Google Engineering Practices, "What to look for in a code review"; OWASP Top 10:2025 for the security pass; confidence ≥ 80 filter from the official `pr-review-toolkit` reviewer; reproduce before reporting, a "Not reviewed" section and a cap of ~15 findings from `code-review-pro` | `tech-lead-review.md` → review order, confidence |
| `qa` | ISTQB test-design techniques: equivalence partitioning, boundary values, decision tables, state transitions; real-browser checks for UI ACs (zero console errors, wait on conditions, role/label selectors) from `browser-test-loop` | `qa.md` → "Always test these", CLOSE step 3 |
| `developer` | the coding-agent failure modes in `ai-coding-guardrails`: never call an API you cannot find, never swallow an error, never report as working what was not run, match the codebase's own style | `developer.md` → INSPECT, "Never" |
| `writer` | Diátaxis (tutorial / how-to / reference / explanation, never mixed); Google-style design docs (context, goals and non-goals, alternatives considered); plain English after the GOV.UK style guide; Thai plain-writing rules (direct verbs, no `ทำการ` / `มีความ` padding, Royal Society transliteration); the Wikipedia AI Cleanup "Signs of AI writing" as the list of tells — used, as that page asks, to find weak substance rather than to swap words | `writer.md` |
| `ui-designer` | a direction derived from the product and named by concrete references, exact type and colour tokens contrast-checked to WCAG 2.2 AA, judged from a rendered sample with real content; table-first density for operational tools | `ui-designer.md` |
| all agents | Anthropic `plugin-dev` agent guidance: second-person system prompt, explicit process, defined output format, least-privilege tools, `color` in frontmatter | every file in `agents/` |

Naming a standard is deliberate: the model already knows these, so one line pulls in a checklist far longer than we could inline, and a reviewer can hold the agent to it.

## Where this plugin departs from the official plugins, and why

Compared with `feature-dev` (explore → clarify → architect → implement → review) and `pr-review-toolkit`:

| official practice | this plugin | why |
|---|---|---|
| 2-3 explorer / architect / reviewer agents in parallel | one agent per stage; only `tech-lead-review` and `ux` AUDIT run together in VERIFY | agents here write files, and parallel writers clobber each other. Review and UX audit only read code, so they share a turn; `qa` writes tests, so it waits |
| clarifying questions asked and answered before any design | `sa` stops with `NEEDS-PM` only for high-impact questions; the rest go to requirements section 6 — at most 6, each with a default (from `grill-the-brief`) — and are answered at GATE 1, where an approval without answers means the defaults stand | one stop before code instead of two. The risk: a medium-impact assumption gets designed around before a human sees it — the default column makes it visible |
| review findings fixed right after review | findings from review, qa, UX audit and security are triaged once, by a human, then fixed in one batch | the per-task review ↔ qa loop cost ~11 calls per task in 1.x |
| `model: inherit` recommended | fixed models per role (opus for review; sonnet for specs (`sa`, with a section-4 checklist that keeps edge cases) and elsewhere, including `ux` and `impact-analyst`; haiku for `mechanical` tasks and qa RETEST) | cost control. A task's `complexity` picks haiku / sonnet / opus; a `mechanical` task that hits a decision or breaks the checkpoint is re-run once on sonnet rather than letting the small model guess |

## Output that reads as made by people

Generic, template-like output comes from having nothing to copy and no second look. 2.3 adds the first two levers; the third is the human's:

- **Something to copy.** `project.md` gains "Voice and style" (mined by `init` from the team's own documents) and "Reference work" (the human's best examples). `ux` models screens on the reference screens; `developer` matches the codebase's comment density and idioms.
- **A named list of tells, checked at review.** `tech-lead-review` treats machine-written code (restating comments, impossible-state checks, single-use wrappers, generic names) as a convention finding; `ux` checks a made-by-a-template look and translated-sounding Thai copy.
- **The human's taste at GATE 3** — "does this read like your team made it?" is on the checklist, because no agent can answer it.

- **Roles built for it.** `writer` (docs lane) drafts deliverables in the reader's language from real sources, and a second `writer` call edits the draft cold; `ui-designer` (design lane) proposes distinct directions with rendered samples and writes the chosen one to `docs/design/DESIGN.md`, which `ux`, `developer` and the UX audit then follow.

What the research says, in one line each — and how the plugin uses it:
- Removing tell-tale words does not make text good; the tells sit on top of vague substance (Wikipedia, *Signs of AI writing*: "do not merely treat these signs as the problems to be fixed"). → `writer` rules start with specifics and sources; the tells list comes last.
- Banning one AI design default produces the next one (cream and terracotta after purple gradients); naming a reference and locking tokens in a design file is what holds (*avoid-ai-design*, and design-system guides). → `ui-designer` names references and values; `DESIGN.md` has a "Not this" section.
- AI-assisted code shows more duplicated blocks and copy-paste over reuse (GitClear, *AI Copilot Code Quality 2025* — correlational). → `developer` Greps for an existing helper and never copy-pastes; review flags it.
- Plan → write → refine pipelines and reviewers who did not write the draft improve long-form output (SuperWriter; LLM Review). → outline gate, then DRAFT and EDIT as separate `writer` calls.

Sources: [Wikipedia: Signs of AI writing](https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing) · [GitClear 2025](https://www.gitclear.com/ai_assistant_code_quality_2025_research) · [avoid-ai-design](https://github.com/funboy322/avoid-ai-design) · [Diátaxis, via GitHub's documentation guide](https://github.blog/developer-skills/documentation-done-right-a-developers-guide) · [Design docs at Google](https://www.industrialempathy.com/posts/design-docs-at-google/) · [GOV.UK content guidance](https://guidance.publishing.service.gov.uk/writing-to-gov-uk-standards/plan-manage-content/understand-content-design) · [SuperWriter](https://pith.science/paper/2506.04180) · [LLM Review](https://arxiv.org/html/2601.08003v1) · Thai wordiness and foreign-construction notes: [gotoknow 399419](https://www.gotoknow.org/posts/399419), [gotoknow 455901](https://www.gotoknow.org/posts/455901), [5C concise writing, municipal manual](https://donjadee.go.th/pdf/a309.pdf), [IPSR transliteration guidance](https://ipsr.mahidol.ac.th/wp-content/uploads/2023/12/manual-newsletter-26July2023.pdf). The specific Thai patterns (`มีความ`, `ได้รับการ`, `ในการที่จะ`) are standard editing advice but were not found stated in an authoritative source; treat them as house rules a Thai editor should confirm.

## Adapted from other libraries

Rules adapted (rewritten, not copied) from **OneWave AI, claude-skills** (MIT License, © 2025 OneWave AI): `grill-the-brief` (defaults on open questions), `ai-coding-guardrails` (developer rules), `browser-test-loop` (qa and ux browser checks), `code-review-pro` (OWASP 2025, reproduce, "Not reviewed", finding cap), `plan-in-files` and `session-handoff` (check the board against git before resuming; the stop note), `static-analysis-sweep` (run installed scanners in VERIFY), `accessibility-auditor` (keyboard walk), `agent-eval-harness` (every defect becomes a permanent test case). Not adopted, and why: `agent-army` / `sub-agent-orchestrator` (parallel writers, which this plugin forbids), `before-you-build` (business validation, not delivery), `test-coverage-improver` (coverage targets instead of ACs), `claude-design-critic` (marketing sites, not tools).

## Known gaps

- **`writer` and `ui-designer` have not run yet** (scenarios S9 and S10). Their rules come from the research above, not from a field run.
- **One full run so far.** P-01 of a real back-office went through spec → build → verify → fix → ship on 2.2 (see `TESTING.md`). The 2.3 rules above are checked structurally only; the spec budgets and the developer's no-silent-skip rule still wait for a P-02 run.
- **No automated behavioural evals yet.** `claude plugin eval` is in early access and was not available on the maintainer's account; the scenarios in `TESTING.md` are run by hand or headless with `claude -p --plugin-dir`. When it is, the first cases worth writing: `sa` returns `OUTLINE` for a large request and writes no requirements; `tech-lead-plan` adds a task for a design element claimed as "existing" that Grep cannot find; `developer` returns a `GAP:` line instead of building a missing shared component inside its own files.
- **`sa.md` is ~16k characters, `ux.md` ~13.5k**, above the ~10k guidance for one agent prompt. Moving the cross-layer survey out to `impact-analyst` brought `sa` down from ~18k; most of what remains is the requirements, design and outline templates `sa` writes from, which cannot leave the file while subagents cannot read each other's files.
- **`ux` AUDIT reads source and screenshots, not a running app**, unless the project names a screenshot command.

## Keeping the standard when you change the plugin

1. Run `python3 -I scripts/check-plugin.py` — it must report 0 errors. It checks the contracts between files: artifact names, template section numbers, GAP kinds, STATUS values, complexity → model mapping, developer's `sed` ranges against the task template, the AC rules shared by `sa` and `ba`, frontmatter, manifests, terms retired by earlier designs — and runs the guard scripts against must-block / must-allow inputs. A guard change needs a case in `GUARD_CASES` for what it newly blocks or allows.
2. Renaming or removing a concept? Add the old term to `RETIRED_TERMS` in the checker, so a half-finished rename fails.
3. Adding an artifact file? Add it to `ARTIFACTS` in the checker and to "Files per feature" in `hooks/orchestrator.md`.
4. Changing what a role does? Check its row in the first table above still holds, or update the row.
5. After a real feature, `/agent-team:retro` reports `PLUGIN:` recommendations. Those are field evidence of defects in this plugin — collect them in an issue rather than letting them disappear with the project.
6. Bump `version` in both manifests; `claude plugin validate .` must pass.
