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

test('general page authenticates before reading exactly five aggregate bundles', () => {
  const page = fs.readFileSync(pagePath, 'utf8');
  const reads = [...page.matchAll(/mifReadDataset\(\s*["']([^"']+)["']\s*\)/gi)]
    .map((match) => match[1]);

  assert.match(page, /includes\/auth\.cfm/i);
  assert.match(page, /includes\/data\.cfm/i);
  assert.deepEqual(reads.sort(), [
    'channels/index.json',
    'cycle.json',
    'general.json',
    'products.json',
    'territories.json',
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
    'roadrunners',
    'recomendacoes-e-metodo',
  ];

  for (const chapter of chapters) {
    assert.match(page, new RegExp(`#${chapter}`));
  }
  assert.match(page, /window\.print\s*\(/i);
  assert.match(page, /MifReport\.renderGeneral/i);
});

test('general page embeds escaped JSON and loads only local shared assets', () => {
  const page = fs.readFileSync(pagePath, 'utf8');

  assert.match(page, /application\/json/i);
  assert.match(page, /mif-report-data/i);
  assert.match(page, /replace\([^\n]+["']<\/["'][^\n]+["']<\\\/["']/i);
  assert.match(page, /assets\/report\.css/i);
  assert.match(page, /assets\/report\.js/i);
  assert.doesNotMatch(page, /(?:src|href)=["']https?:\/\//i);
});
