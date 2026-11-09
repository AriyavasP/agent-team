# Benchmark project

A fixed project and two fixed requests, so every version of the plugin is scored on the same input and graded by the same hidden checks. It supplies the numbers `SCORING.md` asks for.

**What is fixed:** the seed project (`seed/`), the two requests (`requests/f1.md`, `requests/f2.md`), the hidden checks (`hidden/cases.js`, never copied into the project), the grader and the measurement (`bench.js`). `node bench/bench.js selftest` proves it: the seed hash and first commit are identical on every machine, the seed fails every hidden case, the reference solutions pass all of them, grading the same code twice gives the same result, and a float-money mistake is caught.

**What is not fixed:** the agents. The same request can come out differently on two runs. So a score from one run is a sample. For a release decision use the **median of three runs**; for a quick look, one.

## The project

`ledger-lite`: a zero-dependency Node.js invoice library (money in integer satang, errors as codes, an in-memory store). `seed/.agent/project.md` is already filled in, so `/agent-team:init` is not part of the run.

Two features, run **one after the other in the same project**:

| | request | planted on purpose |
|---|---|---|
| F1 | invoice payments | `float-money` (amounts are baht strings; `parseFloat` gives wrong satang for 1.15, 4.35, 0.29), `stale-version` (the store has no versions; a plan that forgets the store has a gap) |
| F2 | invoice refunds | the same two classes again — if F1's lesson was kept, they do not come back |

That second point is what measures LRN2 in `SCORING.md`.

## Run it

```bash
# 1. a fresh project (fails if the directory is not empty)
node bench/bench.js setup /tmp/bench-run

# 2. the request to give the plugin (headless example)
cd /tmp/bench-run
claude -p "$(node /path/to/agent-team/bench/bench.js prompt f1)" \
  --plugin-dir /path/to/agent-team --output-format stream-json --verbose > f1.jsonl
#    take it through the gates as a human would (GATE 1, BUILD, GATE 2, fixes, GATE 3) and run /agent-team:retro

# 3. grade
node /path/to/agent-team/bench/bench.js grade /tmp/bench-run f1

# 4. the same project, now F2
claude -p "$(node /path/to/agent-team/bench/bench.js prompt f2)" ... > f2.jsonl
node /path/to/agent-team/bench/bench.js grade /tmp/bench-run f2     # also re-runs every F1 case

# 5. time, cost, tokens, models, foreground calls of each run
node /path/to/agent-team/bench/bench.js measure f1.jsonl f2.jsonl
```

Turn the output into levels with the tables in `SCORING.md`:

| `SCORING.md` | read from |
|---|---|
| ACC1, ACC3 | your count of gate corrections and `GAP:` lines in `.agent/state.md` |
| ACC2 | `grade` cases that fail although `qa` reported pass |
| SPD1–SPD3 | `measure` → `minutes` per stage (run each stage as its own session) |
| TOK1, TOK2 | `measure` → `tokensByModel`, `calls` (model per call), `notForeground` |
| LRN2 | `grade f2` → `byTag`: a tag that failed in F1 and fails again in F2 is a repeat |

## Notes from the first run

- **Tokens** in `measure` are input + output + cache creation + cache reads per model. For `SCORING.md` use input + output + cache creation and leave cache reads out (they are priced at a fraction and dominate the total).
- The requests begin with *"Build a new capability that does not exist yet, with the agent team."* Without it the orchestrator did not pick a lane in 3 of 3 runs and edited the code itself; with it, it chose the full pipe. The line is fixed so versions compare; the routing weakness is recorded in `TESTING.md` (22nd run).
- The harness must allow the `PowerShell` tool on Windows (`--allowedTools "Bash PowerShell …"`), or `npm test` is refused.
- **The seed no longer states the money convention** (2.5.3 re-baseline): it was in `seed/.agent/project.md` and as a comment in `money.js`, which kept the `float-money` trap from biting in run 1. It is now a rule only a finding and `/agent-team:retro` can add. F1's request still specifies the version check, so `stale-version` is specified, not discovered. Re-baselined with `fingerprint --write`.

## Keep it fixed

- Change nothing under `seed/`, `requests/`, `hidden/` or `reference/` without re-baselining on purpose: `node bench/bench.js fingerprint --write`, then `selftest`, then say so in the `SCORING.md` history. Scores from before and after the change do not compare.
- The hidden checks must never be copied into a run's project. `setup` copies only `seed/`.
- Requires Node 18+ and git. No packages are installed.
