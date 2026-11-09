#!/usr/bin/env node
'use strict';
// Benchmark tool for agent-team. Zero dependencies; Node >= 18.
//   node bench/bench.js setup <dir>              make a fresh copy of the seed project (git repo, one commit)
//   node bench/bench.js prompt f1|f2             print the request to give the plugin
//   node bench/bench.js grade <dir> f1|f2        run the hidden cases (f2 also re-runs f1) and the project's own tests
//   node bench/bench.js measure <stream.jsonl>...  time, cost, tokens, models and Agent calls of headless runs
//   node bench/bench.js selftest                 prove the seed, grader and references behave as recorded
//   node bench/bench.js fingerprint [--write]    hash of the seed (LF-normalised)
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const crypto = require('node:crypto');
const { spawnSync } = require('node:child_process');

const HERE = __dirname;
const SEED = path.join(HERE, 'seed');
const FP_FILE = path.join(HERE, 'seed.sha256');

function walk(dir, base = dir) {
  const out = [];
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    if (e.name === 'node_modules' || e.name === '.git') continue;
    const p = path.join(dir, e.name);
    if (e.isDirectory()) out.push(...walk(p, base));
    else out.push(path.relative(base, p).split(path.sep).join('/'));
  }
  return out.sort();
}

const lf = (s) => s.replace(/\r\n/g, '\n');

function fingerprint(dir = SEED) {
  const h = crypto.createHash('sha256');
  for (const f of walk(dir)) {
    h.update(`${f}\n`);
    h.update(lf(fs.readFileSync(path.join(dir, f), 'utf8')));
    h.update('\n--\n');
  }
  return h.digest('hex');
}

function git(dir, args, env = {}) {
  const r = spawnSync('git', args, { cwd: dir, encoding: 'utf8', env: { ...process.env, ...env } });
  if (r.status !== 0) throw new Error(`git ${args.join(' ')}: ${r.stderr}`);
  return r.stdout.trim();
}

function setup(dir) {
  if (fs.existsSync(dir) && fs.readdirSync(dir).length > 0) throw new Error(`${dir} is not empty`);
  const expected = fs.existsSync(FP_FILE) ? fs.readFileSync(FP_FILE, 'utf8').trim() : null;
  const got = fingerprint();
  if (expected && expected !== got) throw new Error(`seed changed: expected ${expected}, got ${got}. Re-baseline on purpose with: fingerprint --write`);
  for (const f of walk(SEED)) {
    const to = path.join(dir, f);
    fs.mkdirSync(path.dirname(to), { recursive: true });
    fs.writeFileSync(to, lf(fs.readFileSync(path.join(SEED, f), 'utf8')));
  }
  const when = '2026-01-01T00:00:00+00:00';
  git(dir, ['init', '-q']);
  git(dir, ['config', 'user.name', 'bench']);
  git(dir, ['config', 'user.email', 'bench@example.invalid']);
  git(dir, ['config', 'core.autocrlf', 'false']);
  git(dir, ['add', '-A']);
  git(dir, ['commit', '-q', '-m', 'seed'], { GIT_AUTHOR_DATE: when, GIT_COMMITTER_DATE: when });
  return { dir, fingerprint: got, commit: git(dir, ['rev-parse', 'HEAD']) };
}

function runOwnTests(dir) {
  const r = spawnSync('node', ['--test', 'tests/**/*.test.js'], { cwd: dir, encoding: 'utf8', shell: false });
  const out = `${r.stdout}\n${r.stderr}`;
  const num = (k) => Number((out.match(new RegExp(`^ℹ ${k} (\\d+)`, 'm')) || [])[1] || 0);
  return { tests: num('tests'), pass: num('pass'), fail: num('fail') };
}

function grade(dir, feature) {
  const root = path.resolve(dir);
  for (const k of Object.keys(require.cache)) if (k.startsWith(root)) delete require.cache[k];
  const all = require(path.join(HERE, 'hidden', 'cases.js'))(root);
  const list = feature === 'f1' ? all.f1.map((c) => ({ ...c, feature: 'f1' })) : [...all.f1.map((c) => ({ ...c, feature: 'f1' })), ...all.f2.map((c) => ({ ...c, feature: 'f2' }))];
  const cases = [];
  for (const c of list) {
    let error = null;
    try { c.run(); } catch (e) { error = String(e && e.message ? e.message : e).split('\n')[0].slice(0, 160); }
    cases.push({ feature: c.feature, name: c.name, tags: c.tags, pass: error === null, error });
  }
  const byTag = {};
  for (const c of cases) for (const t of c.tags) {
    const k = `${c.feature}:${t}`;
    byTag[k] = byTag[k] || { passed: 0, total: 0 };
    byTag[k].total += 1;
    if (c.pass) byTag[k].passed += 1;
  }
  const byFeature = {};
  for (const c of cases) {
    byFeature[c.feature] = byFeature[c.feature] || { passed: 0, total: 0 };
    byFeature[c.feature].total += 1;
    if (c.pass) byFeature[c.feature].passed += 1;
  }
  const own = runOwnTests(root);
  const ok = cases.every((c) => c.pass) && own.fail === 0 && own.tests > 0;
  return { feature, ok, byFeature, byTag, ownTests: own, cases };
}

function measure(files) {
  const out = [];
  for (const f of files) {
    let cost = 0, ms = 0, usage = null, models = null;
    const calls = [];
    for (const line of fs.readFileSync(f, 'utf8').split('\n')) {
      let e; try { e = JSON.parse(line); } catch { continue; }
      if (e.type === 'result') { cost = Math.max(cost, e.total_cost_usd || 0); ms += e.duration_ms || 0; usage = e.usage || usage; models = e.modelUsage || models; }
      if (e.type === 'assistant') for (const c of e.message.content) if (c.type === 'tool_use' && c.name === 'Agent') {
        calls.push({ agent: c.input.subagent_type, model: c.input.model || 'default', background: c.input.run_in_background !== false });
      }
    }
    const tokens = {};
    for (const [m, u] of Object.entries(models || {})) tokens[m] = (u.inputTokens || 0) + (u.outputTokens || 0) + (u.cacheReadInputTokens || 0) + (u.cacheCreationInputTokens || 0);
    out.push({ file: path.basename(f), minutes: +(ms / 60000).toFixed(2), costUsd: +cost.toFixed(4), tokensByModel: tokens, agentCalls: calls.length, notForeground: calls.filter((c) => c.background).length, calls });
  }
  return out;
}

function selftest() {
  const results = [];
  const check = (name, ok, detail = '') => { results.push(ok); console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}${detail ? ` — ${detail}` : ''}`); };
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'bench-'));
  const overlay = (dir, ref) => fs.cpSync(path.join(HERE, 'reference', ref), dir, { recursive: true });
  const expected = fs.existsSync(FP_FILE) ? fs.readFileSync(FP_FILE, 'utf8').trim() : '(none)';
  check('seed fingerprint matches seed.sha256', fingerprint() === expected, fingerprint().slice(0, 12));

  const a = setup(path.join(tmp, 'a')), b = setup(path.join(tmp, 'b'));
  check('two fresh setups give the same commit', a.commit === b.commit, a.commit.slice(0, 12));
  const seedOwn = runOwnTests(a.dir);
  check('the seed passes its own tests', seedOwn.fail === 0 && seedOwn.tests > 0, `${seedOwn.pass}/${seedOwn.tests}`);
  const g0 = grade(a.dir, 'f1');
  check('on the seed no hidden F1 case passes', g0.byFeature.f1.passed === 0, `${g0.byFeature.f1.passed}/${g0.byFeature.f1.total}`);

  overlay(a.dir, 'f1');
  const g1 = grade(a.dir, 'f1');
  check('reference F1 passes every F1 case and its own tests', g1.ok, `${g1.byFeature.f1.passed}/${g1.byFeature.f1.total}, own ${g1.ownTests.pass}/${g1.ownTests.tests}`);
  const g1b = grade(a.dir, 'f1');
  check('grading the same code twice gives identical results', JSON.stringify(g1) === JSON.stringify(g1b));

  overlay(a.dir, 'f2');
  const g2 = grade(a.dir, 'f2');
  check('reference F2 passes F1 + F2 and its own tests', g2.ok, `${g2.byFeature.f1.passed + g2.byFeature.f2.passed}/${g2.byFeature.f1.total + g2.byFeature.f2.total}, own ${g2.ownTests.pass}/${g2.ownTests.tests}`);

  overlay(b.dir, 'f1');
  const inv = path.join(b.dir, 'src', 'invoices.js');
  fs.writeFileSync(inv, fs.readFileSync(inv, 'utf8').replace('const satang = toSatang(amount);', 'const satang = Math.floor(parseFloat(amount) * 100);'));
  const gn = grade(b.dir, 'f1');
  const ft = gn.byTag['f1:float-money'], sv = gn.byTag['f1:stale-version'];
  check('a float-money mistake is caught by the float-money cases and not by the stale-version ones', ft.passed < ft.total && sv.passed === sv.total && !gn.ok, `float-money ${ft.passed}/${ft.total}, stale-version ${sv.passed}/${sv.total}`);

  fs.rmSync(tmp, { recursive: true, force: true });
  const ok = results.every(Boolean);
  console.log(ok ? '\nselftest: all good' : '\nselftest: FAILED');
  return ok;
}

const [cmd, ...args] = process.argv.slice(2);
try {
  if (cmd === 'setup') console.log(JSON.stringify(setup(path.resolve(args[0])), null, 2));
  else if (cmd === 'prompt') process.stdout.write(fs.readFileSync(path.join(HERE, 'requests', `${args[0]}.md`), 'utf8'));
  else if (cmd === 'grade') {
    const r = grade(args[0], args[1]);
    console.log(JSON.stringify(r, null, 2));
    process.exitCode = r.ok ? 0 : 1;
  } else if (cmd === 'measure') console.log(JSON.stringify(measure(args), null, 2));
  else if (cmd === 'selftest') process.exitCode = selftest() ? 0 : 1;
  else if (cmd === 'fingerprint') {
    const fp = fingerprint();
    if (args[0] === '--write') fs.writeFileSync(FP_FILE, `${fp}\n`);
    console.log(fp);
  } else { console.error('usage: setup <dir> | prompt f1|f2 | grade <dir> f1|f2 | measure <files> | selftest | fingerprint [--write]'); process.exitCode = 2; }
} catch (e) { console.error(`bench: ${e.message}`); process.exitCode = 2; }
