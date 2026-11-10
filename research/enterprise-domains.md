# Enterprise domains: what the evidence says

Collected 2026-11-10 to ground the product profiles (`profiles/`) and the stack guide (`profiles/stacks.md`) in sources instead of the maintainer's judgement. One pass of web research across eight kinds of product: business problem, what fails, design and engineering practice.

This file is for the maintainer and for whoever writes the next profile. It is not copied into projects and no agent reads it.

## How to read the grades

Every claim carries a grade. Use grade A and B claims as the basis for a profile rule. Treat grade C as a lead to verify, never as a figure to quote.

| grade | meaning |
|---|---|
| **A** | the primary source was opened and read in this pass |
| **B** | a primary source exists and was seen only through a search summary of it (the page refused a direct fetch) |
| **C** | secondary or vendor material; figures conflict or could not be traced to an original |

## Findings that hold across every domain

1. **Enterprise software projects fail on people, process and data far more often than on code.** Gartner predicts that by 2027 more than 70% of recently implemented ERP initiatives will fail to fully meet their original business case goals, and up to 25% will fail catastrophically; it names technology-centred approaches that ignore stakeholders as the cause (B). The CRM and HRIS material says the same thing with weaker numbers (C).
2. **Skipping the test of the whole system is how the worst documented failure happened.** Canada's Phoenix pay system went live with 30 of 111 approved functions removed, 20% of 81 reviewed functions failing their tests, no test of the system as a whole, and its pilot cancelled in June 2015 with no assessment of what cancelling it meant (B, Auditor General of Canada, 2018).
3. **Data migration and data quality are named as a top cause in ERP, CRM and HRIS alike** (C for the rates; consistent across every source read).
4. **Start as a monolith.** Fowler: "you shouldn't start a new project with microservices"; almost all the successful microservice stories he knows started as a monolith, and boundaries drawn at the start are usually wrong. He calls the evidence sparse and the advice tentative (A).
5. **Expert users of dense tools need different design from consumers.** NN/g's eight guidelines for complex applications: learning by doing, cues toward faster methods, flexible non-linear pathways, help tracking actions across interruptions, smooth movement between tools, less clutter without less capability, secondary information without leaving the screen, visual salience for what matters (A; expert synthesis, not a controlled study).

What this means for the plugin: the existing gates, the outline-then-parts rule and the end-to-end path `qa` must run are aimed at the right failures. Three things the evidence asks for that the plugin does not have yet: a data-migration rehearsal as a named step, a whole-system test before a multi-module release, and a check that removed or deferred scope is assessed rather than dropped quietly.

## Finance and ledgers

| claim | grade | source |
|---|---|---|
| Record every transaction as where the money came from and what it was used for; at least two entries per transaction | A | Modern Treasury, Accounting for Developers I |
| Store immutable transactions and compute balances from them; "mutating balances directly creates a system that is prone to errors"; balances can then be rebuilt as of any date | A | same |
| A ledger product's stated principles: double entry, immutability once posted, idempotency, concurrency control, an audit log naming the actor | B | Modern Treasury, Announcing Ledgers |
| An idempotency key makes a retry safe: the first result is saved and returned again, including an error; keys may be pruned after 24 hours; a repeat with different parameters is an error; keys must not contain personal data | A | Stripe API, Idempotent requests |
| Provider events arrive more than once and in no guaranteed order: record processed event ids, never depend on order, verify the signature against the raw body, reject old timestamps (5-minute default), return 2xx before doing the work, process from a queue | A | Stripe, Webhooks |
| Money is not a first-class type in mainstream languages; mixing currencies and losing the smallest unit to rounding are the standard defects a Money type exists to prevent | A | Fowler, Money pattern |
| Correct a wrong entry with a reversing entry; assign rounding remainders deterministically or the ledger drifts; freeze the exchange rate on the transaction | C | third-party engineering posts |

Effect on `profiles/finance.md`: rules 1-7, 11 and 14 are supported by A or B sources. Two gaps were found and fixed in this pass: a repeat that reuses a key with different parameters, and provider events arriving out of order or unsigned.

## ERP

| claim | grade | source |
|---|---|---|
| More than 70% of recent ERP initiatives will fail to fully meet their business case by 2027; up to 25% catastrophically; cause is behavioural, not technical | B | Gartner; The Register, 2025-11-13 |
| Phoenix: scope removed, tests failed, no whole-system test, pilot cancelled, executives proceeded knowing of significant problems, no oversight | B | Auditor General of Canada, 2018 Spring Report 1 |
| Specific failure and overrun percentages attributed to Panorama Consulting's 2025 report (68%, 71%, 65%, 30%) | C | conflicting secondary reports; the original was not reached |

Candidate rules for an `erp` profile (not written yet): each module's contract with the others is agreed before the first module is built; a function cut from scope is recorded with who loses what; no go-live without one run of the whole process across modules on migrated data; a pilot is cancelled only with a written assessment.

## CRM

The weakest evidence in this file: no primary study was reached.

| claim | grade | source |
|---|---|---|
| Low user adoption and poor data quality are the leading causes of CRM failure | C | vendor and consultancy summaries, consistent with each other |
| Sales reps spend about 28-30% of their week selling; the rest goes to administration and data entry | B | Salesforce State of Sales, seen through summaries; one 2026 summary says about 40% |

Candidate rules for a `crm` profile: every field a user must type is justified against what it is used for; duplicate detection on create and on import; an import is a feature with its own ACs (malformed rows, duplicates, partial failure); a step budget for the most frequent task, logging an interaction.

## HRM and payroll

| claim | grade | source |
|---|---|---|
| One in five US payrolls contains an error; average cost $291 per error; the average organisation makes 15 corrections per pay period (508 respondents, employers of 250 to 10,000) | A | EY survey as released by Paycom, 2022-12-22. The release is from a payroll vendor |
| The most frequent errors come from inputs, not the pay calculation: time, attendance and expenses (1,139 per 1,000 employees a year), then leave requests (721), benefits (503) | A | same |
| Payroll data conversion is routinely underestimated; scope should not grow before payroll and compliance are stable | B | Panorama Consulting, HRIS implementation |
| Thailand's PDPA section 26 treats health, biometric, criminal-record, union and similar data as sensitive, with explicit consent as the default and employment-law exceptions | C | law-firm summaries; the statute was not read, and they disagree on section numbers |

Candidate rules for an `hrm` profile: validate time, leave and expense inputs before they reach a pay run, and let the employee see their pay before it is final; a pay run is reproducible and a correction is a new adjustment, never an edit; payroll figures (rates, thresholds, contributions) are dated data from the human; sensitive employee data has its own access rule and its own audit trail.

## E-commerce

| claim | grade | source |
|---|---|---|
| Average documented cart abandonment is 70.22% across 50 studies | A | Baymard Institute |
| Reasons given for abandoning a checkout: extra costs too high 40%, delivery too slow 20%, did not trust the site with card details 19%, forced account creation 18%, checkout too long or complicated 17%, site errors or crashes 17%, could not see the total up front 12%, card declined 10%, too few payment methods 9% | A | same |
| The average US checkout shows 23.48 form elements; 12-14 is achievable. Baymard estimates a 35.26% conversion gain from fixing documented checkout problems | A | same |
| Payment confirmation arrives as provider events that can be duplicated, reordered or forged | A | Stripe, Webhooks |

Candidate rules for an `ecommerce` profile: guest checkout exists; the full total including shipping and tax is shown before the payment step; a count of form elements per checkout step is a UX criterion; an order is marked paid only by a verified provider event, handled idempotently; a declined card keeps the cart and offers another method. The finance profile applies to the order's money.

## POS

| claim | grade | source |
|---|---|---|
| Offline card payments are not sent to the processor until the device reconnects; a card can then be declined, and the merchant carries the loss | A | Shopify Help Center; Square Support |
| Both products cap the exposure: a per-transaction limit and (Shopify) a per-device daily limit | A | same |
| Offline payments expire: Square deletes pending payments after 72 hours, and signing out or reinstalling loses them permanently | A | Square Support |
| Card entry by hand, gift cards, tap-to-pay on a phone and loyalty accrual do not work offline | A | Shopify; Square |
| Stock: decrement locally at sale, replay the queue idempotently in order, surface oversells for review instead of overwriting | C | vendor pages |

Candidate rules for a `pos` profile: every screen states what works offline; each offline sale has a client-generated id and syncs idempotently; offline card acceptance has a configurable limit and a stated owner of the loss; pending sales survive app restart and sign-out, and their expiry is visible; a conflict on sync is shown to a person, never resolved silently.

## CMS

| claim | grade | source |
|---|---|---|
| WordPress runs 39.3% of all websites; Shopify 5.3%, Wix 4.2%, Squarespace 2.4%, Joomla 1.1%, Drupal 0.6% (2026-11-10) | A | W3Techs |
| Headless systems lose the built-in page preview and ask more of editors; give authors templates so nobody starts blank or copies whole pages | C | vendor comparisons; Rangle headless CMS playbook |

Effect on `profiles/stacks.md`: "adopt an existing CMS before building one" is supported by how the market actually behaves. Candidate rules for a `cms` profile: the content model is designed before any template; editors can preview before publishing; draft, review and publish are separate permissions; a published URL that changes leaves a redirect.

## Landing pages

| claim | grade | source |
|---|---|---|
| Core Web Vitals "good" thresholds: LCP ≤ 2.5 s, INP ≤ 200 ms, CLS ≤ 0.1, measured at the 75th percentile of page loads, mobile and desktop separately | A | web.dev |
| Median landing-page conversion is 6.6% across 41,000 pages and 464 million visitors | A | Unbounce Conversion Benchmark Report 2024 |
| Copy at a 5th-7th grade reading level converts at 11.1% against 5.3% for professional-level writing; difficult words, reading time and word count each correlate negatively with conversion. Financial services is an exception | A | same. Correlation in one vendor's customer base |
| 83% of visits were on mobile, and desktop still converted 8% better | A | same |
| Case studies linking better vitals to revenue (Vodafone, Rakuten 24, redBus) | C | secondary summaries; originals not opened |

Candidate rules for a `landing` profile: the three thresholds are non-functional ACs, measured on a mobile profile; one primary action per page; copy is tested for reading level in the page's language; the mobile layout is designed first.

## Stack choice

| claim | grade | source |
|---|---|---|
| Use among all respondents (31,771): JavaScript 66%, Python 57.9%, TypeScript 43.6%, PHP 18.9%, Go 16.4%, Rust 14.8% | A | Stack Overflow Developer Survey 2025 |
| Databases: PostgreSQL 55.6%, MySQL 40.5% | A | same |
| Web frameworks: Node.js 48.7%, React 44.7%, Next.js 20.8%, Express 19.9%, Django 12.6%, Laravel 8.9%, NestJS 6.7% | A | same |
| Begin with a monolith | A | Fowler, MonolithFirst |

What this supports in `profiles/stacks.md`: PostgreSQL as the default, the monolith-first rule, and the ordering of how hard each language is to hire for. What it does not support: which framework suits which product. That mapping remains judgement, and the survey shows NestJS, proposed as an alternative in several rows, has the smallest user base of the frameworks named.

## Not found in this pass

- Panorama Consulting's and Gartner's original reports (gated or refused)
- any primary study of CRM failure
- the text of Thailand's PDPA and any Thai tax or e-invoicing rule (profiles state none on purpose)
- independent engineering references for offline sync (CRDTs, event sourcing) beyond vendor pages
- evidence for or against any language being better suited to a domain

## Sources

Read directly (A):
- Baymard Institute, cart abandonment rate statistics: https://baymard.com/lists/cart-abandonment-rate
- web.dev, Web Vitals: https://web.dev/articles/vitals
- Stripe, Idempotent requests: https://docs.stripe.com/api/idempotent_requests
- Stripe, Webhooks: https://docs.stripe.com/webhooks
- Modern Treasury, Accounting for Developers, Part I: https://www.moderntreasury.com/journal/accounting-for-developers-part-i
- Martin Fowler, Money: https://martinfowler.com/eaaCatalog/money.html
- Martin Fowler, MonolithFirst: https://martinfowler.com/bliki/MonolithFirst.html
- Stack Overflow Developer Survey 2025, Technology: https://survey.stackoverflow.co/2025/technology/
- Shopify Help Center, Offline payments: https://help.shopify.com/en/manual/sell-in-person/shopify-pos/selling-offline/offline-payments
- Square Support, Process card payments with offline mode: https://squareup.com/help/us/en/article/7777-process-card-payments-with-offline-mode
- W3Techs, usage of content management systems: https://w3techs.com/technologies/overview/content_management
- Unbounce, Conversion Benchmark Report: https://unbounce.com/conversion-benchmark-report/
- Nielsen Norman Group, 8 Design Guidelines for Complex Applications: https://www.nngroup.com/articles/complex-application-design/
- Paycom news release on the EY payroll-error survey, 2022-12-22: https://s201.q4cdn.com/761236765/files/doc_news/EY-survey-Payroll-errors-average-291-each-impacting-the-economy-2022.pdf

Seen through a search summary (B):
- Auditor General of Canada, Report 1, Building and Implementing the Phoenix Pay System (2018): https://www2.oag-bvg.gc.ca/internet/English/parl_oag_201805_01_e_43033.html
- Gartner, What IT leaders must do to avoid disappointing ERP initiatives: https://www.gartner.com/en/information-technology/insights/what-it-leaders-must-do-to-avoid-disappointing-erp-initiatives
- The Register, 2025-11-13: https://theregister.com/2025/11/13/erp_disaster_gartner/
- Modern Treasury, Announcing Ledgers: https://www.moderntreasury.com/journal/announcing-ledgers
- Panorama Consulting, How to Avoid HRIS Implementation Failure: https://www.panorama-consulting.com/?p=271266
- Salesforce, sales productivity (Trailhead): https://trailhead.salesforce.com/de/content/learn/modules/introduction-to-agentforce-sales/discover-the-modern-sales-landscape

Leads only (C):
- Altoros, What Makes CRM Projects Fail: https://www.altoros.com/blog/what-makes-customer-relationship-management-projects-fail/
- Nutshell, CRM issues: https://www.nutshell.com/blog/crm-issues-and-how-to-address-them
- Dodo Payments, Payment Ledger Design: https://dodopayments.com/blogs/payment-ledger-design/
- Cleverence, offline warehouse sync: https://www.cleverence.com/articles/business-blogs/offline-warehouse-multi-channel-sync-small-business-3846/
- Rangle, headless CMS playbook, authoring experience: https://tbw.rangle.io/headless-cms-playbook/authoring-experience/best-practices
- Tilleke & Gibbins, PDPA lawful basis and sensitive personal data: https://www.tilleke.com/insights/thailand-operationalising-pdpa-lawful-basis-sensitive-personal-data-and-data-processing-safeguards/26/
- Securiti, employee data in Thailand: https://securiti.ai/blog/employee-data-thailand
