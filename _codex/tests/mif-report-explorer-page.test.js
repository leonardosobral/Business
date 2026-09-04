const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');

const pagePath = path.resolve(
  __dirname,
  '..',
  '..',
  'relatorios',
  'maratona-floripa-2026',
  'explorador',
  'index.cfm',
);

test('explorer page authenticates and reads only the private explorer cube', () => {
  const page = fs.readFileSync(pagePath, 'utf8');

  assert.match(page, /includes\/auth\.cfm/i);
  assert.match(page, /includes\/data\.cfm/i);
  assert.deepEqual(
    [...page.matchAll(/mifReadDataset\(\s*["']([^"']+)["']\s*\)/gi)].map((match) => match[1]),
    ['explorer.json'],
  );
  assert.match(page, /application\/json/i);
  assert.match(page, /replace\([^\n]+["']<\/["'][^\n]+["']<\\\/["']/i);
});

test('page offers metric, one main dimension, one comparison and filters', () => {
  const page = fs.readFileSync(pagePath, 'utf8');

  assert.match(page, /id=["']explorer-metric["']/i);
  assert.match(page, /id=["']explorer-primary["']/i);
  assert.match(page, /id=["']explorer-comparison["']/i);
  assert.doesNotMatch(page, /explorer-third/i);
  for (const filter of ['phase', 'modality', 'lot', 'state', 'channel_name', 'product_name']) {
    assert.match(page, new RegExp(`data-filter=["']${filter}["']`, 'i'));
  }
});

test('page restores URL state, exposes validation, grain and share link', () => {
  const page = fs.readFileSync(pagePath, 'utf8');

  assert.match(page, /URLSearchParams/i);
  assert.match(page, /validateSelection/i);
  assert.match(page, /MifExplorer\.render/i);
  assert.match(page, /buildShareUrl/i);
  assert.match(page, /id=["']explorer-error["']/i);
  assert.match(page, /id=["']explorer-result["']/i);
  assert.match(page, /id=["']explorer-share["']/i);
  assert.match(page, /Grão|grão/);
  assert.match(page, /Cobertura|cobertura/);
});

test('explorer uses local report assets, public brand fonts and links to the static analysis', () => {
  const page = fs.readFileSync(pagePath, 'utf8');

  assert.match(page, /\.\.\/assets\/report\.css/i);
  assert.match(page, /\.\.\/assets\/explorer\.css/i);
  assert.match(page, /\.\.\/assets\/report\.js/i);
  assert.match(page, /\.\.\/assets\/explorer\.js/i);
  assert.match(page, /href=["']\/relatorios\/maratona-floripa-2026\/["']/i);
  const remoteAssets = [...page.matchAll(/(?:src|href)=["'](https?:\/\/[^"']+)["']/gi)]
    .map((match) => match[1]);
  assert.equal(remoteAssets.length, 3);
  assert.ok(remoteAssets.every((url) => /^https:\/\/fonts\.(?:googleapis|gstatic)\.com(?:\/|$)/i.test(url)));
  assert.doesNotMatch(page, /class=["']report-back["']/i);
  assert.match(page, /href=["']\/relatorios\/maratona-floripa-2026\/["'][^>]*>Visão geral</i);
  assert.match(page, /MifReport\.isVisibleLot/i);
});

test('explorer keeps the global action group and highlights itself', () => {
  const page = fs.readFileSync(pagePath, 'utf8');
  const actions = page.match(/<nav class=["']report-actions["'][^>]*>[\s\S]*?<\/nav>/i)?.[0] || '';

  assert.match(actions, /href=["']\/relatorios\/maratona-floripa-2026\/["'][^>]*>Visão geral<\/a>/i);
  assert.equal((actions.match(/>Portfólio 2027<\/a>/gi) || []).length, 1);
  assert.match(actions, /href=["']\/relatorios\/maratona-floripa-2026\/portfolio\/["'][^>]*>Portfólio 2027<\/a>/i);
  assert.match(actions, /button-current[^>]*aria-current=["']page["'][^>]*href=["']\/relatorios\/maratona-floripa-2026\/explorador\/["']/i);
  assert.equal((page.match(/>Portfólio 2027<\/a>/gi) || []).length, 1);
  assert.doesNotMatch(page, /class=["']report-back["']/i);
});
