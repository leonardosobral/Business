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
const pagePath = path.join(reportRoot, 'portfolio', 'index.cfm');
const cssPath = path.join(reportRoot, 'assets', 'portfolio.css');

test('static portfolio page authenticates before reading only its compact summary', () => {
  const page = fs.readFileSync(pagePath, 'utf8');
  const reads = [...page.matchAll(/mifReadDataset\(\s*["']([^"']+)["']\s*\)/gi)]
    .map((match) => match[1]);

  assert.match(page, /\.\.\/includes\/auth\.cfm/i);
  assert.match(page, /\.\.\/includes\/data\.cfm/i);
  assert.ok(
    page.search(/\.\.\/includes\/auth\.cfm/i) < page.search(/mifReadDataset\s*\(/i),
    'authentication must precede private data access',
  );
  assert.deepEqual(reads, ['portfolio/summary.json']);
  assert.doesNotMatch(page, /simulator\.json|explorer\.json|channels\/[a-z0-9-]+\.json/i);
});

test('static portfolio page embeds escaped JSON and renders the approved six chapters', () => {
  const page = fs.readFileSync(pagePath, 'utf8');

  assert.match(page, /type=["']application\/json["']/i);
  assert.match(page, /replace\([^\n]+["']<\/["'][^\n]+["']<\\\/["']/i);
  assert.match(page, /MifPortfolio\.renderSummary\(\s*document\.getElementById\(["']mif-portfolio-root["']\),\s*payload\s*\)/i);
  for (const chapter of [
    'portfolio-resumo',
    'portfolio-diferenciacao',
    'portfolio-redundancia',
    'portfolio-dependencias',
    'portfolio-simulador',
    'portfolio-metodo',
  ]) assert.match(page, new RegExp(`href=["']#${chapter}["']`, 'i'));
});

test('static portfolio header exposes general analysis, dossiers, simulator and PDF actions', () => {
  const page = fs.readFileSync(pagePath, 'utf8');

  assert.match(page, /class=["']report-brand["']/i);
  assert.match(page, /src=["']\/lib\/images\/runpro\.svg["']/i);
  assert.match(page, /href=["']\.\.\/["'][^>]*>← Análise geral</i);
  assert.match(page, /href=["']\.\.\/canais\/["'][^>]*>Dossiês</i);
  assert.match(page, /href=["']simulador\.cfm["'][^>]*>Simulador</i);
  assert.match(page, /window\.print\s*\(/i);
  assert.doesNotMatch(page, />Explorador</i);
});

test('static portfolio page uses versioned local report and portfolio assets only', () => {
  const page = fs.readFileSync(pagePath, 'utf8');

  for (const asset of ['report.css', 'portfolio.css', 'report.js', 'portfolio.js']) {
    assert.match(page, new RegExp(`\\.\\.\\/assets\\/${asset.replace('.', '\\.') }\\?v=\\d+`, 'i'));
  }
  assert.match(page, /portfolio\.css\?v=20260902-2/i);
  assert.match(page, /portfolio\.js\?v=20260902-4/i);
  const remoteAssets = [...page.matchAll(/(?:src|href)=["'](https?:\/\/[^"']+)["']/gi)]
    .map((match) => match[1]);
  assert.equal(remoteAssets.length, 3);
  assert.ok(remoteAssets.every((url) => /^https:\/\/fonts\.(?:googleapis|gstatic)\.com(?:\/|$)/i.test(url)));
});

test('portfolio CSS extends the shared system for dimensions, selector, mobile and print', () => {
  const css = fs.readFileSync(cssPath, 'utf8');

  assert.doesNotMatch(css, /(^|\})\s*:root\s*\{/i);
  assert.match(css, /\.portfolio-dimension-grid\s*\{[^}]*display:\s*grid/is);
  assert.match(css, /\.portfolio-pair-list\s*\{[^}]*display:\s*grid/is);
  assert.match(css, /\.portfolio-pair-card\s*\{/i);
  assert.match(css, /\.portfolio-selector-grid\s*\{[^}]*display:\s*grid/is);
  assert.match(css, /\.portfolio-choice-list\s*\{/i);
  assert.match(css, /@media\s*\(max-width:\s*820px\)[\s\S]*\.chapter-nav/is);
  assert.doesNotMatch(
    css.match(/@media\s*\(max-width:\s*820px\)[\s\S]*?(?=@media|$)/i)?.[0] || '',
    /\.chapter-nav\s*\{[^}]*display:\s*none/is,
  );
  const mobile = css.match(/@media\s*\(max-width:\s*820px\)[\s\S]*?(?=@media|$)/i)?.[0] || '';
  assert.match(mobile, /\.portfolio-pair-list\s*\{[^}]*grid-template-columns:\s*minmax\(0,\s*1fr\)/is);
  assert.match(css, /@media\s+print[\s\S]*\.scenario-receipt[^}]*display:\s*block/is);
  assert.match(css, /@media\s+print[\s\S]*\.portfolio-pair-card[^}]*break-inside:\s*avoid/is);
  assert.match(css, /break-inside:\s*avoid/i);
});
