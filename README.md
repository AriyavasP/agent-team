# Agent Team

A Claude Code plugin: an 11-role subagent team (BA, SA, UX, UI Designer, Writer, Impact Analyst, Tech Lead x2, Developer, QA, DevOps) plus an orchestrator that sets itself up in every project — no files to copy.

All plugin instructions, artifacts and agent reports are in English. Thai notes for Thai users are at the end.

## Install

```
/plugin marketplace add AriyavasP/agent-team
/plugin install agent-team@agent-team-marketplace
```

Or locally (to test before publishing):

```
/plugin marketplace add /path/to/agent-team
/plugin install agent-team@agent-team-marketplace
```

Once enabled, **open any project** — on the first session there the plugin will:
1. Create `.agent/project.md`, `.agent/state.md`, `docs/features/`, `docs/fixes/`, `docs/impact/` if missing (never overwriting)
2. Inject the orchestrator instructions into context every session (via the `SessionStart` hook — replacing the need to copy a `CLAUDE.md` into the project)

Confirm with `/plugin list`.

## Before the first task in a project

The `.agent/project.md` the hook creates is an empty template. Run:

```
/agent-team:init
```

It mines stack, commands and conventions from the real code and asks only what it cannot mine. This is the highest-return file in the system — every agent reads it on every call.

## Flow

```
you write the request
  → sa (SPEC mode)  sizes it first:
                      fits in one go (≤ ~30 ACs, ≤ 5 screens) → 01-requirements.md + 02-design.md, one call
                      too large → 00-outline.md only → [outline gate] → each part below runs this whole flow on its own
  → ux (DESIGN)     → 02b-ux.md                          ← UI work only: flows, screen specs, UX-criteria
  → tech-lead-plan  → 03-tasks.md                        ← Coverage table: every design element → a task
                    → [GATE 1: you approve them together]   ← the only stop before code

  you say "run BUILD":

  1. IMPLEMENT   developer T-001 → T-002 → … straight through, no review or qa in between
                 (between tasks the orchestrator only runs the project's build/test command itself — no agent call)
                 a developer hits a gap → GAP line → tech-lead-plan AMEND (sa PATCH first if it is a design gap)
                   small first gap: patched and resumed; anything bigger: [amendment stop]
  2. VERIFY      ONE pass over the diff since BUILD started, each of these exactly once:
                   tech-lead-review FEATURE mode → 05-review.md   (R-01, R-02, …)  ┐ together —
                   ux AUDIT mode (UI work)       → 07-ux-audit.md (U-01, …)       ┘ both read-only
                   qa CLOSE mode                 → 04-test-report.md (BUG-01, …)    then
                   /security-review                                                  then
  3. TRIAGE      everything found is merged into one severity-ranked list F-01…
                 → [GATE 2: YOU pick which ids get fixed]  ← the run stops here
  4. FIX         one developer call fixes the whole batch → 06-fixes.md
                 qa RETEST mode: those ACs + full regression, once
                 → report and stop, pass or fail

  → /agent-team:retro → durable lines into .agent/project.md
                                            → [GATE 3: ship]   ← a part: "next part?"
  → devops (when infra changes)
```

**Three gates, not five, and one of them is before code.** `ba` and `sa` used to be two opus calls with a gate each; `sa` in SPEC mode writes both artifacts in one call, surveying the codebase once instead of twice, and `tech-lead-plan` runs before the gate so you approve scope with its price tag attached. `ba` still exists for requirements-only work — it is simply not on the default path. Large work adds one outline gate up front.

**A gap mid-build is patched, never re-planned.** A plan that missed something used to send the run back through `sa` and `tech-lead-plan` in full. Now the developer names the gap in a fixed `GAP:` line and only that gets fixed: `tech-lead-plan` AMEND adds or widens the tasks it needs, `sa` PATCH changes the one design section involved, and implemented tasks are never touched. Most gaps never happen at all: `sa` must cite a real path for anything it calls "existing", and `tech-lead-plan` Greps every such claim and keeps a Coverage table of every design element → task.

**Large work is planned and built one part at a time, not planned whole.** `sa` sizes every request. If it fits in one go it is specified whole; if not, `sa` writes only a one-to-two page outline — the parts, their order, and the few decisions every part must share — and you approve that. Then each part runs the full cycle (spec → ux → plan → build → verify → fix → ship) before the next one is even specified, against the code the earlier parts actually built. You get something usable after the first part instead of after a long planning phase, and nothing is planned on guesses about code that does not exist yet.

**Usability has an owner.** `ux` turns "easy to use" into criteria that can fail — step budgets per task, one primary action per screen, confirmation and error-recovery rules, Thai date/number format, WCAG 2.2 AA — before planning, and audits the built screens against them in VERIFY. It also runs alone on screens that already exist ("the back-office is hard to use"), from source and any screenshots you give it.

**Nothing in BUILD repeats itself.** Review, qa, ux AUDIT and `/security-review` run once each; a fix batch is one call plus one retest; a retest that still fails is reported to you, never retried on the agents' own judgement. The old per-task `developer → review(≤3) → qa(≤2)` loop could spend ~11 agent calls (several of them opus) on a single task and ping-pong between review and qa; this spends **N + 5** for the whole feature (plus two `ux` calls on UI work). Split into parts, each part spends that on its own, plus one outline call up front — VERIFY runs per part over that part's diff only.

At a gate, type `/agent-team:pm-gate` for that gate's checklist.

**Small work and bug fixes**: `/agent-team:fast-lane` — no full pipe.
**After shipping a feature**: `/agent-team:retro` — moves what the reviews and the test report taught you into `.agent/project.md`, under a line budget.
**Investigation questions** ("check what X must integrate after Y changed"): just ask; the orchestrator calls `impact-analyst` (hard rule 6 in `hooks/orchestrator.md`).
**Existing UI that is hard to use**: just say so, and name the pages; the orchestrator calls `ux` in AUDIT mode and you pick which findings go to fast lane or a new feature. Screenshots in `docs/ux/screens/` make the audit much sharper.
**Documents** (SDD, spec, manual, proposal, report, release notes): ask for one; the orchestrator runs `/agent-team:docs-lane` — `writer` outlines it for you to approve, drafts it from the real sources, then a second `writer` call edits it cold, and you read the result.
**How the product looks** (visual direction, design system, redesign): ask; `/agent-team:design-lane` has `ui-designer` propose two or three directions with rendered samples, you choose, and the choice is written to `docs/design/DESIGN.md`, which every later screen follows.

**Something broken in a running system, or ops work outside a feature** (incident, database move, container, configuration): describe it; `/agent-team:ops-lane` has `devops` collect the evidence from logs and git on haiku, judge it on sonnet (severity, cause chain, remediation), and stop for you. No agent runs a command against a real system — you do.

## Roles and models

| agent | model | writes |
|---|---|---|
| `sa` | sonnet | `01-requirements.md` + `02-design.md`, or `00-outline.md` for large work (SPEC mode) / one design section (PATCH mode) |
| `ui-designer` | opus | `docs/design/directions.md` (DIRECTION, with rendered samples) / `docs/design/DESIGN.md` (SYSTEM) — never code |
| `writer` | opus | `docs/deliverables/<slug>/` — outline, document and its sources (OUTLINE / DRAFT / EDIT) |
| `impact-analyst` | sonnet | a chat report: what one side must integrate after the other changed — read-only |
| `ux` | sonnet (opus for DESIGN only in a project with no screens yet) | `02b-ux.md` (DESIGN) / `07-ux-audit.md` or `docs/ux/*-audit.md` (AUDIT) — never code |
| `ba` | opus | `01-requirements.md` — optional, off the default path |
| `tech-lead-plan` | sonnet | `03-tasks.md` (PLAN), or a patch for one gap (AMEND) |
| `developer` | sonnet (haiku when `complexity: mechanical`, opus when `high` or a fix batch with a blocker) | `src/**`, `tests/**` |
| `tech-lead-review` | opus | `05-review.md` (one pass per feature, not per task) |
| `qa` | sonnet (haiku in RETEST mode) | `tests/**`, `04-test-report.md` |
| `devops` | sonnet (haiku for ops COLLECT) | `Dockerfile`, `.github/**`, `k8s/**`, `*.tf` — owns BUILD tasks whose files are infra; in the ops lane, `docs/ops/<slug>/` evidence, incident report or plan |

## Safety

Two `PreToolUse` scripts run in every project where the plugin is enabled:

1. **`hooks/guard-bash.sh`** — reads the real command, splits it into simple commands (`&&`, `;`, `|`, `$(…)`, loops) and judges each by its own command word. Blocks `git push` / `reset --hard` / `clean` (also with a global option first, `git -C dir push`), recursive `rm` in any flag order, `terraform apply|destroy`, `kubectl apply|delete|rollout`, `helm install|upgrade`, `docker push`, `npm|pnpm|yarn publish`, any `aws` / `gcloud` / `az` / `ssh` / `scp`, and any command touching a secret file (`cat .env`, `head ~/.ssh/id_rsa`). `.env.example` / `.sample` / `.template` / `.dist` and identifiers like `process.env` are fine.
2. **`hooks/guard-read.sh`** — blocks the Read tool on `.env`, `.env.*`, `*.pem` and SSH private keys, in any directory.

**There are no `if:` rules in `hooks.json`, on purpose.** Claude Code matches an `if:` pattern against its own parse of the command; when it cannot parse one — a `for` loop, `${…}`, some redirects — every `if:` rule fires at once and harmless commands get blocked under a random rule's name (D-01 in `TESTING.md`). `scripts/check-plugin.py` fails if one comes back, and feeds both guards ~70 must-block / must-allow inputs on `/bin/bash` 3.2.

**These are guard rails against accidents, not a security boundary.** A creative invocation can still get around them — a script that reads the file, an alias, an unusual encoding. Anything where that matters belongs behind Claude Code's own [permission modes](https://code.claude.com/docs/en/permission-modes) and sandboxing, and secrets should not sit in a working tree an agent can reach.

**Verified**: `claude plugin validate` passes; the SessionStart hook injects the orchestrator, scaffolds the project and never overwrites an existing `.agent/state.md`; the guard scripts pass the payload cases in `scripts/check-plugin.py`. On 2.2.0 the plugin was loaded into a real project with `--plugin-dir` and `/agent-team:init` ran end to end (results log in `TESTING.md`).

The guard scripts were also checked in a live session (S8: `git push` blocked; a `for` loop and a redirect run).

**Not verified**: no feature has gone through the 2.x pipeline end to end yet — scenarios S1–S7 in `TESTING.md`.

To add Claude Code's own permission layer on top of the hooks, add this to the project's `.claude/settings.json` (not tested against the parse problem behind D-01 — if it blocks harmless commands, prefer the hooks):

```json
{
  "permissions": {
    "deny": [
      "Bash(terraform apply:*)", "Bash(terraform destroy:*)",
      "Bash(kubectl apply:*)", "Bash(kubectl delete:*)", "Bash(kubectl rollout:*)",
      "Bash(helm install:*)", "Bash(helm upgrade:*)",
      "Bash(docker push:*)", "Bash(npm publish:*)", "Bash(pnpm publish:*)",
      "Bash(aws:*)", "Bash(gcloud:*)", "Bash(az:*)", "Bash(ssh:*)", "Bash(scp:*)",
      "Bash(git push:*)", "Bash(git reset --hard:*)", "Bash(git clean:*)", "Bash(rm -rf:*)",
      "Read(./.env)", "Read(./.env.*)", "Read(./**/*.pem)", "Read(./**/id_rsa*)"
    ]
  }
}
```

Deny rules stack with the hooks; neither replaces the other.

## Design notes and known limits

- **A plugin cannot inject a CLAUDE.md.** This system prints the equivalent content to stdout from a `SessionStart` hook instead (`hooks/orchestrator.md`); the docs confirm Claude Code appends hook stdout to context.
- **`sa` SPEC mode and `ba` both carry the requirements template.** That duplication is deliberate — subagents cannot read each other's files (see the next note) — so a change to the AC rules has to be made in both. `sa` is the one on the default path.
- **Every agent in `agents/` is self-contained** — none of them `Read` a skill file, because a plugin subagent may fail to resolve `.claude/skills/...` inside the target project (the skills live in the plugin package, not the project). Content that used to be separate skills (req-spec, tech-design, task-breakdown, devops-infra) is inlined into each agent.
- **The library.** `library/` holds 51 skills from OneWave AI's claude-skills (MIT), unchanged — technical writing, runbooks, proposals, type and colour systems, dark mode, accessibility, data models, incident response, load testing, review checklists. They are not plugin skills, so they cost nothing per session and cannot be invoked by mistake. The SessionStart hook copies the folder into `.agent/library/` (git-ignored) every session, because subagents are refused reads outside the project. Each agent's "Library" table says which skill fits which task; `library/INDEX.md` says, per skill, what to set aside in it. A library skill is advice below `project.md`, `DESIGN.md` and the agent's own rules.
- **Plugin skills and agents are namespaced.** Skills are always invoked as `/agent-team:<name>` (`/agent-team:pm-gate`, never `/pm-gate`), and agents appear to the Agent tool as `agent-team:sa`, `agent-team:developer`, and so on. The orchestrator instructions account for this.
- `.agent/state.md` belongs to the orchestrator alone; subagents never write it. It carries a task board and a **findings board** — the triage list plus your fix / wont-fix decision on each row.
- **Verification is batched, not incremental, and that is a trade-off.** Reviewing every task as it lands catches a bad pattern before four more tasks copy it; reviewing once at the end costs one opus pass instead of N and puts a human in the loop while the findings are still cheap to act on. The cheap guard against the trade-off is the checkpoint command run between tasks, so `.agent/project.md` → "Common commands" is worth filling in properly.
- No agent reads a whole artifact — they use `sed -n` / `grep -n` on the range they need. So `02-design.md` must keep section numbers 1-9, `02b-ux.md` sections 1-9 and screen ids `S-nn`, and `03-tasks.md` must use `###` only for tasks, never deeper headings, and always quote its ACs inline.
- **`ux` AUDIT reads source and screenshots, not a running app**, unless `.agent/project.md` names a screenshot command. Judgements about layout and visual hierarchy from markup alone are weaker, and the report says which ones they are.
- **Splitting into parts trades some repetition for earlier feedback.** Each part pays for its own review, qa and audit passes, but over a smaller diff, and a wrong guess in the outline costs one part instead of the whole plan. The size threshold (~30 ACs / 5 screens) is a judgement call by `sa`; override it with "spec it whole" or "outline it".
- **Amendment stops trade a little of your time for fewer wasted calls.** Amendments run without a stop only when they are small (the first one, ≤ 2 tasks, no AC or design change).
- **Output that reads as made by people needs something to copy.** `.agent/project.md` has "Voice and style" (mined by `/agent-team:init` from the team's own documents) and "Reference work" (your best human-made examples, in `.agent/references/` or by path). Without them agents fall back on generic, template-like output; review and the UX audit check a named list of machine-made tells, and GATE 3 asks you to look yourself. See `STANDARDS.md`.
- **Token cost**: instructions, artifacts and reports are English by design — except what end users or clients read, which follows "Voice and style". The orchestrator block is injected on every session, so its size is paid every time. The same applies to `.agent/project.md`, which every agent reads on every call — `/agent-team:retro` keeps it under a ~200 line budget by merging rules rather than appending them.
- **Security is spread across the roles, not delegated to one.** `sa` forces role/permission ACs in part A and writes a threat model in part B (design section 8), `tech-lead-plan` marks auth/money/PII tasks `high` so they run on opus, `tech-lead-review` runs a security pass on every diff, `qa` always tests unauthenticated and wrong-role calls, and fast lane refuses this class of work outright. Before ship, `/security-review` looks at the feature as a whole — the one thing per-task review cannot do.

## Signs the system is failing

| Symptom | Real cause is usually | Fix it in |
|---|---|---|
| the same finding comes back after a fix batch | unclear design, not a weak developer | `02-design.md` |
| the triage list is 20 rows, mostly `minor` | conventions too vague to code against | `project.md` |
| `qa` FAILs because an AC reads several ways | ambiguous AC waved through at GATE 1 | `01-requirements.md` |
| developer keeps returning BLOCKED for files outside its list | tasks split along the wrong boundaries | `03-tasks.md` |
| code is correct but does not fit the project | `.agent/project.md` is not detailed enough | `project.md` |
| developer keeps returning `GAP: missing-element` | design calls things "existing" that are not, or coverage skipped shared pieces | `02-design.md` / `03-tasks.md` |
| every AC passes but the UI is hard to use | flows and step budgets were never agreed | `02b-ux.md` |

**Almost every time, the problem is in an artifact, not in an agent's prompt** — fix the content in the agent file (the single source of templates now that subagents read no external skills).

## Developing this plugin

```
plugin.json            version + metadata
marketplace.json       makes this repo its own marketplace (self-hosting)
agents/*.md            11 subagents — each self-contained
skills/*/SKILL.md      only the ones the orchestrator or a human invokes
hooks/hooks.json       SessionStart (inject + scaffold) + PreToolUse (guard)
hooks/orchestrator.md  the injected content — edit here instead of a CLAUDE.md
hooks/session-start.sh scaffolds the target project, then cats orchestrator.md
hooks/guard-bash.sh    the Bash guard: splits the real command and judges each part
hooks/guard-read.sh    the Read guard: secret file names in any directory
library/               51 skills agents read as advice (INDEX.md: who reads which, and what to set aside)
scripts/sync-library.py re-copies the library from a claude-skills clone
scripts/check-plugin.py checks the text contracts between agents, skills and the orchestrator
STANDARDS.md           the standard each role is anchored to, deliberate departures, known gaps
TESTING.md             behavioural scenarios to run on a real project before releasing a version
```

After changing anything, run `python3 -I scripts/check-plugin.py` (0 errors required — see `STANDARDS.md` → "Keeping the standard"), run the scenarios in `TESTING.md` on a real project with `claude --plugin-dir <this repo>`, then bump `version` in `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json` before pushing, then have users run `/plugin marketplace update agent-team-marketplace`.

---

## หมายเหตุภาษาไทย

Plugin นี้ใช้ **ภาษาอังกฤษทั้งระบบ** ทั้ง instruction ของ agent, artifact (`01-requirements.md` ฯลฯ) และรายงานที่ agent ตอบกลับ — เพราะภาษาไทย 1 คำกินประมาณ 3-5 token ส่วนภาษาอังกฤษประมาณ 1-1.5 และ `hooks/orchestrator.md` ถูก inject เข้า context **ทุก session** จึงจ่ายค่านี้ซ้ำทุกครั้ง

คุยกับ orchestrator เป็นภาษาไทยได้ตามปกติ — มันจะตอบและเขียนไฟล์เป็นอังกฤษให้เอง ถ้าอยากได้สรุปไทยท้ายงาน สั่งได้ในแชทเป็นครั้ง ๆ ไป

สรุปการใช้งานสั้น ๆ:

| อยากทำอะไร | พิมพ์ |
|---|---|
| เริ่มใช้ในโปรเจกต์ใหม่ | `/agent-team:init` |
| สร้างฟีเจอร์ใหม่ | บอกโจทย์ตรง ๆ แล้วอนุมัติที่ GATE 1 ครั้งเดียว |
| ตรวจก่อนอนุมัติแต่ละ gate (3 gate หลัก + outline gate สำหรับงานใหญ่) | `/agent-team:pm-gate` |
| บังคับให้แบ่งเป็นส่วน หรือให้ทำทั้งก้อน | ใส่ในคำสั่งว่า "outline it" หรือ "spec it whole" |
| ให้เขียนเอกสาร (SDD, คู่มือ, proposal, รายงาน, release notes) | บอกตรง ๆ ว่าต้องการเอกสารอะไร ใครอ่าน (orchestrator ใช้ `docs-lane`: วางโครง → คุณอนุมัติ → เขียน → ตรวจแก้อีกรอบ) |
| ระบบที่ใช้งานอยู่มีปัญหา (ล่ม, error หลัง deploy) หรืองานดูแลระบบ เช่น ย้ายฐานข้อมูล, container, config | บอกอาการ ตั้งแต่เมื่อไหร่ และ log อยู่ที่ไหน (orchestrator ใช้ `ops-lane`: haiku รวบรวมหลักฐานจาก log และ git → sonnet วิเคราะห์ความรุนแรง สาเหตุ และวิธีแก้ → หยุดให้คุณตัดสินใจ คำสั่งที่แตะระบบจริงคุณเป็นคนรันเอง) |
| ให้ออกแบบหน้าตาใหม่ หรือวางระบบดีไซน์ | บอกตรง ๆ (orchestrator ใช้ `design-lane`: เสนอ 2-3 แนวทางพร้อมภาพตัวอย่างจริง → คุณเลือก → เขียนเป็น `docs/design/DESIGN.md`) |
| แก้บั๊ก/งานเล็ก (≤2 ไฟล์) | `/agent-team:fast-lane` |
| เก็บบทเรียนหลังปิดฟีเจอร์ | `/agent-team:retro` |
| ถามว่าอีกฝั่งต้องตามอะไรบ้าง | ถามตรง ๆ ในแชท (orchestrator เรียก `impact-analyst` ให้) |
| UI ที่มีอยู่ใช้งานยาก อยากรู้ว่าต้องแก้อะไร | บอกตรง ๆ พร้อมระบุหน้า (orchestrator เรียก `ux` โหมด AUDIT ให้) วาง screenshot ไว้ที่ `docs/ux/screens/` จะได้ผลแม่นขึ้น |
| สั่งให้ทำ task ทั้งหมด | `run BUILD` หลังผ่าน GATE 1 |
| เลือกว่าจะแก้อะไรบ้างหลังทดสอบ | ตอบ id ที่ GATE 2 เช่น `fix F-01, F-03` |

**งานเล็กทำทั้งก้อน งานใหญ่ทำทีละส่วน** — `sa` ประเมินขนาดก่อนเสมอ
- **ไม่ใหญ่** (ประมาณ ≤ 30 AC และ ≤ 5 หน้าจอ): `sa` เขียน requirements + design ใน call เดียว, `ux` เขียน flow และ spec หน้าจอ (เฉพาะงานที่มี UI), `tech-lead-plan` แตก task แล้วคุณอนุมัติรวดเดียวที่ GATE 1 ซึ่งเป็น gate เดียวก่อนเขียนโค้ด
- **ใหญ่**: `sa` เขียนแค่ **outline 1-2 หน้า** (แบ่งเป็นกี่ส่วน, ลำดับ, การตัดสินใจร่วมที่ทุกส่วนต้องใช้) ไม่มี AC และไม่มี design แล้วหยุดให้คุณอนุมัติ หลังจากนั้น **แต่ละส่วนวิ่ง cycle เต็มของตัวเอง** (spec → ux → plan → build → ทดสอบ → แก้ → ship) ส่วนถัดไปจะเริ่ม spec ก็ต่อเมื่อส่วนก่อนหน้าเสร็จแล้ว โดยดูจากโค้ดที่สร้างขึ้นจริง ไม่ต้องเสียเวลาวางแผนทั้งระบบก่อนได้ลงมือ และเปลี่ยนลำดับหรือหยุดได้ทุกครั้งที่จบแต่ละส่วน

ระหว่าง BUILD ถ้า developer เจอว่าแผนขาดอะไร จะรายงาน `GAP:` แล้วแก้เฉพาะจุดนั้น (AMEND/PATCH) **ไม่วางแผนใหม่ทั้งชุด** ถ้าเป็น gap เล็กครั้งแรกจะแก้แล้วทำต่อเอง ถ้าใหญ่กว่านั้นจะหยุดถามคุณ

BUILD เสร็จ → ทดสอบรอบเดียว (review, qa, ux audit, security) → หยุดให้คุณเลือกว่าจะแก้ตัวไหน → แก้ทีเดียวทั้งชุด → retest รอบเดียวแล้วจบ ไม่มีการวน review↔qa เองอีก ถ้า retest ยัง fail มันจะรายงานแล้วหยุด รอคุณสั่ง

**ให้งานออกมาเหมือนคนทำ**: ใส่ตัวอย่างงานดีที่สุดของทีม (เอกสาร, หน้าจอ, โค้ด) ไว้ใน `.agent/references/` หรือระบุ path ในหัวข้อ "Reference work" ของ `.agent/project.md` แล้วรัน `/agent-team:init` ให้สรุปภาษาและสไตล์ของทีมลงหัวข้อ "Voice and style" agent จะเลียนแบบจากตัวอย่างเหล่านี้แทนการเขียนแบบ template

**มาตรฐานที่อ้างอิง**: agent แต่ละตัวผูกกับมาตรฐานที่เป็นที่ยอมรับ (ISO/IEC/IEEE 29148, ISO 9241-11, Nielsen, WCAG 2.2 AA, INVEST, OWASP Top 10, ISTQB, Google code review) และนำแนวปฏิบัติจาก plugin ทางการของ Anthropic มาใช้ รายละเอียด จุดที่ตั้งใจทำต่าง และข้อจำกัดที่ยังมีอยู่ ดูที่ `STANDARDS.md` ทุกครั้งที่แก้ปลั๊กอินให้รัน `python3 -I scripts/check-plugin.py` และต้องได้ 0 error

**คลัง skill (`library/`)**: ปลั๊กอินมี skill จากชุด claude-skills ของ OneWave AI 51 ตัวติดมาด้วย เช่น เขียน runbook, proposal, SOW, ระบบตัวอักษรและสี, dark mode, accessibility, ออกแบบฐานข้อมูล, รับมือ incident, ทดสอบโหลด ทุกครั้งที่เปิด session ปลั๊กอินจะ copy คลังนี้ไปไว้ที่ `.agent/library/` ในโปรเจกต์ (ไม่ถูก commit) agent แต่ละตัวจะเปิดอ่านเฉพาะ skill ที่ตรงกับงานที่ทำอยู่ โดยถือว่าเป็นคำแนะนำ ถ้าขัดกับ `project.md`, `DESIGN.md` หรือกฎของ agent เอง ให้ทำตามสามอย่างนั้น

**คำเตือนเดียวที่สำคัญที่สุด**: ทุกคำตัดสินที่ตอบในแชท ต้องถูกเขียนลง `.agent/project.md` หัวข้อ "Decisions made" ด้วย — subagent รอบถัดไปเริ่มด้วย context เปล่า มันไม่เห็นแชท
