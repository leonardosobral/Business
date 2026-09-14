import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, readFile, writeFile, lstat, readdir, rm, symlink, realpath, mkdir } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { createHash } from 'node:crypto';

// Loading lazily makes the first RED identify the missing public contract.
const report = await import('../scripts/seo_report.mjs').catch(error => {
  if (error.code !== 'ERR_MODULE_NOT_FOUND') throw error;
  return {};
});
function call(name, ...args) {
  assert.equal(typeof report[name], 'function', `Export obrigatório ausente: ${name}`);
  return report[name](...args);
}
const url = 'https://example.test/evento/a/';
const finding = (rule = 'canonical.missing', source = url) => ({
  site_id: 'roadrunners', source_url: source, rule_id: rule, severity: 'warning',
  evidence: { message: 'Canonical ausente' }, evaluated_at: '2026-09-13T10:00:00.000Z'
});
const observation = (overrides = {}) => ({
  source_url: url, status: 200, final_url: url, redirected: false,
  content_type: 'text/html; charset=utf-8', x_robots_tag: '', canonical_url: url,
  meta_robots: '', duration_ms: 12, error: '', initial_status: 200, redirects: [],
  html_evaluation: 'evaluated', robots_by_agent: {}, robots_policy: {},
  canonical_count: 1, canonical_urls: [url], canonical_invalid: false,
  title: 'Prova', h1_count: 1, skip_reason: null, error_code: null,
  evaluated_at: '2026-09-13T10:00:00.000Z', source_sitemaps: ['https://example.test/sitemap.xml'],
  lastmod: null, ...overrides
});
const run = (overrides = {}) => ({
  schema_version: 1, rules_version: '1', collector_version: '2.0.0',
  collector_hash: 'a'.repeat(64), site_id: 'roadrunners', run_id: '20260913T100000Z',
  base_url: 'https://example.test', sitemap_url: 'https://example.test/sitemap.xml',
  started_at: '2026-09-13T10:00:00.000Z', finished_at: '2026-09-13T10:00:01.000Z',
  mode: 'audit', scope: 'sample', completion: 'complete', discovery_complete: true,
  exit_code: 0, config_hash: 'b'.repeat(64), selection_hash: 'c'.repeat(64),
  selected_urls: [url], counts: { discovered: 1, selected: 1, inspected: 1, duplicates: 0, errors: 0, warnings: 0 },
  limits: { maxRunMs: 10000 }, sitemaps: [], errors: [], observations: [observation()], findings: [],
  ...overrides
});
async function temporary(t) {
  const directory = await mkdtemp(path.join(await realpath(tmpdir()), 'seo-report-test-'));
  t.after(() => rm(directory, { recursive: true, force: true }));
  return path.join(directory, 'reports');
}

test('comparison separates new, persistent, resolved and URLs outside the checked sample', () => {
  const previous = run({ findings: [finding(), finding('title.empty'), finding('h1.missing', 'https://example.test/b/')] });
  const current = run({ findings: [finding('title.empty'), finding('h1.multiple')], selection_hash: 'd'.repeat(64) });
  const diff = call('compareRuns', previous, current);
  assert.equal(diff.comparable, true);
  assert.deepEqual(diff.new.map(f => f.rule_id), ['h1.multiple']);
  assert.deepEqual(diff.persistent.map(f => f.rule_id), ['title.empty']);
  assert.deepEqual(diff.resolved.map(f => f.rule_id), ['canonical.missing']);
  assert.deepEqual(diff.not_rechecked.map(f => f.rule_id), ['h1.missing']);
});

test('a partial run never resolves previous findings even if its checked page succeeds', () => {
  const diff = call('compareRuns', run({ findings: [finding()] }), run({ completion: 'partial', exit_code: 1 }));
  assert.deepEqual(diff.resolved, []);
  assert.equal(diff.not_rechecked.length, 1);
});

test('resolution requires successful HTML evaluation, not just absence of a finding', () => {
  for (const change of [
    { html_evaluation: 'not_evaluated' }, { html_evaluation: 'failed' },
    { status: 500 }, { status: 0 }, { error: 'timeout' }, { error_code: 'timeout' },
    { skip_reason: 'skipped_robots' }, { content_type: 'application/pdf' }
  ]) {
    const diff = call('compareRuns', run({ findings: [finding()] }), run({ observations: [observation(change)] }));
    assert.equal(diff.resolved.length, 0, JSON.stringify(change));
    assert.equal(diff.not_rechecked.length, 1);
  }
  const head = call('compareRuns', run({ mode: 'head', findings: [finding()] }), run({ mode: 'head' }));
  assert.equal(head.resolved.length, 0);
});

test('site, mode, rules, schema and configuration changes keep previous findings unverified', () => {
  for (const change of [{ site_id: 'openresults' }, { mode: 'deep' }, { rules_version: '2' }, { schema_version: 2 }, { config_hash: 'd'.repeat(64) }, { config_hash: undefined }]) {
    const diff = call('compareRuns', run({ findings: [finding()] }), run({ findings: [finding('title.empty')], ...change }));
    assert.equal(diff.comparable, false, JSON.stringify(change));
    assert.equal(typeof diff.reason, 'string');
    assert.equal(diff.new.length, 1);
    assert.equal(diff.not_rechecked.length, 1);
    assert.equal(diff.resolved.length, 0);
  }
});

test('the initial baseline has new findings and no invented resolutions', () => {
  const diff = call('compareRuns', null, run({ findings: [finding()] }));
  assert.equal(diff.new.length, 1);
  assert.deepEqual(diff.resolved, []);
  assert.deepEqual(diff.persistent, []);
});

test('report round-trip verifies all payload hashes and preserves exact JSON observations', async t => {
  const root = await temporary(t);
  const original = run({ findings: [finding()] });
  const result = await call('writeReport', original, root);
  assert.equal(result.run_dir, path.join(root, original.site_id, original.run_id));
  const manifest = JSON.parse(await readFile(result.manifest_path, 'utf8'));
  assert.equal(Object.hasOwn(manifest, 'observations'), false);
  assert.equal(Object.hasOwn(manifest, 'findings'), false);
  assert.deepEqual(Object.keys(manifest.files).sort(), ['comparison.json', 'findings.json', 'inventory.csv', 'observations.jsonl', 'summary.md']);
  for (const [name, receipt] of Object.entries(manifest.files)) {
    const data = await readFile(path.join(result.run_dir, name));
    assert.equal(receipt.sha256, createHash('sha256').update(data).digest('hex'));
    assert.equal(receipt.bytes, data.length);
    assert.equal((await lstat(path.join(result.run_dir, name))).mode & 0o777, 0o600);
  }
  assert.equal((await lstat(root)).mode & 0o777, 0o700);
  assert.equal((await lstat(result.run_dir)).mode & 0o777, 0o700);
  assert.equal((await lstat(result.manifest_path)).mode & 0o777, 0o600);
  assert.deepEqual(await call('readReport', result.run_dir), original);
});

test('partial and failed reports preserve latest complete and compare against that verified baseline', async t => {
  const root = await temporary(t);
  const first = await call('writeReport', run({ findings: [finding()] }), root);
  const pointerPath = path.join(root, 'roadrunners', 'latest-complete.json');
  const pointer = await readFile(pointerPath, 'utf8');
  const partial = await call('writeReport', run({ run_id: 'partial-1', completion: 'partial', exit_code: 1 }), root);
  assert.equal(await readFile(pointerPath, 'utf8'), pointer);
  const partialDiff = JSON.parse(await readFile(path.join(partial.run_dir, 'comparison.json'), 'utf8'));
  assert.equal(partialDiff.not_rechecked.length, 1);
  assert.deepEqual(partialDiff.resolved, []);
  await call('writeReport', run({ run_id: 'failed-1', completion: 'failed', exit_code: 1 }), root);
  assert.equal(await readFile(pointerPath, 'utf8'), pointer);
  const complete = await call('writeReport', run({ run_id: 'complete-2' }), root);
  const diff = JSON.parse(await readFile(path.join(complete.run_dir, 'comparison.json'), 'utf8'));
  assert.equal(diff.resolved.length, 1);
  assert.equal(JSON.parse(await readFile(pointerPath, 'utf8')).run_id, 'complete-2');
  assert.ok(await readFile(first.manifest_path));
  assert.equal((await readdir(path.dirname(first.run_dir))).some(name => name.startsWith('.')), false);
});

test('a first partial report does not create latest-complete', async t => {
  const root = await temporary(t);
  await call('writeReport', run({ completion: 'partial', exit_code: 1 }), root);
  await assert.rejects(readFile(path.join(root, 'roadrunners', 'latest-complete.json')), { code: 'ENOENT' });
});

test('duplicate run IDs do not overwrite a published report', async t => {
  const root = await temporary(t);
  const first = await call('writeReport', run(), root);
  const before = await readFile(first.manifest_path, 'utf8');
  await assert.rejects(call('writeReport', run({ findings: [finding()] }), root), /exist|publicad|duplicad/i);
  assert.equal(await readFile(first.manifest_path, 'utf8'), before);
});

test('CSV retains ten legacy columns and neutralizes spreadsheet formulas without changing JSON', async t => {
  const root = await temporary(t);
  const original = run({ observations: [observation({ x_robots_tag: '=HYPERLINK("evil")', meta_robots: '\t+cmd', error: '@SUM(1,2)' })] });
  const result = await call('writeReport', original, root);
  const csv = await readFile(path.join(result.run_dir, 'inventory.csv'), 'utf8');
  assert.equal(csv.split('\n')[0].replaceAll('"', '').trim(), 'source_url,status,final_url,redirected,content_type,x_robots_tag,canonical_url,meta_robots,duration_ms,error');
  assert.ok(csv.includes('"\'=HYPERLINK(""evil"")"'));
  assert.ok(csv.includes('"\'\t+cmd"'));
  assert.ok(csv.includes('"\'@SUM(1,2)"'));
  assert.deepEqual((await call('readReport', result.run_dir)).observations, original.observations);
});

test('Markdown treats remote evidence as text and explicitly qualifies sampled coverage', async t => {
  const root = await temporary(t);
  const malicious = { ...finding(), source_url: 'javascript:alert(1)', evidence: { text: '<script>alert(1)</script>\n[clique](https://evil.test)\n# Falso', control: '\u001b[31m' } };
  const result = await call('writeReport', run({ findings: [malicious] }), root);
  const summary = await readFile(result.summary_path, 'utf8');
  assert.doesNotMatch(summary, /<script>|\[clique\]\(https:\/\/evil\.test\)|\n# Falso|\u001b/);
  assert.match(summary, /amostra/i);
  assert.match(summary, /indexa[çc][aã]o/i);
  assert.match(summary, /inspecionad|verificad/i);
  assert.doesNotMatch(summary, /\]\(javascript:/i);
});

test('tampering with any payload or manifest file map fails integrity checks', async t => {
  for (const name of ['observations.jsonl', 'inventory.csv', 'findings.json', 'summary.md', 'comparison.json']) {
    const root = await temporary(t);
    const result = await call('writeReport', run(), root);
    await writeFile(path.join(result.run_dir, name), 'tampered');
    await assert.rejects(call('readReport', result.run_dir), /integridade|hash|tamanho/i, name);
  }
  const root = await temporary(t);
  const result = await call('writeReport', run(), root);
  const manifest = JSON.parse(await readFile(result.manifest_path, 'utf8'));
  manifest.files['../outside.json'] = manifest.files['findings.json'];
  await writeFile(result.manifest_path, JSON.stringify(manifest));
  await assert.rejects(call('readReport', result.run_dir), /arquivo|caminho|manifesto/i);
});

test('invalid IDs, relative roots and traversal are rejected before artifacts are written', async t => {
  const root = await temporary(t);
  for (const change of [{ site_id: '../escape' }, { site_id: 'Bad/Site' }, { run_id: '../escape' }, { run_id: '.' }, { run_id: 'a/b' }]) {
    await assert.rejects(call('writeReport', run(change), root), /identificador|site_id|run_id/i);
  }
  await assert.rejects(call('writeReport', run(), 'relative/reports'), /absolut/i);
  await assert.rejects(call('writeReport', run(), path.join(root, '..') + '/reports/../escape'), /caminho|traversal/i);
  await assert.rejects(lstat(root), { code: 'ENOENT' });
});

test('symlink roots, ancestors, sites and report payloads are never followed', async t => {
  const root = await temporary(t);
  const parent = path.dirname(root);
  const external = path.join(parent, 'external');
  await mkdir(external);
  await symlink(external, root);
  await assert.rejects(call('writeReport', run(), root), /symlink|simb[oó]lic/i);
  await assert.rejects(call('writeReport', run(), path.join(root, 'child')), /symlink|simb[oó]lic/i);
  assert.deepEqual(await readdir(external), []);
  await rm(root);
  await mkdir(root);
  await symlink(external, path.join(root, 'roadrunners'));
  await assert.rejects(call('writeReport', run(), root), /symlink|simb[oó]lic/i);
  await rm(path.join(root, 'roadrunners'));
  const result = await call('writeReport', run(), root);
  const payload = path.join(result.run_dir, 'findings.json');
  const outsidePayload = path.join(external, 'findings.json');
  await writeFile(outsidePayload, await readFile(payload));
  await rm(payload);
  await symlink(outsidePayload, payload);
  await assert.rejects(call('readReport', result.run_dir), /symlink|simb[oó]lic/i);
});

test('an invalid or tampered latest pointer cannot silently become a new baseline', async t => {
  const root = await temporary(t);
  await call('writeReport', run(), root);
  const pointer = path.join(root, 'roadrunners', 'latest-complete.json');
  await writeFile(pointer, JSON.stringify({ run_id: '../escape', manifest_sha256: 'a'.repeat(64) }));
  await assert.rejects(call('writeReport', run({ run_id: 'next' }), root), /identificador|run_id|ponteiro/i);
  await assert.rejects(lstat(path.join(root, 'roadrunners', 'next')), { code: 'ENOENT' });
});

test('unrechecked findings survive several compatible rotating samples without contaminating raw observations', async t => {
  const root = await temporary(t);
  await call('writeReport', run({ findings: [finding()] }), root);
  const sampleB = { selected_urls: ['https://example.test/b/'], observations: [observation({ source_url: 'https://example.test/b/' })] };
  await call('writeReport', run({ ...sampleB, run_id: 'sample-b' }), root);
  const next = await call('writeReport', run({ ...sampleB, run_id: 'sample-b-again' }), root);
  const diff = JSON.parse(await readFile(path.join(next.run_dir, 'comparison.json'), 'utf8'));
  assert.equal(diff.not_rechecked.length, 1);
  assert.equal(diff.not_rechecked[0].source_url, url);
  assert.deepEqual((await call('readReport', next.run_dir)).findings, []);
  const recheck = await call('writeReport', run({ run_id: 'recheck-a' }), root);
  const resolved = JSON.parse(await readFile(path.join(recheck.run_dir, 'comparison.json'), 'utf8'));
  assert.equal(resolved.resolved.length, 1);
});

test('reserved pointer filename cannot be used as a run directory', async t => {
  const root = await temporary(t);
  await assert.rejects(call('writeReport', run({ run_id: 'latest-complete.json' }), root), /run_id|reservad/i);
  await assert.rejects(lstat(root), { code: 'ENOENT' });
});

test('operational failures precede findings and remain explicit when SEO error count is zero', async t => {
  const root = await temporary(t);
  const result = await call('writeReport', run({
    completion: 'partial', exit_code: 1, discovery_complete: false,
    findings: [finding()], counts: { discovered: 1, selected: 1, inspected: 1, duplicates: 0, errors: 0, warnings: 1 },
    errors: [
      { url: 'https://example.test/upcoming.xml', code: 'INVALID_SITEMAP', message: 'XML inválido' },
      { url: 'https://example.test/history.xml', code: 'TIMEOUT', message: 'Prazo excedido' }
    ]
  }), root);
  const text = await readFile(result.summary_path, 'utf8');
  const firstFinding = text.indexOf('## Achados novos');
  assert.ok(text.indexOf('## Erros operacionais') >= 0 && text.indexOf('## Erros operacionais') < firstFinding);
  assert.match(text.slice(0, firstFinding), /Erros SEO\/página: \*\*0\*\*/);
  assert.match(text.slice(0, firstFinding), /Erros operacionais: \*\*2\*\*/);
  assert.ok(text.slice(0, firstFinding).includes('INVALID\\_SITEMAP'));
  assert.ok(text.slice(0, firstFinding).includes('TIMEOUT'));
});
