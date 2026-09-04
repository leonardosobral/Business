const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');

const reportRoot = path.resolve(__dirname, '..', '..', 'relatorios', 'maratona-floripa-2026');
const pagePath = path.join(reportRoot, 'estados', 'index.cfm');
const cssPath = path.join(reportRoot, 'assets', 'states.css');

test('states page authenticates before reading only the compact territorial bundle', () => {
  const page = fs.readFileSync(pagePath, 'utf8');
  const reads = [...page.matchAll(/mifReadDataset\(\s*["']([^"']+)["']\s*\)/gi)]
    .map((match) => match[1]);

  assert.match(page, /\.\.\/includes\/auth\.cfm/i);
  assert.match(page, /\.\.\/includes\/data\.cfm/i);
  assert.ok(page.search(/auth\.cfm/i) < page.search(/mifReadDataset/i));
  assert.deepEqual(reads, ['states/strategy.json']);
  assert.doesNotMatch(page, /territories\.json|explorer\.json|channels\/[a-z0-9-]+\.json/i);
});

test('states page defaults to visible selected Visão geral and declares all three views', () => {
  const page = fs.readFileSync(pagePath, 'utf8');
  const overviewButton = page.match(/<button[^>]+data-state-view=["']overview["'][^>]*>[\s\S]*?<\/button>/i)?.[0] || '';

  assert.match(overviewButton, /aria-selected=["']true["']/i);
  assert.match(overviewButton, /button-current/i);
  assert.match(overviewButton, />\s*Visão geral\s*</i);
  assert.match(page, /data-state-view=["']state["']/i);
  assert.match(page, /data-state-view=["']compare["']/i);
  assert.match(page, /MifStates\.mount/i);
});

test('states page embeds safe JSON and uses only versioned local report assets', () => {
  const page = fs.readFileSync(pagePath, 'utf8');

  assert.match(page, /replace\([^\n]+["']<["'][^\n]+["']\\u003c["']/i);
  for (const asset of ['report.css', 'states.css', 'report.js', 'states.js']) {
    assert.match(page, new RegExp(`\\.\\.\\/assets\\/${asset.replace('.', '\\.') }\\?v=\\d+`, 'i'));
  }
  const remoteAssets = [...page.matchAll(/(?:src|href)=["'](https?:\/\/[^"']+)["']/gi)]
    .map((match) => match[1]);
  assert.equal(remoteAssets.length, 3);
  assert.ok(remoteAssets.every((url) => /^https:\/\/fonts\.(?:googleapis|gstatic)\.com(?:\/|$)/i.test(url)));
});

test('states styling covers tabs, comparison, responsive navigation and print', () => {
  const css = fs.readFileSync(cssPath, 'utf8');

  assert.doesNotMatch(css, /(^|\})\s*:root\s*\{/i);
  assert.match(css, /\.states-view-tabs\s*\{/i);
  assert.match(css, /\.states-reach-grid\s*\{[^}]*display:\s*grid/is);
  assert.match(css, /\.states-pair-card\s*\{/i);
  assert.match(css, /@media\s*\(max-width:\s*820px\)/i);
  assert.match(css, /@media\s+print[\s\S]*\.states-view-tabs[^}]*display:\s*none/is);
});
