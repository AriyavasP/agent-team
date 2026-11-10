# Product profiles

A profile holds the domain rules of one kind of product, independent of language and framework. The SessionStart hook copies this folder into each project's `.agent/profiles/` every session. A project opts in by naming a profile in `.agent/project.md` → "Product profile"; `/agent-team:init` sets it.

A profile ranks below `.agent/project.md` and a human ruling, and above the library.

| profile | for | status |
|---|---|---|
| finance | anything that records or moves money: ledgers, invoicing, payments, refunds, the money side of ERP, e-commerce and POS | rules checked against sources (plugin `research/enterprise-domains.md`); scored once on the benchmark (2.6.0, run 4: the features ran with it, learning fell, see `SCORING.md`) |

`stacks.md` is not a profile: `/agent-team:init` reads it to propose a stack for a project with no code yet.

## Who reads what

Every profile has the same five numbered sections, so each agent cuts out only its own with `sed -n '/^## <n>\./,/^## /p'`.

| section | read by |
|---|---|
| 1. Rules newcomers get wrong | `sa`, `developer`, `qa`, `tech-lead-review` |
| 2. Required ACs | `sa` |
| 3. Design must decide | `sa` |
| 4. Tests that must exist | `qa` |
| 5. Review checks | `tech-lead-review` |

## Adding a profile

0. Start from the domain's section in the plugin's `research/enterprise-domains.md`: its candidate rules and their sources. A rule with no source better than grade C is marked as judgement in the research file.
1. Write `profiles/<name>.md` with sections 1-5 exactly as titled above. State behaviour, never code, and no legal or tax figure of any country.
2. Add its row to the table above.
3. Run `python3 -I scripts/check-plugin.py`.
4. Score it on a benchmark in that domain before calling it verified.
