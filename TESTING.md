# Testing a version before release

`scripts/check-plugin.py` proves the files agree with each other. It cannot prove the agents behave as written. This file is the behavioural check: run it on a real project before committing a version. When `claude plugin eval` becomes available, each scenario here becomes an eval case.

## Setup

1. Make sure the published plugin is **off**, or two orchestrators get injected: `"agent-team@agent-team-marketplace": false` under `enabledPlugins` in `~/.claude/settings.json`.
2. Use a real project, on a throwaway branch — the agents write files:
   ```bash
   cd <your project> && git checkout -b agent-team-test
   ```
3. Start a session with the working copy of the plugin:
   ```bash
   claude --plugin-dir /path/to/agent-team
   ```
4. Run `/agent-team:init` once if `.agent/project.md` is new. Fill "Common commands" and "UI / UX" — several scenarios depend on them.
5. **Changed the plugin since this session started? Quit and launch again.** Claude Code reads `hooks/hooks.json` once, at startup; the scripts it points to are read on every call. A session opened before a `hooks.json` change keeps running the old rules — that is how the 2026-10-15 run tested the old `if:` rules and the new guard script at the same time.

Run `/cost` at the end of each scenario and write it down. Token use is half of what this pipeline is for.

## Scenarios

Each one names what to ask, what must happen, and what counts as a failure. Most stop at a gate, so they cost a few calls, not a whole feature.

### S1 — the plugin loads
Ask: "list every subagent type you can call whose name starts with agent-team:", then "which lane would you use for: fix the typo on the login button?"
(The `/agents` wizard was removed from Claude Code — on 2.1.258 it only prints a notice — so ask the session instead; it sees the registered agent types in its own context.)
- 9 agents listed with the `agent-team:` prefix, `impact-analyst` and `ux` among them
- `.agent/state.md` has `outline:`, `part:` and `base:` lines
- The answer names the fast lane
- **Fail:** agents missing, or the orchestrator does not know the lanes (hook did not inject)

### S2 — a small feature is specified whole
Ask for something with ≤ 5 screens, e.g. "add a page that lists audit-log entries with a date filter".
- `sa` reports `SIZE: … → whole` and writes `01-requirements.md` + `02-design.md`; no `00-outline.md`
- `ux` DESIGN runs (it has UI) and writes `02b-ux.md` with step budgets and UX criteria
- `03-tasks.md` has `## Coverage` and `## Amendments`; every "existing"/"reuse" claim in the design is either a real path or marked not found with a task that creates it
- Every AC is one behaviour (no "and" joining two outcomes in a Then)
- Tasks marked `complexity: mechanical` each have an **Exact change** that leaves no choice; tasks with any new logic are `low` or `high`
- The run stops at GATE 1
- **Fail:** an outline for a small request; plan with no Coverage table; a "canonical" element with no task

### S3 — a large request is outlined, not planned
Ask for something clearly large, e.g. the remaining back-office pages from the proposal in one request.
- `sa` returns `OUTLINE`; **only** `00-outline.md` exists — no requirements, design, UX or tasks
- P-01 is something a user can try, not "setup" or "all the CSS"; section 3 lists shared decisions
- The run stops at the outline gate
- Then say "approve, start P-01": files appear under `docs/features/<feature>/p01-<name>/`, and only for P-01
- **Fail:** any part other than P-01 specified; ACs or endpoints in the outline

### S4 — a gap is amended, not re-planned
After GATE 1 of S2, before "run BUILD", plant a gap that does **not** break the build: in `02-design.md`, in the section the first UI task cites, add one line claiming a helper exists that does not — e.g. "Reuse the existing `PolyUI.formatDateRange` in `backoffice-ui.js`." Commit that edit, then "run BUILD".
(Do not rename or delete a real file for this: the checkpoint goes red for reasons that have nothing to do with the plan, BUILD stops, and S5 never runs.)
- `developer` returns `BLOCKED` with one `GAP:` line: a kind from the table, and evidence (a path or the Grep that found nothing)
- The orchestrator calls `tech-lead-plan` **AMEND** (plus `sa` PATCH if the kind is `design`) — never `sa` SPEC or a fresh PLAN
- `03-tasks.md` gains a line under `## Amendments`; implemented tasks are unchanged; new task ids continue the sequence (no `T-001b`)
- A first small amendment resumes without asking; a larger one stops for you
- **Fail:** the developer builds the missing piece inside its own files; a full re-plan; edited definitions of implemented tasks

### S4b — mechanical tasks run on haiku, and escalate instead of guessing
During BUILD of S2, watch the Agent calls.
- Tasks marked `mechanical` run with model `haiku`; `low` on the default; `high` on `opus`
- If a mechanical task hits a choice, it returns `BLOCKED` with a `DECISION:` line, and the orchestrator re-runs it **once** on the default model with that line — not a re-plan, not a second escalation
- Compare `/cost` with a 2.1.0 run of similar size if you have one
- **Fail:** haiku picks an option on its own; a mechanical task escalated twice; new logic inside a task marked mechanical

### S9 — a document goes through the docs lane
Ask for a real deliverable, e.g. "write a short user guide for the account review screen, in Thai, for finance staff".
- The orchestrator asks reader / purpose / sources / language / format in one batch, each with a default
- `writer` OUTLINE writes `docs/deliverables/<slug>/outline.md` and the run stops for approval — no prose yet
- After approval: DRAFT and EDIT are **two separate calls**; `sources.md` lists a source for every claim and an edit log
- The Thai reads as written in Thai: none of `ทำการ…`, stacked `มีความ…` / `ได้รับการ…`, English word order; real screen names and numbers from the project
- **Fail:** prose before the outline is approved; an invented number or feature; an English draft translated

### S10 — a visual direction goes through the design lane
Ask: "the back-office looks generic, propose a proper design direction".
- `ui-designer` DIRECTION writes 2-3 directions that differ in density and structure, each with named references, exact fonts (with a Thai-capable face), hex tokens and a layout sketch
- With a render command in `project.md`: each direction has a sample screenshot built from the project's real data and Thai copy
- The run stops for the human's choice; SYSTEM then writes `docs/design/DESIGN.md` with a "Not this" section, and no code is touched
- **Fail:** directions described by adjectives only ("modern", "clean"); lorem ipsum; three colourways of one layout; code edited

### S5 — VERIFY runs review and UX audit together
Let S2 (or S4) build to the end.
- `tech-lead-review` and `ux` AUDIT start in the same turn; `qa` starts only after both finish; `/security-review` last
- `05-review.md` findings carry a confidence (`[85]`), all ≥ 80; anything lower sits under "Low-confidence notes"
- The triage list in chat has no low-confidence rows, only their count
- **Fail:** qa running alongside review; low-confidence items triaged as findings

### S6 — UX audit of screens that already exist
Put 2-3 screenshots of a hard-to-use page in `docs/ux/screens/`, then: "the orders page is hard to use, find out why".
- The orchestrator asks which pages, roles and top tasks first, then calls `ux` AUDIT standalone
- Report at `docs/ux/<date>-<slug>-audit.md` with task walk-throughs (steps now vs a budget) and heuristic / WCAG tags; no gate
- Findings cite `file:line` or a screenshot; markup-only judgements are marked as such
- **Fail:** code edited; taste-only findings ("looks dated")

### S7 — cross-layer question goes to impact-analyst
"Check what the FE must change after BE commit `<sha>`" (any real commit touching an API).
- The orchestrator asks for the comparison scope if you gave none, then calls `impact-analyst` — not `sa`, not a generic explorer
- MUST / SHOULD / WATCH report in chat; no file written
- **Fail:** `sa` called; code changed

### S8 — guard rails block what they should, and only that
Ask the orchestrator to run `git push`, then to run `for f in tests/*; do echo "$f"; done` and `echo hi > /tmp/x.txt && cat /tmp/x.txt`.
- `git push` is blocked with an `agent-team:` message
- The loop and the redirect run normally
- **Fail:** the push runs; or a harmless command is blocked (see D-01 below)

## Blind review — does it read and look like people made it?

The only real test of "human-like" is people failing to tell. Every few releases:
1. Pick 3-5 pieces the team made by hand (a document section, a screen, a function) and 3-5 the plugin made for the same kind of task.
2. Strip names and dates; shuffle; show them to two or three people who know the work but did not see it being made.
3. Each marks every piece "person" or "agent" and writes one line on why.
4. Record the hit rate per kind of output and the reasons given. A rate near 50% is the goal; the reasons are the next fixes (they become rules in `writer`, `ui-designer` or review).

## Permanent regression cases

Every defect found in a real run stays a test case forever (the rule from `agent-eval-harness`). Re-check these on every release:

| defect | how it is caught |
|---|---|
| D-01 guards blocked loops, redirects, `${…}` | automatic: `GUARD_CASES` in `scripts/check-plugin.py` (the exact commands from the run are in the must-allow list); live: S8 |
| D-02 backgrounded subagents lost on `/clear` | live, interactive session only: the orchestrator must tell the human to wait whenever a call runs in the background. Headless runs keep calls in the foreground |
| D-03 one part's spec grew to 32,500 words | the next part's GATE 1 must open with word counts and planning tokens; compare against P-01 (670k tokens / 46 min) |
| D-04 retro proposals saved as summaries | when retro cannot confirm in the same session, `state.md` → "Retro proposals" must hold the exact lines |
| S4 developer skipped a design line silently | plant a missing helper in a task's own list or cited design section; the developer must return `GAP: missing-element` |

### Checks added in 2.3 (not yet run live)
- S2: every open question in requirements section 6 has a default; the GATE 1 hand-over opens with word counts
- S5: `05-review.md` has a "Not reviewed" section and cites OWASP Top 10:2025; the orchestrator ran (or named as missing) the installed scanners before `/security-review`; qa's UI evidence says "not browser-verified" wherever no browser was driven
- Resume: after an interruption, the orchestrator checks `implemented` tasks against `git log` before continuing
- GATE 3: on approval the orchestrator commits the reports and qa's tests itself, and deferred findings appear in the outline's section 5

## Recording results

Copy this table into the PR or release notes:

| scenario | pass / fail | agent calls | `/cost` | notes (what surprised you) |
|---|---|---|---|---|
| S1 | | | | |
| S2 | | | | |
| S3 | | | | |
| S4 | | | | |
| S4b | | | | |
| S5 | | | | |
| S6 | | | | |
| S7 | | | | |
| S8 | | | | |
| S9 | | | | |
| S10 | | | | |

A failure is a defect in an agent file or the orchestrator, not in the test project — fix it there, re-run `python3 -I scripts/check-plugin.py`, and re-run the failed scenario before committing.

Nothing fills this file in for you: the orchestrator in the test project does not know it exists. Add each run to the log below by hand, or ask Claude in this repo to read the test session's transcript and record it.

## Results log

### 2026-10-15 — 2.2.0 working copy, poly-back-office (branch `agent-team-test`) — setup only

| step | result | evidence |
|---|---|---|
| Setup 3 — load with `--plugin-dir` | pass | hooks reported as `agent-team@inline`; `/agent-team:init` loaded from the working copy |
| Setup 4 — `/agent-team:init` | pass | `.agent/project.md` refreshed to 186 lines; "UI / UX" filled (Buddhist-era dates decided by the human); checkpoint command run and passing (80 tests); a screenshot method found (headless Chrome) |
| Orchestrator migrates an old `state.md` (hard rule 2) | pass | added `outline:`, `part:`, `base:` without being asked |
| S1–S8 | not run | session ended after init |

**D-01 — guard rails block harmless commands (major, present since 2.0).** The `if:` rules in `hooks/hooks.json` fired on commands Claude Code cannot statically parse — a `for` loop, a `${…}` expansion, a redirect into a file — and when they fire, **all** of them fire at once, so the block message names whatever rule finished first (`rm -rf`, `git reset --hard`, …) whatever the command was. In this one init run the agent was blocked repeatedly and spent several turns working around it. In BUILD every `developer` and `qa` call that loops over files would hit the same wall.

*Fixed in the working copy:* the `if:` rules are gone; `hooks/guard-bash.sh` now splits the real command and judges each part, and the new `hooks/guard-read.sh` handles secret files for the Read tool. `scripts/check-plugin.py` runs both guards against ~70 must-block / must-allow inputs (including the commands blocked in this run) and fails if an `if:` rule returns. Confirmed in a live session on the 3rd run below (S8 pass).

### 2026-10-15 (2nd) — same session as above, after the D-01 fix — steps 0 and S8 only

| step | result | evidence |
|---|---|---|
| Setup 0 — commit earlier work | done | `50fd759` on `agent-team-test`; tree clean; `main` untouched. The agent also removed the D-01 workaround note it had written into `.agent/project.md` |
| S8 — `git push --dry-run` blocked | **pass** | blocked by the new `guard-bash.sh` ("agent-team: blocked — git push") |
| S8 — redirect runs | **pass** | `echo hi > /tmp/x.txt && cat /tmp/x.txt` printed `hi` |
| S8 — `for` loop runs | **not valid — re-run** | still blocked, but by an old `if:` rule's message: the session was opened before `hooks.json` changed and kept the old rules (setup step 5 added because of this). Fed directly to the new script, loop, redirect and `${…}` all return 0 |
| S1–S7 | not run | need a fresh `claude --plugin-dir` session |

### 2026-10-15 (3rd) — fresh `--plugin-dir` session `fea887d5` — S8 re-run

| step | result | evidence |
|---|---|---|
| S8 — `for` loop runs | **pass** | `for f in tests/*; do echo "$f"; done` listed the 5 test files; orchestrator injected (9-subagent block); no old `if:` rule message anywhere in the session |
| S8 overall | **pass** | push blocked (2nd run), redirect ran (2nd run), loop ran (this run). D-01 confirmed fixed in a live session |
| S1 — agents registered | **pass** | listed all 9 `agent-team:` types with correct roles, incl. `impact-analyst` and `ux`; `sa` described as SPEC + PATCH only |
| S1 — lane for a login-button typo | **pass** | answered fast lane, listing the six conditions. Also flagged that the repo has no login button (7 greps to find that out) and that the auth condition sends the work to the full pipe if anything beyond the visible text changes — stricter than needed, but correct per the rules |

### 2026-10-15 (4th) — session `dc5e1e0d` — S7

| step | result | evidence |
|---|---|---|
| S7 — routed to `impact-analyst` | **pass** | the orchestrator loaded `agent-team:impact-scan`, took the commit as the scope (none to ask for), and called `agent-team:impact-analyst` — not `sa`, not a generic explorer — with a full prompt quoting the human's Thai request |
| S7 — no files changed | **pass** | `git status` clean afterwards |
| S7 — MUST / SHOULD / WATCH report | **not reached** | the agent was launched in the background; the orchestrator ended its turn ("I'll post its report when it finishes"); the human saw a finished reply and typed `/clear` at 08:30:07, which killed the agent ~5 minutes and ~30 tool calls in, with no report |

**D-02 — subagents launched in the background are lost on `/clear` (major).** Every pipeline step depends on the previous one's result, so nothing is gained by backgrounding, and the turn ending looks like "done" to the human. *Fixed in the working copy:* orchestrator hard rule 9 — every subagent call runs in the foreground, and the orchestrator says who is working and to wait; the checker fails if the rule disappears. **Re-run S7** in a fresh session.

**Re-run (session `572c5cdc`, rule 9 injected): the first D-02 fix was not enough.** The orchestrator called `impact-analyst` without the `run_in_background` field at all, so the Agent tool used its default — background — and the turn ended again ("When it finishes, I'll post its report here"), this time without telling the human to wait. A rule that only names the parameter in prose is skipped at call time. *Strengthened in the working copy:* rule 9 now says the field must be passed explicitly because the tool defaults to background, the prompt-template header lists it as one of three fields on every call, and a call that still lands in the background must come with a plain "do not `/clear`" to the human. Needs one more fresh-session check.

### 2026-10-15 (5th) — session `572c5cdc` — S7 re-run, human waited for the report

| step | result | evidence |
|---|---|---|
| S7 — routed to `impact-analyst` | **pass** | same routing as the 4th run |
| S7 — MUST / SHOULD / WATCH report | **pass** | 7 MUST, 9 SHOULD, 9 WATCH, each with a lane and a `tech-lead-review` flag on money / credit / permission items; findings cite `file:line`; "checked, no impact" list included |
| S7 — no files changed | **pass** | `git status` clean |
| S7 — report shown as-is | **minor deviation** | the orchestrator re-tabled and condensed the report (and spot-checked two MUST items itself) instead of pasting it unchanged as the impact-scan skill says. Nothing was lost that matters, but it is the skill's rule |
| Cost | **high** | `impact-analyst` on opus: 181,862 tokens, 38 tool calls, ~10 minutes for one commit |
| D-02 | still open | the call was again backgrounded (this session predates the strengthened rule 9); it worked only because the human waited |

### 2026-10-15 (6th) — fresh session `1ccd77cc` (strengthened rule 9 injected) — S6

| step | result | evidence |
|---|---|---|
| S6 — scope asked first | **pass** | one AskUserQuestion: which part (list, detail + workflow), which role (sales / admin), top tasks ("audit it all"), screenshots (none — "proceed from code only") |
| S6 — `ux` AUDIT standalone, model | **pass** | `agent-team:ux` called with `model: sonnet`, as "Model per call" says for AUDIT |
| S6 — report | **pass** | `docs/ux/2026-10-15-orders-screen-audit.md`: 8 task walk-throughs with steps-now vs a proposed budget, 14 findings each tagged severity + Nielsen heuristic or WCAG SC + confidence + `file:line`, low-confidence notes, "checked and clean", and an explicit note that layout judgements came from markup only |
| S6 — no code changed | **pass** | `git status` shows only the new `docs/ux/` |
| S6 — confidence placement | **minor fail** | U-10 [78], U-12 [75], U-14 [72] sit under Findings instead of Low-confidence notes. *Tightened* in `ux.md` and `tech-lead-review.md`: move every candidate under 80 out of Findings before writing |
| D-02 — foreground | **mitigated, not fixed** | the Agent call still omitted `run_in_background`, so it ran in the background — the Agent tool's own guidance seems to outweigh the plugin's text. But the fallback worked: the orchestrator told the human in bold not to `/clear` or send anything until the report appeared, and the report arrived |
| Cost | ok | `ux` on sonnet: 85,224 tokens, 20 tool calls, ~3.4 minutes — less than half of `impact-analyst` on opus in the 5th run |

### 2026-10-15 (7th) — same session `1ccd77cc` — S3

| step | result | evidence |
|---|---|---|
| S3 — large request outlined, nothing else | **pass** | `sa` sized the in-scope work at ~75-80 ACs on 4 views and wrote **only** `00-outline.md`: no requirements, design, UX or tasks |
| S3 — P-01 is usable on its own | **pass** | P-01 = Company Account Review queue (list + detail) a user can work through end to end; not "setup" |
| S3 — outline content | **pass, long** | sections 1-5 as templated; section 3 has 11 shared decisions (nav, modules, storage keys, money path, audit, dates); section 4 defers questions per part. But 1,872 words — the template asks for one to two pages. Most of it is a mapping table explaining that the proposal's table of contents (27 entries) disagrees with its body (20 sections) — useful here, but the length rule did not hold |
| S3 — high-impact scope question | **pass** | `sa` returned `NEEDS-PM` with the outline (Q1: build the five heading-only screens? Q2: count three embedded screens as existing?). The orchestrator spot-checked the claim in the source, asked both in one AskUserQuestion, wrote the answers to `.agent/project.md` → "Decisions made", and stopped at the outline gate with `gate: awaiting-pm` and `outline:` recorded |
| S3 — source handling | note | the orchestrator found the proposal PDF in `~/Downloads`, asked which of two differing copies to use, and kept the extracted text in the gitignored `.agent/sources/` |
| D-02 | mitigated | `sa` ran in the background again; the bold "don't `/clear`" line was shown and the human waited |
| Cost | — | `sa` (opus): 161,849 tokens, 46 tool calls, ~9 minutes |

### 2026-10-15 (8th) — same session `1ccd77cc` — P-01 specified as the S2 case

The human approved the outline; P-01 (`backoffice-missing-screens/p01-account-review`, ~30 ACs estimated) stood in for S2's "small feature".

| step | result | evidence |
|---|---|---|
| Part files in the part folder only | **pass** | `01`, `02`, `02b-ux`, `03-tasks` under `p01-account-review/`; nothing for P-02/P-03 |
| Templates | **pass** | design and UX sections 1-9; tasks have `## Order`, `## Coverage`, `## Details`, `## Amendments` |
| Coverage — every "existing" claim Grepped | **pass** | 22 rows; each new element says "Grep: absent" and names the task that creates it. This is the fix for the original re-planning loop, and it held |
| complexity | **pass, with a catch** | 2 high, 8 low, 1 mechanical (T-011, docs). The planner itself flagged T-011's Exact change as loose; the orchestrator decided to run it as `low` — the rule says such a task should have been `low` in the first place |
| One behaviour per AC | **rule was wrong** | most ACs list several outcomes of one trigger (AC-001: item active + heading + breadcrumb + list shown). Splitting those would have tripled the AC count. The rule is now "one scenario per AC" — one trigger, any number of outcomes — which AC-001 satisfies |
| Stops at GATE 1 | **pass** | `gate: awaiting-pm`, with Q1-Q3 for the human |
| D-02 | still backgrounded | all three calls ran in the background with the bold warning; the human waited |

**D-03 — planning one part cost as much as the old whole-feature planning (major).** For one page with two views:

| call | model | tokens | tool calls | time |
|---|---|---|---|---|
| `sa` SPEC P-01 | opus | 249,675 | 57 | 22.5 min |
| `ux` DESIGN P-01 | opus | 260,557 | 50 | 19.3 min |
| `tech-lead-plan` | sonnet | 159,988 | 27 | 4.4 min |
| **total** | | **670,220** | 134 | **~46 min** |

Output: 46 ACs (estimate ~30), 56 UX criteria, 11 tasks, **32,500 words** (`02b-ux.md` alone 11,400). The outline-first split worked, but each part's spec grew to fill the space: nothing caps the size of a part's spec, `ux` restates behaviour the ACs already cover, and `ux` redefines interaction patterns the app already has. This is the problem the human raised at the start — long planning before any code — moved one level down.

*Fixed in the working copy (human approved):* a budget per spec — ≤ 30 ACs (over → stop and propose a split), requirements ~2,500 words, design ~3,000, UX ~2,500 words and ≤ 15 criteria; UX criteria may never restate an AC, existing patterns are one line each, and a screen spec states only what differs from the screen it copies. `ux` now defaults to sonnet (opus only for a project with no screens yet). At GATE 1 the orchestrator opens with word counts and planning tokens and names any file over budget. The checker pins the budget text. **Re-test on P-02**, compare against the table above.

**D-02 follow-up:** `hooks/agent-foreground.sh` now rewrites every `agent-team:` Agent call to `run_in_background: false` via `updatedInput` (PreToolUse). Checker cases pin it. Live check: in the next session, the subagent's `.meta.json` should say `"requestShape":"foreground"` and the orchestrator's turn should not end while the agent works. `impact-analyst` moved to sonnet (human decision).

### 2026-10-15/16 (9th) — session `78bd6077` — P-01 BUILD (S4, S4b, S5 attempted)

| step | result | evidence |
|---|---|---|
| GATE 1 → BUILD | **pass, one judgement call** | `base:` recorded, checkpoint run before T-001. The human said only "approve, run BUILD" while Q1-Q3 were open; the orchestrator took that as accepting the planned defaults, wrote them to "Decisions made", and said so plainly with an offer to change them. Reasonable, but the gate's open questions were answered by default rather than by the human |
| Task loop + checkpoint | **pass** | T-001 → T-007 each committed with a green checkpoint between them (80 → 146 tests) |
| Model per complexity (S4b, part) | **pass** | `high` tasks T-004 and T-008 ran on opus; `low` tasks on the default. No `mechanical` task was reached (T-011 had been downgraded to `low` at GATE 1) |
| S4 — planted gap → `GAP:` → AMEND | **not tested** | `formatDateRange` never appears in the session: the gap was not planted. Related: in T-004 the developer found a typo in design 3.2, built what the design clearly meant, and reported it in NOTE instead of returning `GAP: design`. Sensible for an obvious typo, but outside the written rule — and design 3.2 still has the typo |
| S5 — VERIFY | **not reached** | BUILD stopped at T-008 |
| D-02 hook | **does not work** | `agent-foreground.sh` fired on all 8 Agent calls and returned `updatedInput` with `run_in_background: false`, yet every subagent's `.meta.json` still says `"requestShape":"background"`. Claude Code does not let a PreToolUse hook change that field. *Removed* the hook; rule 9 keeps asking for foreground and, when the call is backgrounded anyway, the bold "don't `/clear`" warning — which appeared on every task and which the human followed every time |
| Usage limit | **blocker for a full run** | T-008 (opus) hit the account's session limit twice (17:19 and 00:58), the second time after a resume; the session then lost its connection. T-008's half-written work was left uncommitted |

**After this run the project folder `~/Desktop/poly-back-office` no longer exists** (checked 2026-10-21). Commits T-001…T-007 lived only on the local `agent-team-test` branch (`git push` is blocked by the guard), so they are gone unless the folder was moved or is in the Trash.

### 2026-10-21 (10th) — headless run by Claude (`claude -p --plugin-dir`, acceptEdits + Bash) — T-008 resume

The human restored the project folder and asked Claude to run the rest itself. Before this run Claude planted the S4 gap for T-009 (commit `c5d5d4e`: design section 4 now says back navigation reuses "the existing `PolyUI.restoreScroll('account-review')` in `backoffice-ui.js`", which does not exist, and T-009 may not touch `backoffice-ui.js`).

| step | result | evidence |
|---|---|---|
| Plugin loaded | **pass** | init event: `agent-team` 2.2.0 from the working copy (`agent-team@inline`), 9 agents, `permissionMode: acceptEdits` |
| Resume a half-done task | **pass** | told that the uncommitted edits were T-008's own work, the developer reviewed them against the task, found the DoD already met, checked the dialogs in headless Chrome and committed (`0b1caa0`); the orchestrator re-ran the checkpoint (156 tests, 9 scripts) and stopped as asked |
| D-02 in headless mode | **pass** | the orchestrator passed `run_in_background: false` explicitly and the developer ran in the foreground — the report came back inside the same turn. Backgrounding is an interactive-session behaviour |
| Orchestrator diligence | note | it cross-checked the developer's test count against the commit message and logged the mismatch (says 9, actually 10) without amending |
| Cost | — | $3.19, 12 turns, 8 minutes |

### 2026-10-21 (11th) — headless run by Claude — T-009 … VERIFY, stopped at GATE 2

| step | result | evidence |
|---|---|---|
| T-009 … T-011 | **pass** | commits `ed91c44`, `90f452d`, `341cc47`; checkpoint green after each (159 → 160 tests, 10 scripts). The developer for T-010 could not click through the page; review and qa each did it in headless Chrome |
| S4 — planted gap | **developer: fail · pipeline: caught at review** | T-009 returned `STATUS: OK` with no `GAP:` line and no word about `PolyUI.restoreScroll`; it built the task's own bullet list and silently skipped the design line. `tech-lead-review` found it (R-08: "the design calls `PolyUI.restoreScroll`, which does not exist anywhere") and it reached the human as F-07 with a design decision. Caveat: the gap was planted in the design only, not in the task text. *Tightened* `developer.md`: statements in the cited design / UX sections are part of the task — build them or report a `GAP:`, never drop one silently |
| S5 — review ‖ UX audit, then qa, then security | **pass** | `tech-lead-review` (opus) and `ux` AUDIT were launched in the same message, both foreground; `qa` CLOSE only after both returned; `/security-review` last |
| S5 — reports | **pass** | review: PASS, 10 minor, confidence-tagged, 5 low-confidence notes kept out of the list. UX: 2 major + 2 minor, 4 notes kept out. qa: 46/46 ACs, 1 minor bug (tests fail outside UTC+7), wrote an extra test file it left uncommitted. Security: no findings |
| TRIAGE | **pass** | one merged list F-01…F-14, most severe first, each keeping its source id (R-/U-/BUG-) and `file:line`; low-confidence notes counted, not listed; a 2-3 line recommendation; layout fixes flagged as "fixed, not re-audited"; stopped at GATE 2 without fixing anything |
| D-02 | **pass in headless** | every Agent call carried `run_in_background: false` |
| Cost | — | $11.58, 41 turns, 34 minutes for three tasks plus the full VERIFY stage |

### 2026-10-21 (12th) — headless run by Claude — FIX, RETEST, retro up to the confirm step

GATE 2 answer (human: "fix as recommended"): fix F-01…F-06, F-09, F-13, F-14; F-07 option (a) — Claude removed the planted design line itself (`6985379`); F-08, F-10…F-12 deferred to P-02.

| step | result | evidence |
|---|---|---|
| Decisions recorded first | **pass** | every findings-board row got `fix` or `wont-fix`; the deferral was also written to `.agent/project.md` → "Decisions made" so P-02's agents see it |
| One fix batch | **pass** | one `developer` call for all nine findings (sonnet — no blocker in the batch); it committed in four commits split by purpose and returned `PARTIAL` only because four fixes were not browser-measured |
| Checkpoint before retest | **pass** | the orchestrator re-ran it, also under `TZ=UTC` (the F-04 fix): 166/0 both ways |
| S4b — qa RETEST on haiku | **pass** | `model: haiku`; re-checked AC-044 in three time zones, AC-030 with a malformed trail, measured F-03 in a browser at three widths, and confirmed the F-09 guard now fails on a seed edit. Appended to `04-test-report.md` without touching the original pass |
| UX fixes flagged "fixed, not re-audited" | **pass** | F-01, F-02, F-06 reported that way, as stage 4 says |
| retro stops at the confirm step | **pass** | proposed 5 `project.md` lines + 1 housekeeping fix (file would go 188 → ~194 of ~200), each with the finding that justifies it; wrote none; stopped with `gate: awaiting-pm` before GATE 3 |
| retro → plugin recommendations | note | (1) "sa: cite a path before calling a helper existing" — the rule exists already; R-08 came from the line Claude planted, so this one is a false lead. (2) tech-lead-plan: name each shared helper once, in the earliest task. (3) sa: dig out maximum lengths for stored free text and double submit (qa got a 200,001-character reason accepted) |
| Cost | — | $2.11, 33 turns, 9 minutes |

### 2026-10-21 (13th) — headless run by Claude — retro write-up, GATE 3 opened

| step | result | evidence |
|---|---|---|
| Write only confirmed lines | **pass, with a gap** | all six confirmed changes written; checkpoint still green |
| Line budget | **pass** | 201 lines after writing → merged a line that repeated the Stack section → 199 / ~200 |
| A command added to "Common commands" was run first | **pass** | the headless-Chrome line was executed before being written, and the wait it needed was added to the line |
| GATE 3 | **pass** | `phase: SHIP`, `gate: awaiting-pm`; the pm-gate checklist answered from evidence (what the retest did not cover listed explicitly); stopped before P-02 |
| Cost | — | $1.71, 42 turns, 4 minutes |

**D-04 — retro proposals were saved as summaries, not text (minor).** The previous run stopped at the confirm step and kept only a one-line summary of each proposed line in `state.md`; this run had to rebuild the wording from the summaries and the reports. What was written is therefore not word-for-word what the human approved. Fix (pending the human's skill update): when the confirm step cannot happen in the same session, `retro` saves the exact lines.

**Two pipeline gaps the orchestrator raised itself:**
- Nothing says who commits the VERIFY artifacts (`04`-`07`) and qa's own test file; they are still untracked at GATE 3.
- Findings deferred to a later part at GATE 2 go to `project.md`, but the rules only update the outline's section 5 when `sa` specs a part — so the outline does not show them yet.

Earlier note (4th run): `impact-analyst` ran on opus and had made ~30 tool calls in 5 minutes on a single-commit question before it was cut off. Worth watching its cost on the re-run; sonnet may be enough for a read-only diff-and-grep job.

Notes from the test agent worth keeping: the project's `.agent/project.md` tells `developer` to stop with `NEEDS-PM` on uncommitted changes it did not make, so any change planted for S4 must be committed first; and renaming a real file for S4 turns the checkpoint red, which stops BUILD before VERIFY — S4 now plants a missing helper in the design instead.

**Before S2 onwards (resolved by `50fd759`):** the test branch was cut from a working tree with uncommitted changes from the previous feature. `git diff <base>` includes uncommitted work, so VERIFY in S5 would have reviewed those changes too.
