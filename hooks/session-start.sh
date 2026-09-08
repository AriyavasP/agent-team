#!/usr/bin/env bash
# agent-team plugin — SessionStart hook
# 1) scaffold .agent/ and docs/ in the target project if missing (never overwrites)
# 2) print orchestrator.md to stdout so Claude Code injects it into context
set -euo pipefail

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p .agent docs/features docs/fixes docs/impact

if [ ! -f .agent/project.md ]; then
  cat > .agent/project.md <<'PROJEOF'
# Project context

> Humans maintain this file. **Every agent reads it on every call.**
> Not filled in yet → run skill `agent-team:init`: it mines the code and asks only what it cannot mine.
> A blank reads as "no constraint" — if you do not know yet, write `not decided yet — agents must return NEEDS-PM if they hit this`

## Stack
- Language / runtime:
- Frontend:
- Backend:
- Database:
- ORM / query layer:
- Test runner:
- Package manager:

## Common commands
> Every command here must have been run and passed — not copied from the README
```bash
# dev:
# build:
# test (whole suite):
# test (single file):      ← developer uses this on every task; without it, it runs the full suite every time
# lint:
# typecheck:
# migrate:
```

## Project conventions
- Folder layout:
- Architecture layers (bottom to top):
- Error handling:
- Input validation:
- Naming (files / classes / functions / env vars / tables):
- **Reference files to copy the shape from** (the most important part of this section — developer opens these):
  - backend service:
  - API/controller:
  - frontend component:
  - test:

## Git
- Branch convention:
- Commit convention:
- One branch per task?

## Constraints that must not be broken
> At least one entry. If you cannot think of any, you have not asked enough.
- (e.g. no new dependencies without asking / do not touch module X / must support browser Y / never call external systems in dev)

## Business rules newcomers get wrong
> An agent is a newcomer on every call
-

## Decisions made
> Every time an agent returns NEEDS-PM and you choose, record it here.
> **Chat answers do not count** — the next agent starts with empty context and cannot see the chat.

| date | topic | decision | reason |
|------|-------|----------|--------|
PROJEOF
fi

if [ ! -f .agent/state.md ]; then
  cat > .agent/state.md <<'STATEEOF'
feature: -
phase: REQ
gate: open
current_task: -

## Task board
| id | status | review rounds | note |
|----|--------|---------------|------|

<!--
Owned by the orchestrator (main session) only — subagents must not write here.
Keeps two writers from clobbering each other and keeps status in one place, not synced with 03-tasks.md.

feature: <slug> — matches docs/features/<slug>/
phase:   REQ | DESIGN | PLAN | BUILD | VERIFY | SHIP
gate:    open = keep working | awaiting-pm = stopped for human approval
status:  todo | in-progress | in-review | blocked | verified | done
review rounds: counted to enforce the 3-round rule before returning NEEDS-PM
-->
STATEEOF
fi

[ -f docs/features/.gitkeep ] || echo "Per-feature artifacts — docs/features/<slug>/01..04 + reviews/" > docs/features/.gitkeep
[ -f docs/fixes/.gitkeep ] || echo "Fast-lane work — docs/fixes/<YYYY-MM-DD>-<slug>.md (see skill agent-team:fast-lane)" > docs/fixes/.gitkeep
[ -f docs/impact/.gitkeep ] || echo "Investigation notes (impact-scan) — records, not gated artifacts" > docs/impact/.gitkeep

cat "$HOOK_DIR/orchestrator.md"
