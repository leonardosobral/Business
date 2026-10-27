const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const test = require('node:test');

const root = path.resolve(__dirname, '..', '..');
const reportRoot = path.join(root, 'relatorios', 'maratona-floripa-2026');
const modularRoot = path.join(root, '_codex', 'analyses', 'mif_2026_channels', 'modular_dist');
const python = require('./support/python.cjs');
const pythonOptions = {
  cwd: root,
  encoding: 'utf8',
  env: {...process.env, PYTHONDONTWRITEBYTECODE: '1'},
};

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
    pythonOptions,
  );

  assert.ifError(completed.error);
  assert.equal(completed.status, 0, completed.stderr);
  assert.match(completed.stdout, /modular verification passed/i);
});

test('modular writer confines outputs and preserves unrelated registration files', () => {
  const completed = spawnSync(
    python,
    ['-c', `
from pathlib import Path
from tempfile import TemporaryDirectory
from unittest import TestCase
from _codex.analyses.mif_2026_channels.modular_artifact import write_modular_artifacts

with TemporaryDirectory() as temporary:
    root = Path(temporary)
    registrations = root / 'inscricoes'
    registrations.mkdir()
    for name in ['home.cfm', 'includes/backend.cfm']:
        file = registrations / name
        file.parent.mkdir(parents=True, exist_ok=True)
        file.write_text('existing registration screen: ' + name)
    before = {file.relative_to(root): file.read_bytes() for file in registrations.rglob('*') if file.is_file()}
    output = root / 'report'
    written = write_modular_artifacts(output, {'manifest.json': {}, 'general.json': {'registrations': 1}})
    assert (output / 'general.json').is_file()
    assert all(file.is_relative_to(output) for file in written.values())
    for unsafe in ['../inscricoes/home.cfm', '../inscricoes/data.json', str(registrations / 'data.json')]:
        with TestCase().assertRaises(ValueError):
            write_modular_artifacts(output, {'manifest.json': {}, unsafe: {}})
    after = {file.relative_to(root): file.read_bytes() for file in registrations.rglob('*') if file.is_file()}
    assert after == before, 'registration files changed during report export'
print('modular output confinement passed')
`],
    pythonOptions,
  );

  assert.ifError(completed.error);
  assert.equal(completed.status, 0, completed.stderr);
  assert.match(completed.stdout, /modular output confinement passed/);
});
