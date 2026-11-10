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
> **Keep this file under ~200 lines.** Every agent pays for it on every call, so merge overlapping rules and delete what is no longer true — this is not a log.

## Product profile
> Domain rules for this kind of product, from `.agent/profiles/` (see its `INDEX.md`). `agent-team:init` sets it. Write `none` if no profile fits.
- Profile:

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

## UI / UX
> `ux` reads this on every UI feature. Skip only if the project has no UI.
- Users and devices (who, desktop/mobile, minimum viewport):
- UI language:
- Date format (Buddhist / Gregorian era), time zone, currency and number format:
- Design tokens / component reference (paths):
- Command to render or screenshot pages (or "none"):

## Voice and style
> For everything an end user or client reads: UI copy and deliverable documents. `agent-team:init` mines it from your existing documents.
- Language and register (e.g. Thai, polite business tone, no `ท่าน` in staff tools):
- Glossary — one word per concept:
- Words and patterns to avoid:
- Document habits (heading depth, tables vs prose, numbering, how long a section runs):

## Reference work — what good looks like here
> The best human-made examples of each kind of output. Agents copy their structure, density and voice. Keep 2-3 per kind in `.agent/references/` or point at paths.
- Documents:
- Screens:
- Code: see "Reference files" above

## Git
- Branch convention:
- Commit convention:
- One branch per task?

## Constraints that must not be broken
> At least one entry. If you cannot think of any, you have not asked enough.
- (e.g. no new dependencies without asking / do not touch module X / must support browser Y / never call external systems in dev)
- Regulations: (set by `agent-team:init` — `none apply`, or: legal figures come only from `.agent/regulations.md`, as dated configuration data, never as literals; a missing or unverified row → NEEDS-PM)

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
phase: SPEC
gate: open
outline: -
part: -
base: -
current_task: -

## Task board
| id | status | note |
|----|--------|------|

## Findings board
> Filled at TRIAGE from 05-review.md + 04-test-report.md + 07-ux-audit.md + /security-review. The human picks which ids get fixed.
| id | severity | source | where | decision |
|----|----------|--------|-------|----------|

<!--
Owned by the orchestrator (main session) only - subagents must not write here.
Keeps two writers from clobbering each other and keeps status in one place, not synced with 03-tasks.md.

feature:  <slug> - matches docs/features/<slug>/ (a part of a large feature: <feature>/p0n-<name>)
phase:    SPEC | UX | PLAN | BUILD | VERIFY | TRIAGE | FIX | SHIP
gate:     open = keep working | awaiting-pm = stopped for human approval (outline gate, GATE 1-3, or an amendment)
outline:  docs/features/<feature>/00-outline.md when the work was split into parts, else -
part:     P-0n currently in progress, else -
base:     commit recorded when BUILD starts - VERIFY reviews the diff from here
status:   todo | in-progress | implemented | verified | blocked | done
          (no per-task review status: review and qa run once over the whole feature, in VERIFY)
decision: pending | fix | wont-fix - set by the human at TRIAGE (GATE 2), never by an agent
-->
STATEEOF
fi

# Copy the plugin's library into the project every session: subagents cannot read outside
# the project (D-05), and a fresh copy picks up plugin updates. Never committed.
LIB_DIR="$(cd "$HOOK_DIR/../library" 2>/dev/null && pwd || true)"
if [ -n "$LIB_DIR" ]; then
  mkdir -p .agent/library
  cp -R "$LIB_DIR/." .agent/library/ 2>/dev/null || echo "Note: could not copy the agent library into .agent/library/ - agents work without it this session."
  printf '*\n' > .agent/library/.gitignore
fi

# Product profiles (domain rules) and the stack guide travel the same way as the library.
PROF_DIR="$(cd "$HOOK_DIR/../profiles" 2>/dev/null && pwd || true)"
if [ -n "$PROF_DIR" ]; then
  mkdir -p .agent/profiles
  cp -R "$PROF_DIR/." .agent/profiles/ 2>/dev/null || echo "Note: could not copy the product profiles into .agent/profiles/ - agents work without them this session."
  printf '*\n' > .agent/profiles/.gitignore
fi

[ -f docs/features/.gitkeep ] || echo "Per-feature artifacts — docs/features/<slug>/00-outline (large work) .. 07-ux-audit" > docs/features/.gitkeep
[ -f docs/fixes/.gitkeep ] || echo "Fast-lane work — docs/fixes/<YYYY-MM-DD>-<slug>.md (see skill agent-team:fast-lane)" > docs/fixes/.gitkeep
[ -f docs/impact/.gitkeep ] || echo "Investigation notes (impact-scan) — records, not gated artifacts" > docs/impact/.gitkeep

cat "$HOOK_DIR/orchestrator.md"

# Tax and data-protection rules change. A project that keeps .agent/regulations.md is told to
# re-check it when the plugin version changed since the last check, or its next-check date passed.
# Printed only when due, so a project with nothing to check pays nothing.
REG=.agent/regulations.md
if [ -f "$REG" ]; then
  PLUGIN_VERSION="$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$HOOK_DIR/../.claude-plugin/plugin.json" 2>/dev/null | head -n 1)"
  SEEN="$(sed -n 's/^plugin-version:[[:space:]]*\([^[:space:]]*\).*/\1/p' "$REG" | head -n 1)"
  NEXT="$(sed -n 's/^next-check:[[:space:]]*\([0-9-]*\).*/\1/p' "$REG" | head -n 1)"
  TODAY="$(date +%Y-%m-%d)"
  DUE=""
  if [ -n "$PLUGIN_VERSION" ] && [ "$SEEN" != "$PLUGIN_VERSION" ]; then
    DUE="the agent-team plugin changed since the last check (${SEEN:-unknown} -> $PLUGIN_VERSION)"
  elif [ -z "$NEXT" ] || [ "$TODAY" \> "$NEXT" ]; then
    DUE="its next-check date (${NEXT:-missing}) has passed"
  fi
  if [ -n "$DUE" ]; then
    printf '\n<agent-team-notice>\nREGULATIONS CHECK DUE: .agent/regulations.md - %s. Tell the human now. Before any work that touches tax, payroll or personal data, run skill agent-team:init, its Regulations step only. Until then treat every row of that file as unverified.\n</agent-team-notice>\n' "$DUE"
  fi
fi
