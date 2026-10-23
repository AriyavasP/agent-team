#!/usr/bin/env python3
"""Contract checker for the agent-team plugin.

The agents, skills and the orchestrator depend on each other through plain text:
artifact file names, section numbers, GAP kinds, STATUS values, the sed commands
developer uses to cut one task out of 03-tasks.md. Nothing enforces those
contracts at runtime, so an edit to one file can silently break another.
This script checks them. Run it before every version bump:

    python3 -I scripts/check-plugin.py

Exit code 1 on any ERROR. WARN lines are budgets worth a look, not failures.
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
errors, warnings = [], []


def err(msg):
    errors.append(msg)


def warn(msg):
    warnings.append(msg)


def read(rel):
    return (ROOT / rel).read_text(encoding="utf-8")


def frontmatter(text):
    m = re.match(r"^---\n(.*?)\n---\n", text, re.S)
    if not m:
        return None
    fields = {}
    for line in m.group(1).splitlines():
        if ":" in line and not line.startswith(" "):
            key, value = line.split(":", 1)
            fields[key.strip()] = value.strip()
    return fields


def code_block_after(text, heading):
    """First ```markdown block after the line containing `heading`."""
    start = text.find(heading)
    if start < 0:
        return None
    m = re.search(r"```markdown\n(.*?)\n```", text[start:], re.S)
    return m.group(1) if m else None


def numbered_sections(block):
    return [int(n) for n in re.findall(r"^## (\d+)\.", block, re.M)]


def expect_sequential(name, nums, last):
    if nums != list(range(1, last + 1)):
        err(f"{name}: section numbers are {nums}, expected 1..{last}")


# Terms from earlier designs that must not come back. Add to this list whenever
# a concept is renamed or removed, so a half-finished rename fails the check.
RETIRED_TERMS = [
    r"module gate",
    r"module table",
    r"\bM-0[0-9n]\b",
    r"review rounds?\s*\|",  # the pre-2.1 per-task review column
    r"\bSCAN mode\b",  # moved out of sa into the impact-analyst agent in 2.2
    r"OWASP Top 10 \(2021\)",  # superseded by OWASP Top 10:2025 in 2.3
]

ARTIFACTS = {
    "00-outline.md", "01-requirements.md", "02-design.md", "02b-ux.md",
    "03-tasks.md", "04-test-report.md", "05-review.md", "06-fixes.md",
    "07-ux-audit.md",
}

GAP_KINDS = {"missing-element", "scope", "design", "requirement"}

CHAR_BUDGET_AGENT = 10_000   # plugin-dev agent-development guidance
WORD_BUDGET_ORCHESTRATOR = 4_000  # injected into every session


def text_files():
    for pattern in ("agents/*.md", "skills/*/SKILL.md", "hooks/*.md", "hooks/*.sh", "README.md", "STANDARDS.md", "TESTING.md"):
        yield from sorted(ROOT.glob(pattern))


# 1. Manifests -------------------------------------------------------------
try:
    plugin = json.loads(read(".claude-plugin/plugin.json"))
    market = json.loads(read(".claude-plugin/marketplace.json"))
    entry = next(p for p in market["plugins"] if p["name"] == plugin["name"])
    if entry.get("version") != plugin.get("version"):
        err(f"version mismatch: plugin.json {plugin.get('version')} vs marketplace.json {entry.get('version')}")
except (ValueError, KeyError, StopIteration) as e:
    err(f"manifests: {e}")

try:
    hooks = json.loads(read("hooks/hooks.json"))
    for cmd in re.findall(r'\$\{CLAUDE_PLUGIN_ROOT\}/([\w./-]+)', json.dumps(hooks)):
        if not (ROOT / cmd).is_file():
            err(f"hooks.json runs {cmd}, which does not exist")
except ValueError as e:
    err(f"hooks.json: {e}")

# 2. Agents: frontmatter, names, sizes --------------------------------------
orchestrator = read("hooks/orchestrator.md")
rule7 = re.search(r"\*\*Subagent names\*\*:(.*)", orchestrator)
listed = set(re.findall(r"`([a-z-]+)`", rule7.group(1).split(".")[0])) if rule7 else set()
if not listed:
    err("orchestrator.md: could not find the subagent name list (hard rule 7)")

agent_files = sorted(ROOT.glob("agents/*.md"))
for path in agent_files:
    text = path.read_text(encoding="utf-8")
    fm = frontmatter(text)
    rel = path.relative_to(ROOT)
    if fm is None:
        err(f"{rel}: no frontmatter")
        continue
    for field in ("name", "description", "tools", "model", "color"):
        if not fm.get(field):
            err(f"{rel}: frontmatter is missing '{field}'")
    if fm.get("name") != path.stem:
        err(f"{rel}: name '{fm.get('name')}' does not match the file name")
    if listed and path.stem not in listed:
        err(f"{rel}: agent is not in the orchestrator's subagent list")
    body = text.split("---", 2)[-1]
    if len(body) > CHAR_BUDGET_AGENT:
        warn(f"{rel}: system prompt is {len(body)} chars (guidance: under {CHAR_BUDGET_AGENT})")

for name in listed - {p.stem for p in agent_files}:
    err(f"orchestrator lists agent '{name}' but agents/{name}.md does not exist")

COLORS = {"blue", "cyan", "green", "yellow", "magenta", "red"}  # plugin-dev agent-development
for path in agent_files:
    color = (frontmatter(path.read_text(encoding="utf-8")) or {}).get("color")
    if color and color not in COLORS:
        err(f"{path.relative_to(ROOT)}: color '{color}' is not one of {sorted(COLORS)}")

words = len(orchestrator.split())
if words > WORD_BUDGET_ORCHESTRATOR:
    warn(f"hooks/orchestrator.md is {words} words, paid on every session (budget {WORD_BUDGET_ORCHESTRATOR})")

# 3. Artifact names and retired terms ---------------------------------------
for path in text_files():
    text = path.read_text(encoding="utf-8")
    rel = path.relative_to(ROOT)
    for name in set(re.findall(r"\b0\d[a-z]?-[a-z-]+\.md\b", text)):
        if name not in ARTIFACTS:
            err(f"{rel}: unknown artifact name '{name}'")
    for term in RETIRED_TERMS:
        for m in re.finditer(term, text, re.I):
            line = text.count("\n", 0, m.start()) + 1
            err(f"{rel}:{line}: retired term '{m.group(0)}'")

# 4. GAP kinds: developer emits them, orchestrator routes them --------------
developer = read("agents/developer.md")
dev_kinds = set(re.findall(r"^\| `([a-z-]+)` \|", developer, re.M))
gap_table = orchestrator[orchestrator.find("| `GAP:` kind"):]
orch_kinds = set(re.findall(r"`([a-z-]+)`", gap_table.split("\n\n")[0])) - {"tech-lead-plan", "sa"}
for label, kinds in (("developer.md", dev_kinds), ("orchestrator.md", orch_kinds)):
    if kinds != GAP_KINDS:
        err(f"{label}: GAP kinds are {sorted(kinds)}, expected {sorted(GAP_KINDS)}")

# 5. Templates keep their numbered sections ---------------------------------
sa = read("agents/sa.md")
ux = read("agents/ux.md")
checks = [
    ("sa outline template", code_block_after(sa, "00-outline.md — one to two pages"), 5),
    ("sa requirements template", code_block_after(sa, "### Part A"), 6),
    ("sa design template", code_block_after(sa, "### Part B"), 9),
    ("ux 02b-ux.md template", code_block_after(ux, "## DESIGN mode"), 9),
]
for name, block, last in checks:
    if block is None:
        err(f"{name}: template block not found")
    else:
        expect_sequential(name, numbered_sections(block), last)

# 6. developer's sed ranges work on the 03-tasks.md template ----------------
plan = read("agents/tech-lead-plan.md")
tasks = code_block_after(plan, "## Template")
if tasks is None:
    err("tech-lead-plan: 03-tasks.md template not found")
else:
    if re.search(r"^####", tasks, re.M):
        err("tech-lead-plan template: has a heading deeper than ###, which breaks developer's sed range")
    lines = tasks.splitlines()
    starts = [i for i, l in enumerate(lines) if re.match(r"^### T-\d+ ", l)]
    if not starts:
        err("tech-lead-plan template: no '### T-NNN ' task heading")
    for i in starts:
        # emulate: sed -n '/^### <T-ID> /,/^##/p'
        rng = [lines[i]]
        for l in lines[i + 1:]:
            rng.append(l)
            if l.startswith("##"):
                break
        body = "\n".join(rng)
        if "Definition of Done" not in body or "files touched" not in body:
            err(f"tech-lead-plan template: sed range for '{lines[i]}' loses part of the task")
    if "## Amendments" not in tasks or "## Coverage" not in tasks:
        err("tech-lead-plan template: missing '## Coverage' or '## Amendments'")
for needle in ("sed -n '/^### <T-ID> /,/^##/p'",):
    if needle not in developer:
        err(f"developer.md: task sed command changed — expected {needle}")

# 7. Rules duplicated on purpose stay identical -----------------------------
# Subagents cannot read each other's files, so sa (SPEC) and ba both carry the
# AC rules. A change made to one and not the other is exactly the silent drift
# this script exists to catch.
def ac_rules(text):
    m = re.search(r"These are the characteristics.*?\n4\. \*\*One scenario per AC\*\*[^\n]*", text, re.S)
    return m.group(0) if m else None


ba_rules, sa_rules = ac_rules(read("agents/ba.md")), ac_rules(sa)
if ba_rules is None or sa_rules is None:
    err("AC rules block not found in sa.md or ba.md")
elif ba_rules != sa_rules:
    err("AC rules differ between sa.md and ba.md — change both or neither")

# D-03 (2.2 test run): one part's spec ran to 32,500 words. The budgets are the fix;
# a rewrite that drops them should fail here, not in the next real run.
BUDGET_PINS = [
    ("agents/sa.md", "≤ 30 ACs"), ("agents/sa.md", "a guide, not a limit on detail"),
    ("agents/ux.md", "≤ ~2,500 words and ≤ 15 UX criteria"), ("agents/ux.md", "never restates an AC"),
    ("hooks/orchestrator.md", "word count"),
]
# 2.3: rules adopted from the first real runs and from OneWave AI claude-skills (MIT).
# Each pin names the rule's purpose, so a rewrite that drops one fails loudly.
BUDGET_PINS += [
    ("agents/sa.md", "default if unanswered"),                 # every open question has a default
    ("agents/ba.md", "default if unanswered"),
    ("agents/developer.md", "that is a `GAP: missing-element`, not something to invent"),
    ("agents/qa.md", "not browser-verified"),
    ("agents/tech-lead-review.md", "OWASP Top 10:2025"),
    ("agents/tech-lead-review.md", "## Not reviewed"),
    ("skills/retro/SKILL.md", "**verbatim**"),                  # D-04
    ("hooks/orchestrator.md", "has its commit in `git log`"),   # resume against reality
    ("hooks/orchestrator.md", "deferred to a later part"),      # outline section 5 at ship
    ("hooks/session-start.sh", "## Voice and style"),
    ("hooks/session-start.sh", "## Reference work"),
    # 2.3 roles for human-like output: the rules the research says matter most
    ("agents/writer.md", "Every claim has a source"),
    ("agents/writer.md", "never drafted in English and translated"),
    ("agents/writer.md", "## EDIT mode — you did not write this"),
    ("agents/writer.md", "At most 15 lines for a document of two pages or less"),
    ("agents/writer.md", "No source table, no line numbers, no word counts per section"),
    ("agents/ui-designer.md", "**Named references**"),
    ("agents/ui-designer.md", "real content from the project"),
    ("skills/docs-lane/SKILL.md", "two separate calls"),
    ("skills/design-lane/SKILL.md", "docs/design/DESIGN.md"),
    # 14th run: a part's spec cost more than P-01 because sa re-surveyed the codebase
    ("agents/sa.md", "Stop surveying once you can name every file this part touches"),
    ("hooks/orchestrator.md", "`sa` → its default (sonnet) in every mode"),
    ("agents/sa.md", "Never bundle two triggers into one AC to stay under 30"),
    # 17th run: on sonnet the section-4 checklist is what keeps the edge cases
    ("agents/sa.md", "for a malformed saved record and a failed save"),
    ("agents/sa.md", "for a change made elsewhere meanwhile (another tab or user)"),
    # 2.4 library: subagents are refused reads outside the project (D-05), so the hook copies it in
    ("hooks/orchestrator.md", "each finds its library skills in `.agent/library/` itself"),
    ("hooks/session-start.sh", "printf '*\\n' > .agent/library/.gitignore"),
    ("skills/docs-lane/SKILL.md", "statements of work, RFP responses, SOPs, FAQs"),
]
for rel, needle in BUDGET_PINS:
    if needle not in read(rel):
        err(f"{rel}: pinned rule text '{needle}' is gone — see the comment above BUDGET_PINS and TESTING.md → Permanent regression cases")

# 8. complexity levels: tech-lead-plan assigns them, the orchestrator maps them to models
COMPLEXITY_MODELS = {"mechanical": "haiku", "high": "opus"}  # `low` → the agent default
if "`mechanical`, `low` or `high`" not in plan:
    err("tech-lead-plan.md: complexity levels are no longer `mechanical`, `low` or `high`")
model_line = next((l for l in orchestrator.splitlines() if "gives every task a `complexity:`" in l), "")
for level, model in COMPLEXITY_MODELS.items():
    if f"`{level}` → `{model}`" not in model_line:
        err(f"orchestrator.md: 'Model per call' no longer maps `{level}` → `{model}`")
if "`low` → the agent default" not in model_line:
    err("orchestrator.md: 'Model per call' no longer maps `low` to the agent default")
if "DECISION:" not in developer or "`DECISION:`" not in model_line:
    err("developer.md and orchestrator.md must both handle the `DECISION:` line of a mechanical task")

# D-02 (2.2 test run): the orchestrator ran impact-analyst in the background,
# ended its turn, and the human's /clear killed the agent five minutes in.
if "run_in_background: false" not in orchestrator:
    err("orchestrator.md: the foreground rule for subagent calls is gone — see D-02 in TESTING.md")

# 9. STATUS values the orchestrator relies on exist in the agents -----------
status_contracts = [
    ("agents/sa.md", "OUTLINE"),
    ("agents/sa.md", "NEEDS-PM"),
    ("agents/developer.md", "BLOCKED"),
    ("agents/tech-lead-plan.md", "NEEDS-PM"),
]
for rel, value in status_contracts:
    status_lines = re.findall(r"^STATUS: (.*)$", read(rel), re.M)
    if not any(value in s for s in status_lines):
        err(f"{rel}: no STATUS line offers '{value}', but the orchestrator routes on it")

# 10. Guards block what they should, and only that ---------------------------
# D-01 (2.2 test run): `if:` rules in hooks.json fired on any command Claude Code
# could not parse, all at once. The guards are scripts now; these cases pin both
# directions. Strings below are test data fed to the guard on stdin — never run.
if '"if"' in read("hooks/hooks.json"):
    err("hooks.json has an `if:` rule again — see D-01 in TESTING.md; put the pattern in a guard script")

GUARD_CASES = {
    "hooks/guard-bash.sh": ("command", [
        # must block
        "git push", "git push origin main", "git -C /tmp push", "git -c user.name=x push",
        "ls && git push", "git reset --hard HEAD~1", "git clean -fd",
        "rm -rf build", "rm -fr build", "rm -r -f build", "rm --recursive build",
        "sudo rm -rf build", "cd x && rm -rf y", "/bin/rm -rf y",
        "terraform apply", "terraform -chdir=infra apply", "terraform destroy",
        "kubectl apply -f x.yaml", "kubectl -n prod delete pod x", "kubectl rollout restart deploy/x",
        "helm install x ./chart", "helm upgrade x ./chart", "docker push img:1",
        "npm publish", "pnpm publish --access public", "yarn publish",
        "aws s3 ls", "FOO=1 aws s3 ls", "echo $(aws sts get-caller-identity)",
        "gcloud auth list", "az login", "ssh host", "echo x | ssh host", "scp a host:b",
        "cat .env", "grep SECRET .env.local", "cat config/.env", "head ~/.ssh/id_rsa",
        "cat certs/server.pem", "if git push; then echo ok; fi", "for f in a; do git push; done",
    ], [
        # must allow — the first five are the commands D-01 blocked in the test run
        "for f in tests/*; do echo \"$f\"; done", "for x in a b; do echo \"$x\"; done",
        "echo hi > /tmp/x.txt && cat /tmp/x.txt", "echo \"${HOME}\"", "true; echo \"exit=$?\"",
        "git status", "git log --oneline -5", "git diff HEAD~1", "git commit -m \"push later\"",
        "git reset --soft HEAD~1", "git stash", "node -e \"console.log(process.env.HOME)\"",
        "node --test 'tests/*.test.cjs'", "cat .env.example", "rm file.txt", "rm -f file.txt",
        "pnpm test", "npm run build", "grep -rn \"git push\" docs/", "grep -r aws .",
        "docker build .", "kubectl get pods", "terraform plan", "helm list",
        "python3 -m http.server 8000 --bind 127.0.0.1",
        # agents reading their library skill
        "cat .agent/library/env-setup-wizard/SKILL.md", "grep -F '| env-setup-wizard |' .agent/library/INDEX.md",
        "sed -n '1,80p' .agent/library/runbook-generator/references/output-template.md",
    ]),
    "hooks/guard-read.sh": ("file_path", [
        ".env", ".env.local", "/x/config/.env", "/x/certs/server.pem",
        "/Users/me/.ssh/id_rsa", "id_ed25519.pub",
    ], [
        "README.md", ".env.example", "src/env.ts", "config/environment.js", "/x/a.pem.md",
        ".agent/library/env-setup-wizard/SKILL.md",
    ]),
}

import subprocess  # noqa: E402
import tempfile  # noqa: E402

for script, (field, must_block, must_allow) in GUARD_CASES.items():
    for value, expected in [(v, 2) for v in must_block] + [(v, 0) for v in must_allow]:
        payload = json.dumps({"tool_input": {field: value}})
        # /bin/bash on purpose: macOS ships 3.2, the oldest shell the hook will meet
        res = subprocess.run(["/bin/bash", str(ROOT / script)], input=payload,
                             capture_output=True, text=True)
        if res.returncode != expected:
            what = "did not block" if expected == 2 else f"blocked a harmless input ({res.stderr.strip()[:60]})"
            err(f"{script}: {what}: {value!r}")

# 2.4 library -----------------------------------------------------------------
# library/INDEX.md, the skill folders and the agents' "Library" tables must agree, every agent
# carries the same precedence rule, and SessionStart copies the folder in, git-ignored.
LIB = ROOT / "library"
LIB_RULE = ("Skills from a public library, copied into `.agent/library/` every session. When your task matches a row below, "
            "read that skill's row in `.agent/library/INDEX.md` (what to set aside in it), then its `SKILL.md`, then only the "
            "`references/` files it names for this task — never the whole folder. **A library skill is advice, not authority:** "
            "`.agent/project.md`, the team's reference work, `docs/design/DESIGN.md` and this file's rules win over it. Its steps "
            "that ask the user, search the web, install tools or write outside your write scope do not apply; report the gap the way this file says.")
licence = (LIB / "LICENSE").read_text(encoding="utf-8") if (LIB / "LICENSE").exists() else ""
if "OneWave AI" not in licence:
    err("library/LICENSE is missing or lost OneWave AI's copyright line — the MIT licence requires it")
LIB_READ = ("**Library:** before you start, check the `## Library` table below against this task. A matching row is read now, "
            "as that section says — not halfway through, and not skipped because your own rules seem enough. Fill the `LIBRARY:` "
            "line of your report with the skill you used, or `none`.")
index_rows = {}
for line in read("library/INDEX.md").splitlines():
    cells = [c.strip() for c in line.strip().strip("|").split("|")]
    if len(cells) == 4 and re.fullmatch(r"[a-z][a-z0-9-]*", cells[0]) and cells[0] != "skill":
        index_rows[cells[0]] = {u.strip() for u in cells[1].split(",")}
folders = {d.name for d in LIB.iterdir() if d.is_dir()}
for name in sorted(folders - set(index_rows)):
    err(f"library/{name}/ has no row in library/INDEX.md")
for name in sorted(set(index_rows) - folders):
    err(f"library/INDEX.md lists {name}, but library/{name}/ is missing")
for name in sorted(folders):
    if not (LIB / name / "SKILL.md").is_file():
        err(f"library/{name}/ has no SKILL.md")
for path in agent_files:
    text = path.read_text(encoding="utf-8")
    m = re.search(r"^## Library\n(.*?)(?=^## |^---$)", text, re.S | re.M)
    agent = path.stem
    used = set(re.findall(r"`([a-z0-9-]+)`", m.group(1).split("|---|---|", 1)[1])) if m else set()
    if m and LIB_RULE not in m.group(1):
        err(f"{path.relative_to(ROOT)}: the Library precedence rule differs from the other agents'")
    if m and text.count("LIBRARY: <skill used, or none>") != len(re.findall(r"^STATUS: ", text, re.M)):
        err(f"{path.relative_to(ROOT)}: every report template needs a `LIBRARY:` line under STATUS (T2 of the 18th run had nowhere to say it)")
    if m and LIB_READ not in text:
        err(f"{path.relative_to(ROOT)}: the read-first Library check is missing or differs (T2 of the 18th run: ux never opened its skill without it)")
    for name in sorted(used - set(index_rows)):
        err(f"{path.relative_to(ROOT)}: Library names `{name}`, which library/INDEX.md does not list")
    for name, users in sorted(index_rows.items()):
        if agent in users and name not in used:
            err(f"library/INDEX.md says {agent} reads {name}, but agents/{agent}.md does not list it")
        if agent not in users and name in used:
            err(f"agents/{agent}.md lists {name}, but its library/INDEX.md row does not name {agent}")
for name, users in sorted(index_rows.items()):
    unknown = users - {p.stem for p in agent_files} - {"orchestrator", "maintainer"}
    if unknown:
        err(f"library/INDEX.md row {name}: unknown reader(s) {sorted(unknown)}")

with tempfile.TemporaryDirectory() as tmp:
    for _ in range(2):  # the second run refreshes over an existing copy
        res = subprocess.run(["/bin/bash", str(ROOT / "hooks/session-start.sh")], cwd=tmp, capture_output=True, text=True)
    copied = Path(tmp) / ".agent/library"
    if res.returncode != 0 or not (copied / "INDEX.md").is_file() or not (copied / "runbook-generator/SKILL.md").is_file():
        err("session-start.sh did not copy library/ into .agent/library/")
    elif (copied / ".gitignore").read_text() != "*\n":
        err("session-start.sh: .agent/library/.gitignore must hold `*` so the copy is never committed")

# ---------------------------------------------------------------------------
for w in warnings:
    print(f"WARN  {w}")
for e in errors:
    print(f"ERROR {e}")
print(f"\n{len(errors)} error(s), {len(warnings)} warning(s)")
sys.exit(1 if errors else 0)
