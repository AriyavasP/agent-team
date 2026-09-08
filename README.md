# Agent Team

Claude Code plugin — ทีมพัฒนาแบบ subagent 7 บทบาท (BA, SA, Tech Lead x2, Developer, QA, DevOps) พร้อม orchestrator ที่ setup ให้ทุกโปรเจกต์อัตโนมัติ ไม่ต้อง copy ไฟล์เอง

## ติดตั้ง

```
/plugin marketplace add AriyavasP/agent-team
/plugin install agent-team@agent-team-marketplace
```

หรือแบบ local (ทดสอบก่อน publish):

```
/plugin marketplace add /path/to/agent-team
/plugin install agent-team@agent-team-marketplace
```

เปิดใช้แล้ว **เปิดโปรเจกต์อะไรก็ได้** — session แรกที่เปิดในโปรเจกต์นั้น plugin จะ:
1. สร้าง `.agent/project.md`, `.agent/state.md`, `docs/features/`, `docs/fixes/`, `docs/impact/` ให้อัตโนมัติถ้ายังไม่มี (ไม่เขียนทับของเดิม)
2. inject orchestrator instructions เข้า context อัตโนมัติทุก session (ผ่าน `SessionStart` hook — แทนที่การต้อง copy `CLAUDE.md` เข้าโปรเจกต์)

ตรวจว่า enable สำเร็จด้วย `/plugin list`

## ก่อนเริ่มงานครั้งแรกในแต่ละโปรเจกต์

`.agent/project.md` ที่ hook สร้างให้เป็น template เปล่า — พิมพ์:

```
/agent-team-init
```

จะขุด stack/คำสั่ง/convention จากโค้ดจริง แล้วถามเฉพาะสิ่งที่ขุดไม่ได้ นี่คือไฟล์ที่ให้ผลตอบแทนสูงสุด — agent ทุกตัวอ่านมันทุกครั้งที่ถูกเรียก

## ลำดับการทำงาน

```
คุณเขียนโจทย์
  → ba              → 01-requirements.md  → [GATE 1: คุณอนุมัติ]
  → sa (DESIGN)      → 02-design.md        → [GATE 2: คุณอนุมัติ]
  → tech-lead-plan  → 03-tasks.md         → [GATE 3: คุณอนุมัติ]

  คุณสั่ง "รัน BUILD" → orchestrator วนเองจนจบทุก task:
    developer → tech-lead-review ──BLOCK(≤3)──┐
                    │ PASS                    │
                    qa ──────────FAIL(≤2)─────┘
                    │ PASS
                    └─→ task ถัดไป

  → qa โหมด CLOSE   → 04-test-report.md   → [GATE 4: ก่อน ship]
  → devops (เมื่อ infra เปลี่ยน)
```

ที่ gate ให้พิมพ์ `/pm-gate` มาอ่าน checklist

**งานเล็กและ bug fix**: `/fast-lane` — ไม่ต้องเดินท่อเต็ม
**คำถามสำรวจ** ("ดู X ว่าต้อง integrate อะไรเพิ่มจาก Y ที่อัพเดต"): พิมพ์ถามตรง ๆ orchestrator จะเรียก `sa` โหมด SCAN ให้เอง (ดูกฎเหล็กข้อ 6 ใน `hooks/orchestrator.md`)

## บทบาทและ model

| agent | model | เขียนไฟล์อะไร |
|---|---|---|
| `ba` | opus | `01-requirements.md` |
| `sa` | opus | `02-design.md` (โหมด DESIGN) / รายงานในแชท (โหมด SCAN) |
| `tech-lead-plan` | sonnet | `03-tasks.md` |
| `developer` | sonnet (opus ถ้า `complexity: high`) | `src/**`, `tests/**` |
| `tech-lead-review` | opus | `reviews/<T-ID>.md` |
| `qa` | sonnet | `tests/**`, `04-test-report.md` |
| `devops` | sonnet | `Dockerfile`, `.github/**`, `k8s/**`, `*.tf` |

## Safety

`hooks/hooks.json` มี `PreToolUse` hook block คำสั่งอันตราย (`terraform apply`, `kubectl apply`, `docker push`, `git push`, `rm -rf` ฯลฯ) และการอ่าน `.env`/`*.pem`/`id_rsa*` โดยอัตโนมัติทุกโปรเจกต์ที่ enable plugin นี้

**หมายเหตุความเชื่อมั่น**: กลไก hook นี้อ้างอิงจากเอกสาร Claude Code ล่าสุดเท่าที่ตรวจสอบได้ (`SessionStart` inject context, `PreToolUse` + `if` เพื่อ block) แต่ยังไม่ได้ validate ด้วย Claude CLI จริง (เครื่องที่ build plugin นี้ไม่มี CLI ติดตั้ง) — **ทดสอบก่อนใช้งานจริง**: เปิด session ในโปรเจกต์ทดสอบ แล้วลองสั่งให้รัน `git push` หรือ `terraform apply` ดูว่าถูก block จริงไหม

ถ้า hook ไม่ทำงานตามคาด ให้ใช้ fallback นี้แทน — เพิ่มลง `.claude/settings.json` ของโปรเจกต์ (กลไกนี้ยืนยันแล้วว่าทำงานจริง):

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

## ข้อควรรู้ทางเทคนิค / ข้อจำกัดที่ทราบ

- **CLAUDE.md ปกติ plugin inject ให้ไม่ได้** — ระบบนี้แก้ด้วย `SessionStart` hook ที่ print เนื้อหาเทียบเท่าออก stdout แทน (`hooks/orchestrator.md`) วิธีนี้ยืนยันจากเอกสารว่า Claude Code เติมข้อความจาก stdout ของ hook เข้า context จริง
- **agent ทุกตัวใน `agents/` self-contained** — ไม่มีตัวไหนพึ่งการ `Read` ไฟล์ skill อื่นในโปรเจกต์ เพราะ subagent ที่มาจาก plugin อาจ resolve path แบบ `.claude/skills/...` ในโปรเจกต์เป้าหมายไม่เจอ (skill อยู่ใน plugin package ไม่ใช่ในโปรเจกต์) เนื้อหาที่เคยแยกเป็น skill (req-spec, tech-design, task-breakdown, devops-infra) ถูก inline เข้าตัว agent แต่ละตัวแทน
- **skill ที่เหลือใน `skills/`** (`pm-gate`, `fast-lane`, `impact-scan`, `agent-team-init`) เป็นแบบที่ orchestrator/มนุษย์เรียกเองผ่าน Skill tool หรือ `/slash` — กลไกนี้ทำงานกับ main session อยู่แล้วโดยไม่ขึ้นกับ path
- **ชื่อ agent อาจปรากฏพร้อม prefix** เป็น `agent-team:ba` แทน `ba` เปล่า ๆ ขึ้นกับวิธี resolve ของ Claude Code — ถ้าเรียกด้วยชื่อเปล่าแล้วไม่เจอ ให้ลองใส่ prefix `agent-team:` (orchestrator instructions มีโน้ตเรื่องนี้ไว้แล้ว)
- `.agent/state.md` เป็นของ orchestrator ตัวเดียว subagent ห้ามเขียน
- ห้ามอ่าน artifact ทั้งไฟล์ — ทุก agent ถูกสั่งให้ `sed -n`/`grep -n` อ่านเฉพาะช่วงที่ต้องใช้ ดังนั้น `02-design.md` ต้องคงเลขหัวข้อ 1-7 และ `03-tasks.md` ต้องยกข้อความ AC มาไว้ในตัว task เสมอ

## สัญญาณว่าระบบกำลังพัง

| อาการ | สาเหตุที่แท้จริงมักอยู่ที่ | ไปแก้ที่ |
|---|---|---|
| `tech-lead-review` BLOCK ซ้ำ 3 รอบใน task เดียว | design ไม่ชัด ไม่ใช่ developer ไม่เก่ง | `02-design.md` |
| `qa` FAIL เพราะ AC ตีความได้หลายแบบ | AC เขียนกำกวมตั้งแต่ gate 1 | `01-requirements.md` |
| developer คืน BLOCKED ว่าต้องแตะไฟล์นอกรายการบ่อย | task แตกผิดขอบเขต | `03-tasks.md` |
| โค้ดถูกแต่ไม่เข้ากับโปรเจกต์ | `.agent/project.md` ไม่ละเอียดพอ | `project.md` |

**เกือบทุกครั้งปัญหาอยู่ที่ artifact ไม่ใช่ที่พรอมป์ของ agent** — แก้ที่เนื้อหาในไฟล์ agent (ต้นทางเดียวของ template ตอนนี้ เพราะไม่มี skill แยกให้ subagent อ่านแล้ว) ไม่ใช่พึ่งการแก้ skill ภายนอก

## Dev / อัปเดต plugin นี้

```
plugin.json         version + metadata
marketplace.json    ทำให้ repo นี้เป็น marketplace ของตัวเอง (self-hosting)
agents/*.md          7 subagent — self-contained ทุกไฟล์
skills/*/SKILL.md    เฉพาะที่ orchestrator/มนุษย์เรียกเอง
hooks/hooks.json     SessionStart (inject + scaffold) + PreToolUse (guard)
hooks/orchestrator.md เนื้อหาที่ถูก inject — แก้ตรงนี้แทนการแก้ CLAUDE.md เดิม
hooks/session-start.sh สคริปต์ที่ scaffold โปรเจกต์เป้าหมาย + cat orchestrator.md
```

แก้แล้ว bump `version` ใน `.claude-plugin/plugin.json` และ `.claude-plugin/marketplace.json` ก่อน push แล้วให้ผู้ใช้ `/plugin marketplace update agent-team-marketplace`
