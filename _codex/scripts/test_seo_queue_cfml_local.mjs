#!/usr/bin/env node
// Runs copied production templates with isolated auth variables and the real admin guard.
// No Application.cfc, datasource, credentials, production requests, or software downloads.
// CLI CGI is readonly: this checks include denial, not HTTP status/POST or session login.
// Pass one or more scenario names to split JVM work into bounded invocations; --list lists them.
import assert from 'node:assert/strict';
import { appendFileSync, copyFileSync, existsSync, mkdirSync, mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const templates = ['portal/conteudo/seo.cfm', 'portal/includes/seo_queue_backend.cfm', 'portal/includes/seo_queue_data.cfm',
  'portal/conteudo/seo_report.cfm', 'portal/includes/seo_score_backend.cfm', 'portal/includes/seo_score_data.cfm'];
const cases = ['contract', 'resolved-contract', ...templates.flatMap((_, index) => [`anonymous-${index}`, `effective-denied-${index}`]),
  'render-all', 'render-filtered', 'render-empty', 'render-escaped', 'invalid-urls',
  'score-contract', 'score-invalid-data', 'render-score-filtered', 'render-score-escaped'];
const requested = process.argv.slice(2);
if (requested.includes('--list')) { console.log(cases.join('\n')); process.exit(0); }
for (const name of requested) assert.ok(cases.includes(name), `Unknown CFML scenario: ${name}. Use --list.`);
const selected = new Set(requested.length ? requested : cases);
function scenario(name, check) { if (selected.has(name)) check(); }
const requiredTemplates = [...selected].some(name => name.startsWith('render-')) ? templates
  : [...new Set([templates[1], templates[2], templates[4], templates[5],
      ...[...selected].filter(name => /^(anonymous|effective-denied)-\d+$/.test(name)).map(name => templates[Number(name.match(/\d+$/)[0])])])];
for (const name of requiredTemplates) assert.ok(existsSync(resolve(root, name)), `SEO queue template must exist before its CFML behavior can pass: ${name}`);
const box = process.env.SEO_QUEUE_CFML_BOX_RUNTIME || '/Users/Shared/Projects/ColdFusion Certification/box';
const runtimeHome = process.env.SEO_QUEUE_CFML_COMMANDBOX_HOME || '/private/tmp/runnerhub-audience-cfml.j0MZzV/commandbox';
const java = process.env.SEO_QUEUE_CFML_JAVA_RUNTIME || '/usr/bin/java';
for (const path of [box, java, resolve(runtimeHome, 'lib/lucee-5.3.10.120.jar')]) {
  assert.ok(existsSync(path), `Existing local CFML runtime required: ${path}. This test never installs software.`);
}
const scratch = mkdtempSync(resolve(tmpdir(), 'seo-queue-cfml-'));
const output = mkdtempSync(resolve(tmpdir(), 'seo-queue-render-'));
let passed = 0;

function execute(name, variables = '') {
  const filename = `${name}.cfm`;
  writeFileSync(resolve(scratch, filename), `<cfset VARIABLES.seoTestCase="${name}"/>\n${variables}\n<cfinclude template="fixture.cfm"/>`);
  const result = spawnSync(java, ['-Dfile.encoding=UTF-8', '-Dsun.stdout.encoding=UTF-8', '-cp', box,
    'cliloader.LoaderCLIMain', `-CommandBox_home=${runtimeHome}`, 'execute', filename], {
    cwd: scratch, encoding: 'utf8', timeout: 60000, maxBuffer: 4 * 1024 * 1024,
    env: { PATH: process.env.PATH, LC_ALL: 'en_US.UTF-8', TMPDIR: tmpdir(), RUNNERHUB_OFFLINE_CFML_TESTS: '1' }
  });
  assert.equal(result.status, 0, `CFML execution failed (${name}): ${result.error || ''}\n${result.stdout || ''}\n${result.stderr || ''}`);
  return result.stdout;
}

function readScoreMetadata(html) {
  const match = html.match(/<!-- SEO_SCORE_RENDER_DATA:([A-Za-z0-9+/=]+) -->/);
  assert.ok(match, 'Rendered tests must retain source score metadata for comparison');
  const normalize = value => Array.isArray(value) ? value.map(normalize)
    : value && typeof value === 'object' ? Object.fromEntries(Object.entries(value).map(([key, child]) => [key.toLowerCase(), normalize(child)])) : value;
  return normalize(JSON.parse(Buffer.from(match[1], 'base64').toString('utf8')));
}

try {
  for (const name of [...templates.filter(name => existsSync(resolve(root, name))), 'includes/backend/require_admin.cfm']) {
    mkdirSync(dirname(resolve(scratch, name)), { recursive: true });
    copyFileSync(resolve(root, name), resolve(scratch, name));
  }
  copyFileSync(resolve(root, '_codex/tests/seo_queue_cfml.cfm'), resolve(scratch, 'fixture.cfm'));
  // Synthetic resolution states exercise the optional field without changing curated data.
  appendFileSync(resolve(scratch, 'portal/includes/seo_queue_data.cfm'), `\n<cfscript>
if (VARIABLES.seoTestCase EQ "contract") {
    for (seoTestItem in VARIABLES.seoQueueSnapshot.items) structDelete(seoTestItem,"resolved");
}
if (VARIABLES.seoTestCase EQ "resolved-contract") {
    for (seoTestItem in VARIABLES.seoQueueSnapshot.items) seoTestItem.resolved = seoTestItem.id EQ "RR-02";
}
</cfscript>\n`);
  appendFileSync(resolve(scratch, 'portal/includes/seo_score_data.cfm'), `\n<cfscript>
if (structKeyExists(VARIABLES,"seoTestScoreInvalidUrl")) {
    VARIABLES.seoScoreSnapshot.sites[1].criteria[1].cases.pass = [VARIABLES.seoTestScoreInvalidUrl];
}
if (structKeyExists(VARIABLES,"seoTestScoreInvalidStatus")) {
    VARIABLES.seoScoreSnapshot.sites[1].criteria[1].status = VARIABLES.seoTestScoreInvalidStatus;
}
if (VARIABLES.seoTestCase EQ "render-score-escaped") {
    VARIABLES.seoScoreSnapshot.sites[1].criteria[1].label = "<script>seoScoreXss()</script>";
    VARIABLES.seoScoreSnapshot.sites[1].criteria[1].cases.pass = ["https://roadrunners.run/evidence?a=1&b=2"];
}
</cfscript>\n`);
  scenario('contract', () => {
  const contract = execute('contract');
  assert.match(contract, /SEO_QUEUE_CONTRACT_PASSED:\d+/, `Backend contract failed:\n${contract}`);
  process.stdout.write(`${contract.trim()}\n`);
  passed++;
  });

  scenario('resolved-contract', () => {
  const resolved = execute('resolved-contract');
  assert.match(resolved, /SEO_QUEUE_RESOLVED_PASSED:10/, `Resolved queue issue contract failed:\n${resolved}`);
  process.stdout.write(`${resolved.trim()}\n`);
  passed++;
  });

  for (const [index, template] of templates.entries()) {
    for (const mode of ['anonymous', 'effective-denied']) {
      if (!selected.has(`${mode}-${index}`)) continue;
      const html = execute(`${mode}-${index}`, `<cfset VARIABLES.seoTestTarget="${template}"/>`);
      assert.match(html, /Acesso restrito/, `${mode}: direct ${template} must be refused by the real guard`);
      assert.doesNotMatch(html, /SEO_QUEUE_ACCESS_GRANTED|RR-01|events-upcoming-1\.xml|2026-09-13T18-/, 'Denied templates must not expose queue data or continue execution');
      passed++;
    }
  }

  scenario('render-all', () => {
  const html = execute('render-all');
  assert.match(html, /SEO_QUEUE_RENDER_PASSED/, `View failed to compile or render:\n${html}`);
  for (const id of ['RR-01', 'RR-02', 'RR-03', 'RR-04', 'OR-01', 'SH-01', 'OR-02']) {
    assert.ok(html.includes(id), `Rendered queue must identify ${id}`);
  }
  const metadata = html.match(/<!-- SEO_QUEUE_RENDER_DATA:([A-Za-z0-9+/=]+) -->/);
  assert.ok(metadata, 'Rendered test output must retain its source audit metadata');
  const renderData = JSON.parse(Buffer.from(metadata[1], 'base64').toString('utf8'));
  const source = Object.fromEntries(Object.entries(renderData).map(([key, value]) => [key.toLowerCase(), value]));
  const auditCards = [...html.matchAll(/<section class="[^"]*\bseo-run\b[^"]*"[\s\S]*?<\/section>/g)].map(match => match[0]);
  assert.equal(auditCards.length, source.runs.length, 'Each site audit must have its own card');
  for (const [index, rawRun] of source.runs.entries()) {
    const run = Object.fromEntries(Object.entries(rawRun).map(([key, value]) => [key.toLowerCase(), value]));
    const expectedCount = new Intl.NumberFormat('pt-BR').format(run.discovered);
    assert.ok(auditCards[index].includes(source.auditlabels[index]), `${run.label}: the card must show its own audit date`);
    assert.ok(auditCards[index].includes(`URLs coletadas</dt><dd>${expectedCount}</dd>`), `${run.label}: collected URLs must retain their value with Brazilian formatting`);
    assert.ok(auditCards[index].includes(run.discoverycomplete ? 'Descoberta completa dos sitemaps' : 'Cobertura incompleta'), `${run.label}: discovery coverage must reflect its own status`);
  }
  assert.doesNotMatch(html, /href\s*=\s*["'](?:javascript:|file:|data:)/i, 'Evidence links cannot use active or local protocols');
  const scoreData = readScoreMetadata(html);
  assert.equal(scoreData.sites.length, 2, 'Report must contain a separate score for each site');
  assert.equal((html.match(/class="seo-score-value"/g) || []).length, 2, 'Each site needs one visible score');
  for (const site of scoreData.sites) {
    assert.ok(html.includes(site.scorelabel), `${site.id}: its source score must appear in the report`);
    assert.ok(html.includes(`class="seo-history" data-seo-site="${site.id}"`), `${site.id}: its dated history must be visible`);
    assert.ok(html.includes(`data-seo-site="${site.id}"`), `${site.id}: the source must have a distinct report section`);
  }
  for (const status of ['pass', 'warning', 'error', 'unknown']) {
    assert.match(html, new RegExp(`data-seo-status="${status}"`), `Real data must show ${status} checks`);
    const label = scoreData.statuses.find(item => item.id === status);
    assert.ok(label && html.includes(label.label), `${status}: checks need visible escaped status text`);
    assert.ok(html.includes(label.icon), `${status}: checks need a visible icon in addition to color`);
  }
  assert.match(html, /amostra/i, 'The report must disclose its sampled coverage');
  assert.match(html, /Google/, 'The report must explain that its internal score is not Google indexing evidence');
  writeFileSync(resolve(output, 'seo-queue.html'), html);
  passed++;
  });

  scenario('render-filtered', () => {
  const filtered = execute('render-filtered');
  assert.match(filtered, /SEO_QUEUE_RENDER_PASSED/);
  assert.ok(filtered.includes('SH-01'), 'Shared issue remains visible when filtering OpenResults/P3');
  assert.ok(!filtered.includes('RR-01'), 'Unselected P1 issues cannot appear in filtered cards');
  writeFileSync(resolve(output, 'seo-queue-filtered.html'), filtered);
  passed++;
  });

  scenario('render-empty', () => {
  const empty = execute('render-empty');
  assert.match(empty, /SEO_QUEUE_RENDER_PASSED/);
  assert.match(empty, /Nenhum|Nenhuma/i, 'Empty filter selection must explain the absence of matching items');
  assert.doesNotMatch(empty, /RR-01|RR-02|OR-01|SH-01/, 'Empty selection must not retain stale cards');
  writeFileSync(resolve(output, 'seo-queue-empty.html'), empty);
  passed++;
  });

  // Extend only the scratch data include, retaining its real authorization guard.
  appendFileSync(resolve(scratch, 'portal/includes/seo_queue_data.cfm'), `\n<cfscript>
if (structKeyExists(VARIABLES,"seoTestMaliciousUrl")) {
    VARIABLES.seoQueueSnapshot.items[1].urls[1].url = VARIABLES.seoTestMaliciousUrl;
}
if (VARIABLES.seoTestCase EQ "render-escaped") {
    VARIABLES.seoQueueSnapshot.items[1].title = "<script>seoQueueXss()</script>";
    VARIABLES.seoQueueSnapshot.items[1].evidence = "<img src=x onerror=seoQueueXss()>";
    VARIABLES.seoQueueSnapshot.items[1].urls[1].label = "<svg onload=seoQueueXss()>";
    VARIABLES.seoQueueSnapshot.items[1].urls[1].url = "https://roadrunners.run/evidence?a=1&b=2";
}
</cfscript>\n`);
  scenario('render-escaped', () => {
  const escaped = execute('render-escaped');
  assert.match(escaped, /SEO_QUEUE_RENDER_PASSED/);
  assert.match(escaped, /&lt;script&gt;/, 'Evidence titles must remain visible as escaped text');
  assert.match(escaped, /seoQueueXss/, 'The escaping scenario must actually reach the rendered view');
  assert.doesNotMatch(escaped, /<script>seoQueueXss|<img src=x|<svg onload/i, 'Untrusted title, evidence, and link label cannot render active HTML');
  assert.doesNotMatch(escaped, /href="[^"]*&b=2/, 'Query separators must be escaped inside link attributes');
  writeFileSync(resolve(output, 'seo-queue-escaped.html'), escaped);
  passed++;
  });

  scenario('invalid-urls', () => {
  const rejectedUrls = execute('invalid-urls');
  assert.match(rejectedUrls, /SEO_QUEUE_INVALID_URLS_PASSED:7/, `Malformed evidence URLs must fail closed:\n${rejectedUrls}`);
  passed++;
  });

  scenario('score-contract', () => {
    const result = execute('score-contract');
    assert.match(result, /SEO_SCORE_CONTRACT_PASSED:\d+/, `Score/filter contract failed:\n${result}`);
    process.stdout.write(`${result.trim()}\n`);
    passed++;
  });

  scenario('score-invalid-data', () => {
    const result = execute('score-invalid-data');
    assert.match(result, /SEO_SCORE_INVALID_DATA_PASSED:9/, `Unsafe score data must fail closed:\n${result}`);
    process.stdout.write(`${result.trim()}\n`);
    passed++;
  });

  scenario('render-score-filtered', () => {
    const html = execute('render-score-filtered');
    assert.match(html, /SEO_QUEUE_RENDER_PASSED/);
    const data = readScoreMetadata(html);
    assert.equal(data.filter, 'error', 'The check filter must retain its valid selection');
    const statuses = [...html.matchAll(/data-seo-status="([a-z]+)"/g)].map(match => match[1]);
    assert.ok(statuses.length > 0, 'The real Road Runners error must remain visible');
    assert.ok(statuses.every(status => status === 'error'), 'Status filtering must apply to the rendered checklist');
    for (const site of data.sites) {
      assert.ok(html.includes(site.scorelabel), `${site.id}: filtering must leave its score visible`);
    }
    assert.ok(html.includes('RR-01') && html.includes('SH-01'), 'Filtering checks must leave the correction queue intact');
    writeFileSync(resolve(output, 'seo-score-filtered.html'), html);
    passed++;
  });

  scenario('render-score-escaped', () => {
    const html = execute('render-score-escaped');
    assert.match(html, /SEO_QUEUE_RENDER_PASSED/);
    assert.match(html, /&lt;script&gt;seoScoreXss/, 'Criterion labels must be rendered as escaped text');
    assert.doesNotMatch(html, /<script>seoScoreXss/, 'Criterion labels cannot render active HTML');
    assert.match(html, /href="[^"]*roadrunners[^"]*evidence[^"]*"/i, 'Escaped evidence must still be rendered as a link');
    assert.doesNotMatch(html, /href="[^"]*&b=2/, 'Score evidence query separators must be escaped inside attributes');
    writeFileSync(resolve(output, 'seo-score-escaped.html'), html);
    passed++;
  });

  mkdirSync(resolve(output, 'assets/css'), { recursive: true });
  for (const name of ['mdb.min.css', 'business-ui.css']) {
    if (existsSync(resolve(root, 'assets/css', name))) copyFileSync(resolve(root, 'assets/css', name), resolve(output, 'assets/css', name));
  }
  assert.equal(passed, selected.size, 'Every selected scenario must execute its full assertions');
  console.log(`SEO queue CFML: ${passed} execution scenarios passed.\nHTML: ${resolve(output, 'seo-queue.html')}`);
} finally {
  rmSync(scratch, { recursive: true, force: true });
}
