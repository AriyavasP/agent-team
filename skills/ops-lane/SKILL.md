---
name: ops-lane
description: Route for operations work outside a feature - a production incident or outage and its post-mortem, a database moving between providers, a container that will not build or start, environment and configuration setup. Runs devops in COLLECT (evidence from logs and git on a small model), DIAGNOSE (severity, cause chain, remediation) or PLAN mode, then stops for the human. No agent runs a command against a real system.
---

# Ops Lane

Operations work carries the highest cost of a wrong call and the least room for an agent to act: production belongs to the human. This lane gathers the evidence cheaply, spends the stronger model on judging it, and leaves every command against a real system to the human.

## When — and when not

- An incident: "orders fail since this morning's deploy", "the site is down", or a post-mortem after one
- A database moving between providers; a container that will not build or start; environment variables and configuration
- Not this lane: a bug whose location is known (`fast-lane`); new infra inside a feature (the full pipe — `devops` takes those tasks in BUILD); "check what X affects" (`impact-scan`)

## 1. Scope — one batch, each question with a default

- What is wrong, for whom, since when (default: since the last deploy in `git log`)
- What changed recently (default: the last day of `git log`)
- Where the logs are — ask the human to paste them or save them under `docs/ops/<slug>/logs/` (default: logs inside the repo only, and the report says production logs were not seen)
- Environment: production, staging or local (default: production for an incident)

**An active incident with users affected:** ask once, then proceed on the defaults at once — speed matters more than a complete brief.

Pick a kebab-case `<slug>`. Record `ops: <slug>` and `phase: OPS` in `.agent/state.md`. Before any log lands in the project, write `docs/ops/<slug>/logs/.gitignore` containing `*`: production logs can hold personal data and must never be committed.

## 2a. Incident — COLLECT on a small model, then DIAGNOSE

```
devops — COLLECT mode (pass model: haiku):
  COLLECT mode — <slug>: <symptom, since when, who is affected>
  Sources: docs/ops/<slug>/logs/, <log paths in the repo>, git log since <time>
  Write docs/ops/<slug>/evidence.md

devops — DIAGNOSE mode (default model):
  DIAGNOSE mode — <slug>: read docs/ops/<slug>/evidence.md
  Write docs/ops/<slug>/incident-report.md
```

Run them back to back. If DIAGNOSE returns `NEEDS-PM` with a list of missing evidence: one more COLLECT with that list, then DIAGNOSE once more. Still not enough → report the list to the human; never a third round.

Then stop and set `gate: awaiting-pm`. Show the severity, the cause chain with the evidence for each link, and the remediation with any command for the human to run. A code fix goes through `fast-lane`, quoting the file and function the report names; a configuration fix is a `devops` PLAN. After the incident is resolved, a post-mortem for readers outside the team is a `docs-lane` document with `incident-report.md` as its source.

## 2b. Migration, container or configuration — PLAN

```
devops — PLAN mode (default model):
  PLAN mode — <slug>: <the human's request, in full>
  Write docs/ops/<slug>/plan.md and its scripts — nothing executed
```

Stop and set `gate: awaiting-pm`: the human reviews the plan and runs it.

## Never

- Let an agent run a command against a real system — the guard blocks most of them; this rule covers the rest
- Ask an agent to read secrets, or paste secrets into a prompt
- Commit anything under `docs/ops/<slug>/logs/`
- Run COLLECT or DIAGNOSE a third time on your own
- Skip the gate because the fix looks obvious
