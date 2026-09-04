const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const test = require('node:test');

const root = path.resolve(__dirname, '..', '..');
const reportRoot = path.join(root, 'relatorios', 'maratona-floripa-2026');
const modularRoot = path.join(root, '_codex', 'analyses', 'mif_2026_channels', 'modular_dist');
const python = '/Users/leonardosobral/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3';

function filesBelow(directory) {
  return fs.readdirSync(directory, { withFileTypes: true }).flatMap((entry) => {
    const candidate = path.join(directory, entry.name);
    return entry.isDirectory() ? filesBelow(candidate) : [candidate];
  });
}

test('web route contains code and assets only, never report JSON', () => {
  const files = filesBelow(reportRoot);

  assert.equal(files.some((file) => file.endsWith('.json')), false);
  assert.equal(files.some((file) => path.basename(file) === 'manifest.json'), false);
  assert.equal(fs.existsSync(path.join(reportRoot, 'index.html')), false);
  assert.equal(fs.existsSync(path.join(reportRoot, 'index.cfm')), true);
});

test('every private-data consumer authenticates first', () => {
  const consumers = filesBelow(reportRoot)
    .filter((file) => file.endsWith('.cfm'))
    .filter((file) => /mifReadDataset\s*\(/i.test(fs.readFileSync(file, 'utf8')));

  assert.equal(consumers.length, 7);
  for (const consumer of consumers) {
    const source = fs.readFileSync(consumer, 'utf8');
    assert.match(source, /includes\/auth\.cfm/i, consumer);
    assert.match(source, /includes\/data\.cfm/i, consumer);
    assert.ok(
      source.search(/includes\/auth\.cfm/i) < source.search(/mifReadDataset\s*\(/i),
      `${consumer} must authenticate before reading data`,
    );
  }
});

test('public code has local assets and no embedded production snapshot', () => {
  const publicFiles = filesBelow(reportRoot)
    .filter((file) => /\.(?:cfm|js|css)$/i.test(file));
  const publicSources = publicFiles
    .map((file) => fs.readFileSync(file, 'utf8'))
    .join('\n');
  const templates = publicFiles
    .filter((file) => file.endsWith('.cfm'))
    .map((file) => fs.readFileSync(file, 'utf8'))
    .join('\n');

  const remoteAssets = [...publicSources.matchAll(/(?:src|href)=["'](https?:\/\/[^"']+)["']/gi)]
    .map((match) => match[1]);
  assert.equal(remoteAssets.length, 21);
  assert.ok(
    remoteAssets.every((url) => /^https:\/\/fonts\.(?:googleapis|gstatic)\.com(?:\/|$)/i.test(url)),
  );
  assert.doesNotMatch(
    templates,
    /(?:src|href)=["'][^"']*assets\/[^"'?]+\.(?:js|css)["']/i,
  );
  assert.doesNotMatch(publicSources, /4321891\.20|15713\s+inscrições pagas em 14027/i);
  assert.doesNotMatch(publicSources, /numero_inscricao|numero_pedido/i);
  assert.doesNotMatch(publicSources, /\/private\/tmp\/mif-2026-channel-study-source/i);
});

test('modular manifest passes portable privacy and hash verification', () => {
  const completed = spawnSync(
    python,
    [
      '-m',
      '_codex.analyses.mif_2026_channels.run',
      'verify-modular',
      '--manifest',
      path.join(modularRoot, 'manifest.json'),
    ],
    { cwd: root, encoding: 'utf8' },
  );

  assert.equal(completed.status, 0, completed.stderr);
  assert.match(completed.stdout, /modular verification passed/i);
});

test('the modular feature never changes the existing registrations screen', () => {
  const completed = spawnSync(
    'git',
    ['diff', '--name-only', '87ccfa7', '--', 'inscricoes'],
    { cwd: root, encoding: 'utf8' },
  );

  assert.equal(completed.status, 0, completed.stderr);
  assert.equal(completed.stdout.trim(), '');
});
