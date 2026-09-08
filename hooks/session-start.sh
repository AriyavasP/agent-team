#!/usr/bin/env bash
# agent-team plugin — SessionStart hook
# 1) scaffold .agent/ และ docs/ ในโปรเจกต์เป้าหมายถ้ายังไม่มี (ไม่เคยเขียนทับของเดิม)
# 2) print orchestrator.md ออก stdout เพื่อให้ Claude Code inject เข้า context อัตโนมัติ
set -euo pipefail

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p .agent docs/features docs/fixes docs/impact

if [ ! -f .agent/project.md ]; then
  cat > .agent/project.md <<'PROJEOF'
# บริบทโปรเจกต์

> ไฟล์นี้มนุษย์เป็นคนดูแล **agent ทุกตัวอ่านไฟล์นี้ทุกครั้งที่ถูกเรียก**
> ยังไม่ได้กรอก → เรียก skill `agent-team-init` ให้ช่วยขุดจากโค้ดแล้วถามเฉพาะที่ขุดไม่ได้
> ช่องว่างอ่านเหมือน "ไม่มีข้อจำกัด" — ถ้ายังไม่รู้คำตอบให้เขียนว่า `ยังไม่กำหนด — agent ต้องคืน NEEDS-PM ถ้าเจอ`

## Stack
- ภาษา / runtime:
- Frontend:
- Backend:
- Database:
- ORM / query layer:
- Test runner:
- Package manager:

## คำสั่งที่ใช้บ่อย
> ทุกคำสั่งต้องเคยรันจริงแล้วผ่าน ไม่ใช่คัดลอกมาจาก README
```bash
# dev:
# build:
# test (ทั้ง suite):
# test (ไฟล์เดียว):        ← developer ใช้ตัวนี้ทุก task ถ้าไม่มี มันจะรันทั้ง suite ทุกครั้ง
# lint:
# typecheck:
# migrate:
```

## Convention ของโปรเจกต์
- โครงโฟลเดอร์:
- ชั้นของสถาปัตยกรรม (เรียงจากล่างขึ้นบน):
- วิธี handle error:
- วิธี validate input:
- naming (ไฟล์ / class / function / env / table):
- **ไฟล์ตัวอย่างที่ควรใช้เป็นแบบ** (สำคัญที่สุดในหัวข้อนี้ — developer จะเปิดไปลอกโครง):
  - backend service:
  - API/controller:
  - frontend component:
  - test:

## Git
- branch convention:
- commit convention:
- ต้องแตก branch ต่อ task ไหม:

## ข้อจำกัดที่ห้ามละเมิด
> ต้องมีอย่างน้อย 1 ข้อ ถ้านึกไม่ออกเลยแปลว่ายังถามไม่พอ
- (เช่น ห้ามเพิ่ม dependency ใหม่โดยไม่ถาม / ห้ามแตะ module X / ต้องรองรับ browser Y / ห้ามยิงระบบภายนอกตอน dev)

## กฎทางธุรกิจที่คนใหม่มักทำผิด
> agent คือคนใหม่ทุกครั้งที่ถูกเรียก
-

## คำตัดสินที่ทำไปแล้ว
> ทุกครั้งที่ agent คืน NEEDS-PM แล้วคุณเลือกแล้ว ต้องบันทึกลงที่นี่
> **อย่าตอบแค่ในแชท** agent ตัวถัดไปเริ่มด้วย context เปล่า มันไม่เห็นแชท

| วันที่ | เรื่อง | ตัดสินว่า | เหตุผล |
|--------|--------|-----------|--------|
PROJEOF
fi

if [ ! -f .agent/state.md ]; then
  cat > .agent/state.md <<'STATEEOF'
feature: -
phase: REQ
gate: open
current_task: -

## Task board
| id | status | รอบ review | note |
|----|--------|-----------|------|

<!--
เจ้าของไฟล์นี้คือ orchestrator (session หลัก) เท่านั้น — subagent ห้ามเขียน
เพื่อไม่ให้สองตัวเขียนทับกัน และเพื่อให้ status อยู่ที่เดียวไม่ต้อง sync กับ 03-tasks.md

feature: <slug> — ตรงกับโฟลเดอร์ docs/features/<slug>/
phase:   REQ | DESIGN | PLAN | BUILD | VERIFY | SHIP
gate:    open = ทำงานต่อได้ | awaiting-pm = หยุดรอมนุษย์อนุมัติ
status:  todo | in-progress | in-review | blocked | verified | done
รอบ review: นับเพื่อบังคับกฎ 3 รอบแล้วต้องคืน NEEDS-PM
-->
STATEEOF
fi

[ -f docs/features/.gitkeep ] || echo "โฟลเดอร์นี้เก็บ artifact ของแต่ละฟีเจอร์ — docs/features/<slug>/01..04 + reviews/" > docs/features/.gitkeep
[ -f docs/fixes/.gitkeep ] || echo "โฟลเดอร์นี้เก็บงานเลนด่วน — docs/fixes/<YYYY-MM-DD>-<slug>.md (ดู skill fast-lane)" > docs/fixes/.gitkeep
[ -f docs/impact/.gitkeep ] || echo "โฟลเดอร์นี้เก็บบันทึกการสำรวจ (impact-scan) — เป็น record อ้างอิง ไม่ใช่ artifact ที่ผ่าน gate" > docs/impact/.gitkeep

cat "$HOOK_DIR/orchestrator.md"
