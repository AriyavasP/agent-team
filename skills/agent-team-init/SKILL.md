---
name: agent-team-init
description: Interview the human to fill in .agent/project.md before the agent team's first run. Use when project.md still has empty fields, or right after installing agent-team in a new project.
---

# Agent Team Init

`.agent/project.md` has the highest return per minute spent in this whole system: **every agent reads it on every call.** If it is empty they invent conventions, and you get code that works but does not fit the project — debt more expensive than code that plainly breaks, because nobody sees it at review time.

## Method — mine the project first, ask only what you cannot mine

**Never ask a human for something you can read yourself.** In this order:

### 1. Read from files (all doable alone)

| Looking for | Source |
|---|---|
| package manager | lockfile: `pnpm-lock.yaml` / `package-lock.json` / `yarn.lock` / `bun.lockb` |
| dev/build/test/lint commands | `scripts` in `package.json` (or `Makefile`, `pyproject.toml`, `go.mod`) |
| test runner | devDependencies + config files (`vitest.config`, `jest.config`, `playwright.config`) |
| ORM / database | dependencies + `prisma/schema.prisma`, `*.entity.ts`, migration files |
| framework and version | dependencies |
| folder layout | `find src -maxdepth 2 -type d` |

### 2. Derive conventions from real code (never guess from the framework name)

Open 1-2 real files of each kind and summarize in short sentences, **naming the path of the reference file**:

- backend module/service shape — layering, dependency injection, where business logic lives
- error handling — thrown exceptions / result objects / a central filter
- input validation — DTO + decorators / schema validator / hand-written
- frontend component shape — file layout, state management, API calls
- naming: files, classes, functions, env vars, tables/columns

**The reference files matter more than the prose** — `developer` opens them to copy the shape. Pick the best-written file in the project, not the first one you find.

### 3. Ask the human — only what the code cannot tell you

Ask as one batch, not one at a time.

1. Any module that must not be touched, or that requires telling someone first?
2. Can dependencies be added freely, or does that need approval?
3. Constraints not visible in code (browsers to support, compliance rules, external systems not to call in dev)
4. Business rules newcomers get wrong (an agent is a newcomer on every call)
5. Branch / commit conventions

### 4. Write it back into `.agent/project.md`

Fill every field. Where there is genuinely no answer yet, write `not decided yet — agents must return NEEDS-PM if they hit this`. **Never leave a blank**, because a blank reads as "no constraint", which is not true.

## Before finishing

- [ ] Every command under "Common commands" **has actually been run and passed**, not copied from the README
- [ ] There is a command to run **a single test file**, not only the whole suite (developer uses it on every task; without it, it runs the full suite every time — slow and expensive)
- [ ] Every referenced example file **exists** — verify with `ls`
- [ ] At least one entry under "Constraints that must not be broken" (if you cannot think of one, you have not asked enough)
