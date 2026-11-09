# Scoring the plugin

A fixed way to put one number on a version of this plugin, so a change is judged against the version before it. `TESTING.md` says what to run; `scripts/check-plugin.py` says whether the files agree; this file says **what the results are worth**.

The plugin is judged on four things, **equally weighted**. Each axis is scored out of 10; the **overall** is the mean of the four, also out of 10.

| axis | what the human wants | scored out of |
|---|---|---|
| **Accuracy** | little re-work: few corrections at the gates, few gaps mid-build | 10 |
| **Speed** | a feature reaches each gate quickly | 10 |
| **Token economy** | usage stays low | 10 |
| **Learning** | the more it is used, the fewer the mistakes | 10 |

Inside an axis the criteria carry the weights shown below (they add up to that axis). Safety and file integrity are not scored — they are **release gates**: failing one blocks the version however high the score is.

Score a version before bumping `version`, and record it in the history at the end.

## The scale

Every criterion is scored 0–4. Axis score = Σ (weight × level ÷ 4) over the axis's criteria, ÷ the axis's total weight × 10. **Overall = the mean of the four axis scores** (0–10; × 10 for a figure out of 100).

| level | meaning |
|---|---|
| 4 | meets the target; **evidence from the current minor version** (2.5.x for 2.5.3) |
| 3 | meets it, or is just short; or the evidence is from an earlier version with the relevant files unchanged |
| 2 | about twice the target, or only part of it was exercised |
| 1 | far from it, or no live evidence beyond the design |
| 0 | fails, or the mechanism does not exist |

Each criterion gives the number that earns 4, 2 and 0; 3 and 1 sit between.

## Rules

1. **Cite evidence.** Every level names the run, file, command or line it rests on. No citation, no score.
2. **Evidence ages.** Level 4 needs a run on the current minor. Older evidence caps the level at 3. No evidence at all → `N/M`: 0 in the *conservative* score, left out of the *measured* score (the axis is re-scaled without it). Always report both.
3. **Numbers come from the run, not from memory.** Minutes and tokens are read from the run's own record (`stream-json` `result`, the subagent `.jsonl`, the `TESTING.md` row). Time spent waiting on a usage limit or an outage is subtracted and said so.
4. **Same task, same yardstick.** Speed and token figures are compared per feature of about the same size (≈ 30 ACs, ≈ 12 tasks). A very different size is scaled per AC / per task, and the row says so.
5. **Scorer.** The agent that made a change may not be the only scorer of it; if it was, the row is *provisional* until the human reads the evidence.
6. **No silent regressions.** No criterion falls by 2 levels or more, and the overall falls by no more than 0.3, unless the history row says why.

## Release gates (pass / fail, not scored)

| gate | pass when | evidence |
|---|---|---|
| G1 files agree | `python3 -I scripts/check-plugin.py` reports 0 errors | the script's output |
| G2 guards hold | every guard case in the checker passes; no command in the blocked list runs in S8 | checker, S8 |
| G3 scope and secrets | no write outside a role's scope, no secret read, the ops lane runs nothing on a real system | review/security findings, S12 |
| G4 gates hold | no run skipped a gate or edited code before GATE 1 | S1–S4, S9, S10, S12 |

## Criteria

### ACC — Accuracy (30)

| id | w | measures | how to read it | 4 | 2 | 0 |
|---|---|---|---|---|---|---|
| ACC1 | 10 | corrections the human makes at GATE 1 and GATE 2 because an agent was wrong (a changed preference does not count) | count in the run record | ≤ 1 per feature | 3–4 | ≥ 6 |
| ACC2 | 8 | defects that reach the human unseen by review and qa | defects found after VERIFY, or by the human at GATE 2 that no agent reported | 0 | 2 | ≥ 4, or a data-loss bug escapes |
| ACC3 | 6 | design or plan gaps found during BUILD | `GAP:` lines and amendments per 10 tasks | 0 | 2–3 | ≥ 5, or a full re-plan |
| ACC4 | 6 | claims in documents and designs are true to their sources | trace ≥ 5 claims by hand to `file:line` | all trace; gaps flagged, none invented | a few unsupported | invented facts |

### SPD — Speed (25)

| id | w | measures | how to read it | 4 | 2 | 0 |
|---|---|---|---|---|---|---|
| SPD1 | 10 | request to GATE 1 (sa → ux → tech-lead-plan) | wall-clock minutes, ≈ 30 ACs | ≤ 15 | ≤ 30 | > 45 |
| SPD2 | 10 | BUILD, minutes per task | wall-clock ÷ tasks, waits subtracted | ≤ 6 | ≤ 12 | > 20 |
| SPD3 | 5 | VERIFY to GATE 2 | wall-clock minutes for review + ux AUDIT + qa + security | ≤ 20 | ≤ 45 | > 75 |

### TOK — Token economy (25)

| id | w | measures | how to read it | 4 | 2 | 0 |
|---|---|---|---|---|---|---|
| TOK1 | 10 | spec and plan, and the largest single call | tokens of sa + ux + plan; largest call in the feature | ≤ 400k, and no call > 250k | ≤ 800k | > 1.2M |
| TOK2 | 8 | the right model and call count | `model` of each `Agent` input against `orchestrator.md` → "Model per call"; calls ≈ N + 5 | all match, ≤ N + 6 calls | one role wrong, or ≤ 2 × N | models ignored, or a verification repeated |
| TOK3 | 7 | what is paid on every session | orchestrator words; longest agent prompt | ≤ 4000 words, every prompt ≤ 10,000 chars | one over | several far over |

### LRN — Learning (20)

| id | w | measures | how to read it | 4 | 2 | 0 |
|---|---|---|---|---|---|---|
| LRN1 | 8 | lessons are kept | `/agent-team:retro` run after each feature; `.agent/project.md` stays under ~200 lines and holds the recurring finding classes as rules | every feature | some features | never |
| LRN2 | 8 | the same mistake does not come back | two features in the **same project**, one after the other: finding classes of the first that reappear in the second | none reappear | about half | all reappear |
| LRN3 | 4 | the plugin learns from its own defects | each `D-nn` in `TESTING.md` has a fix, a pin in `check-plugin.py` and a re-run showing it holds | all three, every time | fixed but not pinned or not re-run | a fixed defect came back |

LRN2 is the only criterion that needs two real features back to back; until one is run it stays `N/M`.

## Measuring with the benchmark

`bench/` holds a fixed project (`ledger-lite`), two fixed requests run back to back in it, hidden checks and a grader, so the same input and the same yardstick are used for every version. `bench/README.md` says how to run it and which output feeds which criterion; `node bench/bench.js selftest` proves the yardstick itself is stable. The agents are not deterministic: a release decision uses the **median of three runs**, and the row says how many runs it rests on. The 2.5.2 baseline below was built from earlier recorded runs, **not yet** from this benchmark — re-score it on the benchmark first, and treat that as the real baseline.

## History

| version | date | ACC | SPD | TOK | LRN | **overall** | scorer | status |
|---|---|---|---|---|---|---|---|---|
| **2.5.3, benchmark run 3 (1 run, whole pipeline to GATE 2)** | 2026-11-09 | 8.83 | 9.50 | 6.00 | 7.00 | **7.83** | the agent that ran it | **current baseline, provisional** |
| 2.5.2, benchmark run 1 (1 run) | 2026-11-09 | 8.00 | 8.00 | 6.00 | 4.00 | 6.50 | the agent that ran it | not comparable: VERIFY never ran, agents had no shell |
| 2.5.2 measured, benchmark run 1 of 1 | 2026-11-09 | 8.00 | 10.00 | 6.00 | 6.67 | 7.67 | (SPD3, LRN2 left out) | flatters: do not compare against it |
| 2.5.2 conservative, earlier recorded runs | 2026-11-09 | 6.33 | 8.00 | 6.80 | 3.00 | 6.03 | the agent that made the change | superseded by the row above |

Use the **conservative** column for comparisons. The measured column leaves out what was not reached, which in this run is the whole of VERIFY.

Gates for 2.5.2: G1 pass (0 errors, 2 warnings, run in WSL), G2 pass (checker guard cases), G3 pass (P-02 security pass, S12 run), G4 pass (every 2.5.x run stopped at its gate).

Gates for 2.5.3: G1 pass (0 errors, 2 warnings, run in WSL), G2 and G3 not re-exercised this run (guard cases pass in the checker; `/security-review` did not complete in either benchmark feature, so G3 rests on review findings only), G4 pass (both features stopped at GATE 1 and GATE 2).

### 2.5.3 — benchmark run 3: what was reached

One run of `bench/`, F1 then F2, with the harness fixed (agents now get a shell: `CLAUDE_CODE_GIT_BASH_PATH`; the "human" accepts every retro line). **Both features went SPEC → PLAN → GATE 1 → BUILD → VERIFY (review + qa) → GATE 2 → fix batch (empty) → retro → ship, with no question asked in between.** Hidden cases: F1 12/12; F2 9/9 plus F1 12/12; project tests 41 → 68. Nothing is `N/M`.

| id | level | points | evidence (and what held it below 4) |
|---|---|---|---|
| ACC1 | 4 | 10.0 | GATE 1 approved as proposed in both, 0 corrections; GATE 2 reached in both |
| ACC2 | 3 | 6.0 | hidden grader 0 failures in 21; review and qa ran and found only minors — but no seeded defect bit, so their ability to catch a real one is still unshown. `/security-review` was not completed in either feature (F2 called the Skill and still reported it did not run) |
| ACC3 | 4 | 6.0 | no `GAP:` reported by any developer call in either feature |
| ACC4 | 3 | 4.5 | unchanged (documents not in this benchmark) |
| SPD1 | 4 | 10.0 | request to GATE 1: 2.6 min (27 ACs) and 3.1 min (30 ACs) |
| SPD2 | 4 | 10.0 | BUILD + VERIFY together took 5.4 min (3 tasks) and 7.0 min (4 tasks), so BUILD per task is under 2 min |
| SPD3 | 3 | 3.75 | VERIFY is inside that 5.4 / 7.0 minutes, so ≤ 20 min is certain; its own time is not separable (one session) |
| TOK1 | 3 | 7.5 | spec + plan 143k and 143k tokens (input + output + cache creation). Largest single call not measured |
| TOK2 | 2 | 4.0 | **F2 right, F1 wrong.** F2: tasks low/high/high/low ran on default/opus/opus/default, review on opus. F1: tasks low/mechanical/high all ran on the default, review on the default (should be haiku, opus, opus), and all 5 F1 build/verify `Agent` calls carried no `run_in_background`. 5 of 15 calls without it |
| TOK3 | 2 | 3.5 | orchestrator back under 4000 words; `sa.md` and `ux.md` still over 10,000 chars |
| LRN1 | 4 | 8.0 | retro ran after both features and wrote its lines to `project.md` (31 → 33 → 36 lines of ~200) |
| LRN2 | 2 | 4.0 | F1's retro turned two review findings into rules — one was *"do not write try/catch helpers"* in tests. **F2 broke that rule and got the same finding** (R-01, a try/catch in the AC-030 test); the other F1 finding (R-02) did not come back. 1 of 2 classes repeated. The `float-money` trap still did not bite (`toSatang` exists in the code), so it says nothing about learning |
| LRN3 | 2 | 2.0 | unchanged: D-06 not re-run; D-02 only partly better |
| **axes** | | | ACC 26.5/30 → 8.83 · SPD 23.75/25 → 9.50 · TOK 15/25 → 6.00 · LRN 14/20 → 7.00 · **overall 7.83** |

The 2.5.2 run-1 row differs in two ways besides the plugin: its agents had no shell and it never reached VERIFY, so **the +1.33 is not all the plugin** — compare future versions with run 3, not run 1.

**Cheapest points to win now:** TOK2 (F1 build ran with no model or foreground fields in 3 of 3 runs while F2 got them right — find what differs in a project's first BUILD session), LRN2 (a rule that is in `project.md` was still broken: make the developer and review read the Conventions as a checklist), `/security-review` never completing, TOK3 (`sa.md`, `ux.md`).

### 2.5.2 — benchmark run 1: what was and was not reached

One run of `bench/` (F1 then F2, one headless session per stage, a fixed "human" policy; `TESTING.md` 22nd run). SPEC, PLAN and BUILD ran for both features and every hidden case passed (F1 12/12; F2 9/9 plus F1 12/12; project tests 33 → 61). **VERIFY, TRIAGE and FIX were never reached** — after BUILD the orchestrator reported "Next in VERIFY … I haven't started any of it" and stopped, both times; the fix stage then found no findings. So SPD3 and LRN2 are `N/M`, ACC2 rests on the hidden grader alone, and the learning axis has nothing to learn from.

| id | level | points | evidence |
|---|---|---|---|
| ACC1 | 3 | 7.5 | GATE 1 approved as proposed in both features (0 corrections); GATE 2 never reached, so half the gates were exercised |
| ACC2 | 3 | 6.0 | hidden grader: 0 failing cases in 21; but `tech-lead-review` and `qa` never ran, so the ability to find a defect is untested |
| ACC3 | 4 | 6.0 | 0 `GAP:` lines in 9 developer calls; the planted missing store version was covered by T-001 in the plan |
| ACC4 | 3 | 4.5 | unchanged from the T3 run on 2.5.2 (documents were not part of this benchmark) |
| SPD1 | 4 | 10.0 | request to GATE 1: 3.0 min (27 ACs) and 2.9 min (29 ACs) |
| SPD2 | 4 | 10.0 | BUILD 2.6 min for 3 tasks and 5.7 min for 4 tasks (52 s and 86 s a task). Tasks here are small; the yardstick was set on 12-task parts |
| SPD3 | N/M | 0.0 | VERIFY did not run |
| TOK1 | 3 | 7.5 | spec + plan 112k and 128k tokens (input + output + cache creation; cache reads excluded, see `bench/README.md`). Largest single call is not in the stream-json, so 4 is not claimed |
| TOK2 | 2 | 4.0 | F1's plan marked T-001 `high` and T-002 `mechanical`; all three developer calls carried no `model`, so ran on the default (should be opus and haiku). F2's tasks were all `low`: correct. 3 of 13 `Agent` calls (all F1 BUILD) carried no `run_in_background` |
| TOK3 | 2 | 3.5 | unchanged |
| LRN1 | 3 | 6.0 | `/agent-team:retro` ran after both features; it proposed nothing because no review or test report existed. `project.md` stayed at 23 lines |
| LRN2 | N/M | 0.0 | no finding was raised in F1, so there is nothing to repeat in F2. The planted `float-money` trap did not bite at all (see below) |
| LRN3 | 2 | 2.0 | unchanged |
| **axes** | | | ACC 24/30 → 8.00 · SPD 20/25 → 8.00 (measured 10.00) · TOK 15/25 → 6.00 · LRN 8/20 → 4.00 (measured 6.67) |

**The benchmark itself needs work before the learning axis can be read from it:** the seed's `.agent/project.md` already states the money convention (baht strings, `toSatang`), so the `float-money` trap never bites, and F1's request spells out the version check, so `stale-version` is specified rather than discovered. Nothing was found in F1, so F2 cannot show a lesson kept. Remove the convention line from the seed (so that it is a rule only a retro can add) and re-baseline with `fingerprint --write`.

**Cheapest points to win now:** get VERIFY to run after BUILD (SPD3, ACC2, and everything LRN depends on), apply `complexity` → model on developer calls (TOK2), then re-run.

### 2.5.2 — detail from the earlier recorded runs (superseded)

| id | level | points | evidence (and what held it below 4) |
|---|---|---|---|
| ACC1 | 3 | 7.5 | P-02: one GATE 1 change (a fresh profile must open with a `payments.verify` holder) plus D-06, where the orchestrator improvised a path for a ruling — about 2 |
| ACC2 | 2 | 4.0 | P-02 reached GATE 2 only; qa caught the data-loss bug (F-01) through AC-029. No feature has shipped on 2.5.x, so escapes after VERIFY are unknown |
| ACC3 | 2 | 3.0 | P-02: 3 amendments over 13 tasks (one from T-007's `GAP:`); the third needed a patch and stopped for the human |
| ACC4 | 3 | 4.5 | T3 on 2.5.2: 22 claims traced, 5 checked by hand against `src/orders.js`, all correct; one run each for the haiku draft and sonnet `ui-designer` |
| SPD1 | 4 | 10.0 | P-02 SPEC → UX → PLAN 12.9 min for 34 ACs (P-01 on 2.2: 46 min) |
| SPD2 | 3 | 7.5 | P-02 BUILD ≈ 120 min over 13 tasks ≈ 9 min a task (usage-limit and outage waits already out of the 120) |
| SPD3 | 2 | 2.5 | P-02 VERIFY ≈ 40 min; the single opus review call took 39 min |
| TOK1 | 3 | 7.5 | P-02 spec + plan 337k tokens; the review call 255k, just over 250k |
| TOK2 | 3 | 6.0 | T1–T3 models as written (writer haiku → default for EDIT; `ui-designer` sonnet); `ba` not run on sonnet; all three 2.5.2 runs called `Agent` without `run_in_background` |
| TOK3 | 2 | 3.5 | orchestrator just under 4000 words; `sa.md` 19,413 and `ux.md` 15,000 chars, both over 10,000 |
| LRN1 | 2 | 4.0 | `/agent-team:retro` exercised on P-01 (2.2–2.3), not on 2.5.x |
| LRN2 | N/M | 0.0 | no two consecutive features in one project have been scored |
| LRN3 | 2 | 2.0 | D-06 fixed in 2.5.1 and not re-run; D-02 (calls backgrounded) has no mechanical fix — a hook cannot change the field (tried and removed) — so it rests on rule 9 and came back in 3 of 13 calls |
| **axes** | | | ACC 19/30 → 6.33 · SPD 20/25 → 8.00 · TOK 17/25 → 6.80 · LRN 6/20 → 3.00 (measured: 6/12 → 5.00) |

**Cheapest points to win:** LRN2 (run two features back to back — 8 points waiting on evidence), LRN3 (re-run D-06; D-02 has no hook fix), SPD3 and TOK1 (the one 250k review call), TOK3 (trim `sa.md` and `ux.md`).

## Keeping the standard

- Change a weight or an anchor only with a line in the history saying why, and re-score the previous version under the new rule so the two numbers compare.
- A thing the human wants that no criterion covers is a sign to add one and rebalance to 100, not to ignore it.
- `scripts/check-plugin.py` does not read this file. If it should (for instance, the weights in each axis adding up), add that there.
