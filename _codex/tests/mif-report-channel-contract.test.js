const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');

const reportRoot = path.resolve(
  __dirname,
  '..',
  '..',
  'relatorios',
  'maratona-floripa-2026',
);
const indexPath = path.join(reportRoot, 'canais', 'index.cfm');
const dossierPath = path.join(reportRoot, 'canais', 'dossie.cfm');
const rendererPath = path.join(reportRoot, 'assets', 'report.js');

test('channel index reads only the index and renders commercial DESC order', () => {
  const page = fs.readFileSync(indexPath, 'utf8');
  const renderer = fs.readFileSync(rendererPath, 'utf8');

  assert.match(page, /includes\/auth\.cfm/i);
  assert.match(page, /includes\/data\.cfm/i);
  assert.deepEqual(
    [...page.matchAll(/mifReadDataset\(\s*["']([^"']+)["']\s*\)/gi)].map((match) => match[1]),
    ['channels/index.json'],
  );
  assert.match(page, /MifReport\.renderChannelIndex/i);
  assert.match(renderer, /sortChannelsByGross/i);
  assert.match(renderer, /encodeURIComponent/i);
  assert.match(renderer, /dossie\.cfm\?canal=/i);
  assert.doesNotMatch(page, /class=["']report-back["']/i);
  assert.match(page, /class=["']button["'][^>]+href=["']\.\.\/["'][^>]*>← Análise geral</i);
});

test('channel pages keep the general-analysis action and add one portfolio action on the right', () => {
  for (const pagePath of [indexPath, dossierPath]) {
    const page = fs.readFileSync(pagePath, 'utf8');
    const actions = page.match(/<div class=["']report-actions["']>[\s\S]*?<\/div>/i)?.[0] || '';

    assert.match(actions, /class=["']button["'][^>]+href=["']\.\.\/["'][^>]*>← Análise geral<\/a>/i);
    assert.equal((actions.match(/>Portfólio 2027<\/a>/gi) || []).length, 1);
    assert.match(actions, /class=["']button["'][^>]+href=["']\.\.\/portfolio\/["'][^>]*>Portfólio 2027<\/a>/i);
    assert.equal((page.match(/>Portfólio 2027<\/a>/gi) || []).length, 1);
    assert.doesNotMatch(page, /class=["']report-back["']/i);
  }
});

test('dossier validates the slug against the manifest and loads one file', () => {
  const page = fs.readFileSync(dossierPath, 'utf8');

  assert.match(page, /\^\[a-z0-9-\]\+\$/i);
  assert.match(page, /channels\//i);
  assert.match(page, /\.json/i);
  assert.match(page, /mifReportManifest\.artifacts/i);
  assert.match(page, /structKeyExists/i);
  assert.match(page, /mifReadDataset\(VARIABLES\.mifChannelDatasetPath\)/i);
  assert.equal((page.match(/mifReadDataset\(/gi) || []).length, 1);
  assert.match(page, /statuscode=["']404["']/i);
  assert.doesNotMatch(page, /mifReportDataRoot/i);
});

test('dossier declares all seven sections, recommendation and print controls', () => {
  const page = fs.readFileSync(dossierPath, 'utf8');
  const sections = [
    'canal-resumo',
    'canal-ciclo',
    'canal-distancias-lotes',
    'canal-territorios',
    'canal-produtos',
    'canal-cupons',
    'canal-recomendacao',
  ];
  for (const section of sections) assert.match(page, new RegExp(`#${section}`));

  assert.match(page, /MifReport\.renderChannel/i);
  assert.match(page, /window\.print\s*\(/i);
  assert.match(page, /application\/json/i);
  assert.match(page, /replace\([^\n]+["']<\/["'][^\n]+["']<\\\/["']/i);
  assert.match(page, /assets\/report\.css/i);
  assert.match(page, /assets\/report\.js/i);
  const remoteAssets = [...page.matchAll(/(?:src|href)=["'](https?:\/\/[^"']+)["']/gi)]
    .map((match) => match[1]);
  assert.equal(remoteAssets.length, 3);
  assert.ok(remoteAssets.every((url) => /^https:\/\/fonts\.(?:googleapis|gstatic)\.com(?:\/|$)/i.test(url)));
  assert.doesNotMatch(page, /class=["']report-back["']/i);
  assert.match(page, /class=["']button["'][^>]+href=["']\.\.\/["'][^>]*>← Análise geral</i);
  assert.match(page, /class=["']button["'][^>]+href=["']\.\/["'][^>]*>Todos os canais</i);
});

test('renderer preserves recommendation, small-sample warning and coupon table', () => {
  const renderer = fs.readFileSync(rendererPath, 'utf8');

  assert.match(renderer, /sample_qualification/i);
  assert.match(renderer, /amostra reduzida/i);
  assert.match(renderer, /recommendation\.category/i);
  assert.match(renderer, /coupon_code/i);
  assert.match(renderer, /alias_reason/i);
});
