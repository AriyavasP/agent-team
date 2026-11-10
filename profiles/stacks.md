# Choosing a stack for a project with no code yet

Read by `/agent-team:init` only when the project has no source to mine. A project that already has code keeps its stack: mine it, never propose a change here.

The proposal is one stack and one alternative, each with its reason. The human confirms; the choice goes into `.agent/project.md` → "Stack" and "Decisions made".

## What decides, in this order

1. **What the team already runs and can maintain.** Ask before proposing. A stack the team knows beats a better fit on paper.
2. **What it must connect to**: existing systems, a hosting platform, a client's requirement.
3. **The shape of the product**: the table below.
4. One backend language per project, and a modular monolith before separate services, unless a row below or the human gives a reason.

## Defaults by product shape

Languages considered: TypeScript on Node.js, Go, PHP, Python, Rust. PostgreSQL is the default database for every row that stores business data.

| product | default | why | take the alternative when |
|---|---|---|---|
| landing page, marketing site | a static site generator on Node.js (Astro), no backend; a form posts to one small function | fast pages, nothing to operate | content editors need a CMS → the CMS row |
| CMS, content site | adopt an existing CMS before building one; if built: PHP (Laravel) or TypeScript (Next.js with a headless CMS) | content modelling, media and roles are solved problems | the content model is the product itself → the back-office row |
| back office: CRM, HRM, ERP modules | a batteries-included framework: PHP (Laravel) or Python (Django) | forms, roles, migrations, queues, admin screens and reports are most of the work, and these ship them | the team is TypeScript-only → NestJS with a React or Vue front end |
| finance, ledger, billing | the same stack as the system it belongs to; standalone: Go or TypeScript (NestJS) | correctness lives in the database (transactions, constraints, exact numeric types), so the language matters less than PostgreSQL used strictly | heavy reporting or data science on the ledger → Python for that part only |
| e-commerce | a server-rendered storefront (Next.js or Nuxt) on a backend API (NestJS or Laravel) | product pages need SEO and fast first load; the catalogue and orders are back-office work | checkout or inventory under very high concurrency → Go for that service |
| POS | an offline-first client (a PWA with local storage) and a sync API (Go or NestJS) | a till must keep selling without a network; sync and conflict rules are the hard part | printers, cash drawers or scanners need native access → a Tauri (Rust) desktop client |
| integration gateway, high-throughput service | Go | concurrency, small deployments, simple operations | hard latency or memory limits → Rust |

## What each language costs

- **Rust**: the strongest guarantees, the slowest to build with and the hardest to hire for. Use it for a named need (device access, a hot path), never as the default for forms and reports.
- **Go**: plain and fast to run; few batteries, so CRUD screens and admin take more code than in Laravel or Django.
- **PHP, Python**: the fastest route to a working back office; watch typing discipline and background-job design as the system grows.
- **TypeScript on Node.js**: one language across front and back; choose a framework with structure (NestJS) for anything larger than a few endpoints.

## What is evidence here and what is judgement

Evidence (sources in the plugin's `research/enterprise-domains.md`):

- **Hiring pool**, Stack Overflow Developer Survey 2025, share of respondents using each: JavaScript 66%, Python 57.9%, TypeScript 43.6%, PHP 18.9%, Go 16.4%, Rust 14.8%. Frameworks: Node.js 48.7%, React 44.7%, Next.js 20.8%, Express 19.9%, Django 12.6%, Laravel 8.9%, NestJS 6.7%.
- **PostgreSQL as the default**: the most used database in the same survey, 55.6% against MySQL's 40.5%.
- **Monolith first**: Martin Fowler's observation that almost every successful microservice system began as a monolith. He calls the advice tentative.
- **Adopt a CMS before building one**: WordPress alone runs 39.3% of all websites (W3Techs, November 2026).
- **POS must work offline, with limits**: Shopify and Square both ship offline selling with a cap per transaction, and the merchant carries the loss on a card declined after reconnecting.
- **Landing pages are judged on mobile speed**: Core Web Vitals (LCP ≤ 2.5 s, INP ≤ 200 ms, CLS ≤ 0.1 at the 75th percentile); 83% of landing-page visits in Unbounce's 2024 data were on mobile.

Judgement: which framework suits which product in the table above. No source read compares them by domain. Say so when proposing, and note that NestJS has the smallest user base of the frameworks named.

## What init writes for a new project

- "Stack": the confirmed choice, with versions
- "Common commands": the stack's standard commands, each marked `planned — not run yet`. Run and confirm them after the first part builds the scaffold, then remove the mark
- "Decisions made": one row with the stack, the alternative rejected and the reason
