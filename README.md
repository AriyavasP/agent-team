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
  → ba              → 01-requirements.md  → [GATE 1: you approve]
  → sa (DESIGN)     → 02-design.md        → [GATE 2: you approve]
  → tech-lead-plan  → 03-tasks.md         → [GATE 3: you approve]

  you say "run BUILD" → the orchestrator loops to the end on its own:
    developer → tech-lead-review ──BLOCK(≤3)──┐
                    │ PASS                    │
                    qa ──────────FAIL(≤2)─────┘
                    │ PASS
                    └─→ next task

  → qa in CLOSE mode → 04-test-report.md   → [GATE 4: before ship]
  → devops (when infra changes)
```

At a gate, type `/agent-team:pm-gate` for the checklist.

**Small work and bug fixes**: `/agent-team:fast-lane` — no full pipe.
**Investigation questions** ("check what X must integrate after Y changed"): just ask; the orchestrator calls `sa` in SCAN mode (hard rule 6 in `hooks/orchestrator.md`).

## Roles and models

| agent | model | writes |
|---|---|---|
| `ba` | opus | `01-requirements.md` |
| `sa` | opus | `02-design.md` (DESIGN mode) / a chat report (SCAN mode) |
| `tech-lead-plan` | sonnet | `03-tasks.md` |
| `developer` | sonnet (opus when `complexity: high`) | `src/**`, `tests/**` |
| `tech-lead-review` | opus | `reviews/<T-ID>.md` |
| `qa` | sonnet | `tests/**`, `04-test-report.md` |
| `devops` | sonnet | `Dockerfile`, `.github/**`, `k8s/**`, `*.tf` |

## Safety

Two layers run in every project where the plugin is enabled:

1. **Pattern guards** (`hooks/hooks.json`) — `PreToolUse` hooks with `if:` rules blocking `terraform apply`, `kubectl apply`, `docker push`, `npm publish`, `aws`/`gcloud`/`az`, `ssh`, `git push`, `rm -rf`, and `Read` of `.env` / `*.pem` / `id_rsa*`.
2. **A command inspector** (`hooks/guard-bash.sh`) — runs on every Bash call and reads the actual command, catching what a pattern cannot: flag reordering (`rm -fr`, `rm -r -f`), a global option before the subcommand (`git -C dir push`), and any shell command touching a secret file (`cat .env`, `grep SECRET .env`, `head ~/.ssh/id_rsa`), which the `Read` guard never sees. `.env.example` / `.sample` / `.template` / `.dist` stay readable.

**These are guard rails against accidents, not a security boundary.** A creative invocation can still get around them — a script that reads the file, an alias, an unusual encoding. Anything where that matters belongs behind Claude Code's own [permission modes](https://code.claude.com/docs/en/permission-modes) and sandboxing, and secrets should not sit in a working tree an agent can reach.

**Verified against Claude Code CLI** (`claude --plugin-dir`, September 2026): `claude plugin validate` passes for both manifests; the SessionStart hook injects the orchestrator and scaffolds the project; `git push` and `Read(.env)` are refused even when the tool is explicitly allowed; `cat .env`, `rm -fr`, and `git -C . push` are refused by the inspector, while `git status`, `rm file.txt` and `cat .env.example` pass through.

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
- **Every agent in `agents/` is self-contained** — none of them `Read` a skill file, because a plugin subagent may fail to resolve `.claude/skills/...` inside the target project (the skills live in the plugin package, not the project). Content that used to be separate skills (req-spec, tech-design, task-breakdown, devops-infra) is inlined into each agent.
- **Plugin skills and agents are namespaced.** Skills are always invoked as `/agent-team:<name>` (`/agent-team:pm-gate`, never `/pm-gate`), and agents appear to the Agent tool as `agent-team:ba`, `agent-team:sa`, and so on. The orchestrator instructions account for this.
- `.agent/state.md` belongs to the orchestrator alone; subagents never write it.
- No agent reads a whole artifact — they use `sed -n` / `grep -n` on the range they need. So `02-design.md` must keep section numbers 1-7, and `03-tasks.md` must always quote its ACs inline.
- **Token cost**: instructions, artifacts and reports are English by design. The orchestrator block is injected on every session, so its size is paid every time.

## Signs the system is failing

| Symptom | Real cause is usually | Fix it in |
|---|---|---|
| `tech-lead-review` BLOCKs 3 rounds on one task | unclear design, not a weak developer | `02-design.md` |
| `qa` FAILs because an AC reads several ways | ambiguous AC written back at gate 1 | `01-requirements.md` |
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
| สร้างฟีเจอร์ใหม่ | บอกโจทย์ตรง ๆ แล้วอนุมัติทีละ gate |
| ตรวจก่อนอนุมัติแต่ละ gate | `/agent-team:pm-gate` |
| แก้บั๊ก/งานเล็ก (≤2 ไฟล์) | `/agent-team:fast-lane` |
| ถามว่าอีกฝั่งต้องตามอะไรบ้าง | ถามตรง ๆ ในแชท (orchestrator เรียก `sa` โหมด SCAN ให้) |
| สั่งให้ทำ task ทั้งหมดต่อเนื่อง | `run BUILD` หลังผ่าน GATE 3 |

**คำเตือนเดียวที่สำคัญที่สุด**: ทุกคำตัดสินที่ตอบในแชท ต้องถูกเขียนลง `.agent/project.md` หัวข้อ "Decisions made" ด้วย — subagent รอบถัดไปเริ่มด้วย context เปล่า มันไม่เห็นแชท
