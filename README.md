# Agent Team

A Claude Code plugin: a 7-role subagent dev team (BA, SA, Tech Lead x2, Developer, QA, DevOps) plus an orchestrator that sets itself up in every project — no files to copy.

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
  → sa (SPEC mode)  → 01-requirements.md + 02-design.md   ← one call, both files
  → tech-lead-plan  → 03-tasks.md
                    → [GATE 1: you approve all three together]   ← the only stop before code

  you say "run BUILD":

  1. IMPLEMENT   developer T-001 → T-002 → … straight through, no review or qa in between
                 (between tasks the orchestrator only runs the project's build/test command itself — no agent call)
  2. VERIFY      ONE pass over the whole feature, each of these exactly once:
                   tech-lead-review FEATURE mode → 05-review.md   (R-01, R-02, …)
                   qa CLOSE mode                 → 04-test-report.md (BUG-01, …)
                   /security-review over the branch
  3. TRIAGE      everything found is merged into one severity-ranked list F-01…
                 → [GATE 2: YOU pick which ids get fixed]  ← the run stops here
  4. FIX         one developer call fixes the whole batch → 06-fixes.md
                 qa RETEST mode: those ACs + full regression, once
                 → report and stop, pass or fail

  → /agent-team:retro → durable lines into .agent/project.md
                                            → [GATE 3: ship]
  → devops (when infra changes)
```

**Three gates, not five, and one of them is before code.** `ba` and `sa` used to be two opus calls with a gate each; `sa` in SPEC mode writes both artifacts in one call, surveying the codebase once instead of twice, and `tech-lead-plan` runs before the gate so you approve scope with its price tag attached. `ba` still exists for requirements-only work — it is simply not on the default path.

**Nothing in BUILD repeats itself.** Review, qa and `/security-review` run once each; a fix batch is one call plus one retest; a retest that still fails is reported to you, never retried on the agents' own judgement. The old per-task `developer → review(≤3) → qa(≤2)` loop could spend ~11 agent calls (several of them opus) on a single task and ping-pong between review and qa; this spends **N + 5** for the whole feature.

At a gate, type `/agent-team:pm-gate` for that gate's checklist.

**Small work and bug fixes**: `/agent-team:fast-lane` — no full pipe.
**After shipping a feature**: `/agent-team:retro` — moves what the reviews and the test report taught you into `.agent/project.md`, under a line budget.
**Investigation questions** ("check what X must integrate after Y changed"): just ask; the orchestrator calls `sa` in SCAN mode (hard rule 6 in `hooks/orchestrator.md`).

## Roles and models

| agent | model | writes |
|---|---|---|
| `sa` | opus | `01-requirements.md` + `02-design.md` (SPEC mode) / a chat report (SCAN mode) |
| `ba` | opus | `01-requirements.md` — optional, off the default path |
| `tech-lead-plan` | sonnet | `03-tasks.md` |
| `developer` | sonnet (opus when `complexity: high`, or a fix batch with a blocker) | `src/**`, `tests/**` |
| `tech-lead-review` | opus | `05-review.md` (one pass per feature, not per task) |
| `qa` | sonnet | `tests/**`, `04-test-report.md` |
| `devops` | sonnet | `Dockerfile`, `.github/**`, `k8s/**`, `*.tf` — owns BUILD tasks whose files are infra |

## Safety

Two layers run in every project where the plugin is enabled:

1. **Pattern guards** (`hooks/hooks.json`) — `PreToolUse` hooks with `if:` rules blocking `terraform apply`, `kubectl apply`, `docker push`, `npm publish`, `aws`/`gcloud`/`az`, `ssh`, `git push`, `rm -rf`, and `Read` of `.env` / `*.pem` / `id_rsa*`.
2. **A command inspector** (`hooks/guard-bash.sh`) — runs on every Bash call and reads the actual command, catching what a pattern cannot: flag reordering (`rm -fr`, `rm -r -f`), a global option before the subcommand (`git -C dir push`), and any shell command touching a secret file (`cat .env`, `grep SECRET .env`, `head ~/.ssh/id_rsa`), which the `Read` guard never sees. `.env.example` / `.sample` / `.template` / `.dist` stay readable.

**These are guard rails against accidents, not a security boundary.** A creative invocation can still get around them — a script that reads the file, an alias, an unusual encoding. Anything where that matters belongs behind Claude Code's own [permission modes](https://code.claude.com/docs/en/permission-modes) and sandboxing, and secrets should not sit in a working tree an agent can reach.

**Verified against Claude Code CLI**: `claude plugin validate` passes for both manifests; the SessionStart hook injects the orchestrator and scaffolds the project (re-run on 2.1.0, including that it never overwrites an existing `.agent/state.md`). The guard was re-tested on 2.1.0 by feeding `hooks/guard-bash.sh` real payloads: `git push`, `git -C /tmp push`, `cat .env`, `grep SECRET .env.local`, `rm -fr`, `rm -r -f`, `head ~/.ssh/id_rsa` and `git clean -fd` are refused, while `git status`, `git log`, `cat .env.example`, `rm file.txt` and `pnpm test` pass through. The `Read(.env)` deny rule was verified through the CLI on 1.3.0 and has not changed since.

**Not verified**: no feature has been run end to end through the 2.x pipeline in a real project — the checks above are structural.

To enforce the same list through settings instead of hooks, add this to the project's `.claude/settings.json`:

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
- **Plugin skills and agents are namespaced.** Skills are always invoked as `/agent-team:<name>` (`/agent-team:pm-gate`, never `/pm-gate`), and agents appear to the Agent tool as `agent-team:sa`, `agent-team:developer`, and so on. The orchestrator instructions account for this.
- `.agent/state.md` belongs to the orchestrator alone; subagents never write it. It carries a task board and a **findings board** — the triage list plus your fix / wont-fix decision on each row.
- **Verification is batched, not incremental, and that is a trade-off.** Reviewing every task as it lands catches a bad pattern before four more tasks copy it; reviewing once at the end costs one opus pass instead of N and puts a human in the loop while the findings are still cheap to act on. The cheap guard against the trade-off is the checkpoint command run between tasks, so `.agent/project.md` → "Common commands" is worth filling in properly.
- No agent reads a whole artifact — they use `sed -n` / `grep -n` on the range they need. So `02-design.md` must keep section numbers 1-7, and `03-tasks.md` must always quote its ACs inline.
- **Token cost**: instructions, artifacts and reports are English by design. The orchestrator block is injected on every session, so its size is paid every time. The same applies to `.agent/project.md`, which every agent reads on every call — `/agent-team:retro` keeps it under a ~200 line budget by merging rules rather than appending them.
- **Security is spread across the roles, not delegated to one.** `sa` forces role/permission ACs in part A and writes a threat model in part B (design section 8), `tech-lead-plan` marks auth/money/PII tasks `high` so they run on opus, `tech-lead-review` runs a security pass on every diff, `qa` always tests unauthenticated and wrong-role calls, and fast lane refuses this class of work outright. Before ship, `/security-review` looks at the feature as a whole — the one thing per-task review cannot do.

## Signs the system is failing

| Symptom | Real cause is usually | Fix it in |
|---|---|---|
| the same finding comes back after a fix batch | unclear design, not a weak developer | `02-design.md` |
| the triage list is 20 rows, mostly `minor` | conventions too vague to code against | `project.md` |
| `qa` FAILs because an AC reads several ways | ambiguous AC waved through at GATE 1 | `01-requirements.md` |
| developer keeps returning BLOCKED for files outside its list | tasks split along the wrong boundaries | `03-tasks.md` |
| code is correct but does not fit the project | `.agent/project.md` is not detailed enough | `project.md` |

**Almost every time, the problem is in an artifact, not in an agent's prompt** — fix the content in the agent file (the single source of templates now that subagents read no external skills).

## Developing this plugin

```
plugin.json            version + metadata
marketplace.json       makes this repo its own marketplace (self-hosting)
agents/*.md            7 subagents — each self-contained
skills/*/SKILL.md      only the ones the orchestrator or a human invokes
hooks/hooks.json       SessionStart (inject + scaffold) + PreToolUse (guard)
hooks/orchestrator.md  the injected content — edit here instead of a CLAUDE.md
hooks/session-start.sh scaffolds the target project, then cats orchestrator.md
hooks/guard-bash.sh     inspects every Bash command for the cases patterns miss
```

After changing anything, bump `version` in `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json` before pushing, then have users run `/plugin marketplace update agent-team-marketplace`.

---

## หมายเหตุภาษาไทย

Plugin นี้ใช้ **ภาษาอังกฤษทั้งระบบ** ทั้ง instruction ของ agent, artifact (`01-requirements.md` ฯลฯ) และรายงานที่ agent ตอบกลับ — เพราะภาษาไทย 1 คำกินประมาณ 3-5 token ส่วนภาษาอังกฤษประมาณ 1-1.5 และ `hooks/orchestrator.md` ถูก inject เข้า context **ทุก session** จึงจ่ายค่านี้ซ้ำทุกครั้ง

คุยกับ orchestrator เป็นภาษาไทยได้ตามปกติ — มันจะตอบและเขียนไฟล์เป็นอังกฤษให้เอง ถ้าอยากได้สรุปไทยท้ายงาน สั่งได้ในแชทเป็นครั้ง ๆ ไป

สรุปการใช้งานสั้น ๆ:

| อยากทำอะไร | พิมพ์ |
|---|---|
| เริ่มใช้ในโปรเจกต์ใหม่ | `/agent-team:init` |
| สร้างฟีเจอร์ใหม่ | บอกโจทย์ตรง ๆ แล้วอนุมัติที่ GATE 1 ครั้งเดียว |
| ตรวจก่อนอนุมัติแต่ละ gate (มี 3 gate) | `/agent-team:pm-gate` |
| แก้บั๊ก/งานเล็ก (≤2 ไฟล์) | `/agent-team:fast-lane` |
| เก็บบทเรียนหลังปิดฟีเจอร์ | `/agent-team:retro` |
| ถามว่าอีกฝั่งต้องตามอะไรบ้าง | ถามตรง ๆ ในแชท (orchestrator เรียก `sa` โหมด SCAN ให้) |
| สั่งให้ทำ task ทั้งหมดรวดเดียว | `run BUILD` หลังผ่าน GATE 1 |
| เลือกว่าจะแก้อะไรบ้างหลังทดสอบ | ตอบ id ที่ GATE 2 เช่น `fix F-01, F-03` |

ก่อนถึงโค้ดมี **gate เดียว** — `sa` เขียน requirements + design ใน call เดียว แล้ว `tech-lead-plan` แตก task ต่อทันที คุณอ่านทั้ง 3 ไฟล์รวดเดียวแล้วอนุมัติที่ GATE 1

BUILD ทำงานแบบ **ทำทุก task รวดเดียว → ทดสอบรอบเดียว → หยุดให้คุณเลือกว่าจะแก้ตัวไหน → แก้ทีเดียวทั้งชุด → retest รอบเดียวแล้วจบ** ไม่มีการวน review↔qa เองอีก ถ้า retest ยัง fail มันจะรายงานแล้วหยุด รอคุณสั่ง

**คำเตือนเดียวที่สำคัญที่สุด**: ทุกคำตัดสินที่ตอบในแชท ต้องถูกเขียนลง `.agent/project.md` หัวข้อ "Decisions made" ด้วย — subagent รอบถัดไปเริ่มด้วย context เปล่า มันไม่เห็นแชท
