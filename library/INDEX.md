# Agent library

Skills from **OneWave AI, claude-skills** (MIT License, © 2025 OneWave AI — see `LICENSE`), copied unchanged. The SessionStart hook copies this folder into each project's `.agent/library/` every session, because subagents cannot read files outside the project (D-05 in `TESTING.md`).

A library skill is advice, not authority. `.agent/project.md`, the team's reference work, `docs/design/DESIGN.md` and the agent's own rules win over it. Its steps that ask the user, search the web, install tools or write outside the agent's write scope do not apply. Before reading a skill, read its row here: the last column says what in it to set aside.

To update: `python3 -I scripts/sync-library.py <path to a claude-skills clone>` re-copies every skill in the table below.

| skill | used by | use when | set aside in it |
|---|---|---|---|
| technical-writer | writer | README, tutorial, how-to, user guide, architecture doc, troubleshooting guide, release notes | — |
| api-documentation-writer | writer | API reference, OpenAPI spec | example data that is not from the project |
| runbook-generator | writer, devops | runbook, on-call or deployment guide | "500+ lines": length follows content; `[ACTION REQUIRED]` gaps go to the report as well |
| cowork-sop-writer | writer | SOP or process document | the gap interview: mark `[TO CONFIRM]` and report it |
| sow-generator | writer | statement of work | client web research; "no blanks": a missing commercial term is flagged, never filled in |
| client-proposal-generator | writer | proposal to a client | client web research; rate benchmarks: prices and rates come from the human only |
| cowork-rfp-response | writer | RFP or TOR response, compliance matrix | the bid/no-bid question goes to the human through the report |
| knowledge-base-builder | writer | FAQ or help-centre articles | its generic output frame; use the document type's shape |
| claude-md-writer | writer | CLAUDE.md or AGENTS.md for a repository | — |
| brand-voice-analyzer | writer | EDIT mode: checking a draft against a written voice; mining a voice from the team's documents | web collection; its corpus comes from the paths given |
| typography-scale-builder | ui-designer | the type scale and type roles | its 13-14px body for dense UI does not apply to Thai text (a step larger, line-height ≥ 1.5) |
| font-pairing-suggester | ui-designer | choosing typefaces | its generic output frame; Thai needs a face with designed Thai glyphs |
| color-palette-extractor | ui-designer | a palette from a brand image, logo or site; ramps and contrast | — |
| claude-design-system-architect | ui-designer | a whole token system with component specs | its house defaults (no purple, warm earth tones, dark surface): the direction comes from the product |
| design-system-generator | ui-designer | token files and base components for a codebase without them | its React / Tailwind / `cn` code where the project uses something else |
| motion-language-designer | ui-designer | motion tokens and rules | Framer Motion output where the project does not use it |
| css-animation-creator | ui-designer, developer | a specific animation or micro-interaction | anything that ignores `prefers-reduced-motion` |
| dark-mode-converter | ui-designer | a dark theme | — |
| design-tokens-sync | ui-designer | SYSTEM mode in a project with an existing token file: drift between tokens and code | its edits: list the changes for a developer task |
| responsive-layout-builder | ui-designer, developer | page grid, breakpoints, container queries | Tailwind breakpoints where the project defines its own |
| claude-design-critic | ui-designer, ux | judging a sample or a public page for the made-by-a-template look, design and copy | its house defaults (no purple, editorial and premium as the goal): judge against the chosen direction |
| accessibility-auditor | ux | AUDIT: WCAG checklist, ARIA patterns, axe commands | WCAG 2.1: the plugin's floor is WCAG 2.2 AA |
| browser-test-loop | ux, qa | driving a real browser to check a UI | — (its rules are already in `qa` and `ux`) |
| customer-journey-mapper | ux | DESIGN for a customer journey across many touchpoints (sign-up, onboarding, renewal) | web research; its seven marketing stages where the feature covers fewer |
| fresh-library-docs | developer | calling a library API whose installed version you are not sure of | web search: read the installed source first, as it says |
| screenshot-to-code | developer | building a screen from a screenshot or mockup | its default stack: the project's stack and components win |
| react-component-generator | developer | a React component in a React project | its Tailwind / `cn` code where the project uses something else |
| error-boundary-creator | developer | error boundaries and fallback UI in a React project | a reporting service the project does not have |
| api-endpoint-scaffolder | developer | a new API endpoint | its frameworks and `zod` where the project validates another way |
| ai-coding-guardrails | developer | a checkpoint failed twice, or you are unsure you are guessing | — (its rules are already in `developer`) |
| database-schema-designer | sa | data model: tables, keys, constraints, indexes, migrations | its PostgreSQL default where the project uses another store |
| data-pipeline-builder | sa | an ETL / ELT feature | Airflow and its file layout where the project has its own |
| mcp-server-builder | sa | a feature that is an MCP server or adds tools for a model | — |
| grill-the-brief | sa, ba | open questions, each with a default | — (its rule is already in `sa` and `ba`) |
| database-migrator | devops | moving a database between providers | executing against production: plan and scripts only |
| incident-responder | devops | a production incident or its post-mortem | commands against production systems: read-only diagnosis; the guard blocks the rest |
| docker-debugger | devops | container build or runtime problems | `docker push` and pruning: ask first |
| env-setup-wizard | devops | environment variables and configuration | reading or writing real `.env` files: `.env.example` only (the guard blocks secrets) |
| api-load-tester | qa | load or performance test of an API | installing tools without approval; any target but the one the human named |
| test-coverage-improver | qa | after the AC tests: untested paths worth a test | coverage as a target: tests trace to ACs and risks |
| code-review-pro | tech-lead-review | security and correctness depth | — (its rules are already in `tech-lead-review`) |
| static-analysis-sweep | tech-lead-review | running installed scanners over the diff | — (its rule is already in the orchestrator's VERIFY step) |
| git-pr-reviewer | tech-lead-review | a general checklist for a diff | — |
| dependency-auditor | tech-lead-review | the diff adds or upgrades dependencies | `npm audit fix --force` and any automatic fix: report only |
| performance-profiler | tech-lead-review | a performance-sensitive diff | — |
| compliance-checker | tech-lead-review | the diff handles regulated data (PII, payments, health) | its frameworks are US / EU: name Thailand's PDPA where it applies, and leave legal calls to the human |
| security-pentest-planner | tech-lead-review | only when the human asks for a penetration test plan | OWASP Top 10 (2021): use OWASP Top 10:2025; planning only, never active testing |
| plan-in-files | orchestrator | reasoning behind the state board and resume check | — (already in `hooks/orchestrator.md`) |
| session-handoff | orchestrator | reasoning behind the stop note | — (already in `hooks/orchestrator.md`) |
| context-budget | orchestrator | keeping a long session's context lean | — |
| agent-eval-harness | maintainer | turning a defect into a permanent test case | — (already in `TESTING.md`) |
