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
  'index.cfm',
);
const reportRoot = path.dirname(pagePath);

test('general page authenticates before reading exactly three compact bundles', () => {
  const page = fs.readFileSync(pagePath, 'utf8');
  const reads = [...page.matchAll(/mifReadDataset\(\s*["']([^"']+)["']\s*\)/gi)]
    .map((match) => match[1]);

  assert.match(page, /includes\/auth\.cfm/i);
  assert.match(page, /includes\/data\.cfm/i);
  assert.deepEqual(reads.sort(), [
    'channels/index.json',
    'general.json',
    'strategy.json',
  ]);
  assert.doesNotMatch(page, /channels\/<|channels\/#|channels\/\$|channels\/(?!index\.json)[a-z0-9-]+\.json/i);
});

test('general page declares the eight editorial chapters and print action', () => {
  const page = fs.readFileSync(pagePath, 'utf8');
  const chapters = [
    'resumo-executivo',
    'ciclo-de-vendas',
    'distancias',
    'lotes-e-produtos',
    'territorios',
    'canais',
    'aprofundamento-canais',
    'recomendacoes-e-metodo',
  ];

  for (const chapter of chapters) {
    assert.match(page, new RegExp(`#${chapter}`));
  }
  assert.match(page, /window\.print\s*\(/i);
  assert.match(page, /MifReport\.renderGeneral/i);
});

test('general page embeds escaped JSON and limits remote assets to public brand fonts', () => {
  const page = fs.readFileSync(pagePath, 'utf8');

  assert.match(page, /application\/json/i);
  assert.match(page, /mif-report-data/i);
  assert.match(page, /replace\([^\n]+["']<\/["'][^\n]+["']<\\\/["']/i);
  assert.match(page, /assets\/report\.css/i);
  assert.match(page, /assets\/report\.js/i);
  const remoteAssets = [...page.matchAll(/(?:src|href)=["'](https?:\/\/[^"']+)["']/gi)]
    .map((match) => match[1]);
  assert.equal(remoteAssets.length, 3);
  assert.ok(remoteAssets.every((url) => /^https:\/\/fonts\.(?:googleapis|gstatic)\.com(?:\/|$)/i.test(url)));
});

test('report pages render the public Run Pro brand system', () => {
  const css = fs.readFileSync(path.join(reportRoot, 'assets', 'report.css'), 'utf8');
  const pages = [
    pagePath,
    path.join(reportRoot, 'canais', 'index.cfm'),
    path.join(reportRoot, 'canais', 'dossie.cfm'),
    path.join(reportRoot, 'explorador', 'index.cfm'),
  ].map((file) => fs.readFileSync(file, 'utf8'));

  for (const page of pages) {
    assert.match(page, /class=["']report-brand["']/i);
    assert.match(page, /src=["']\/lib\/images\/runpro\.svg["']/i);
  }
  assert.match(css, /--ink:\s*#121212/i);
  assert.match(css, /--paper:\s*#f5f1e8/i);
  assert.match(css, /--accent:\s*#f6b61e/i);
  assert.match(css, /--display:\s*["']Barlow Condensed["']/i);
  assert.match(css, /--body:\s*["']Inter["']/i);
});
