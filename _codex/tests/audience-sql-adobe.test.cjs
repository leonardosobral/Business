const { test } = require('node:test');
const assert = require('node:assert/strict');
const { readFileSync, readdirSync } = require('node:fs');
const { resolve } = require('node:path');

// Adobe's named-parameter parser treats the SQL string '--' as a comment.
// Native reproduction: _codex/docs/2026-09-07_audiencia_homologacao_http.md.
// Keep this host-compatibility guard alongside real PostgreSQL semantic tests.
test('audience SQL avoids the unknown-UF literal that breaks Adobe parameter binding', () => {
  const directory = resolve(__dirname, '../../portal/audiencia/queries');
  const incompatible = readdirSync(directory).filter(name => name.endsWith('.sql'))
    .filter(name => /'--'/.test(readFileSync(resolve(directory, name), 'utf8')));
  assert.deepEqual(incompatible, [], 'Build the same unknown-UF value without a double-hyphen SQL literal');
});
