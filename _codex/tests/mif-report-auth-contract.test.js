const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');

const root = path.resolve(__dirname, '..', '..');
const includes = path.join(
  root,
  'relatorios',
  'maratona-floripa-2026',
  'includes',
);

function source(name) {
  return fs.readFileSync(path.join(includes, name), 'utf8');
}

test('auth reuses Business login and fails closed without a profile', () => {
  const auth = source('auth.cfm');

  assert.match(auth, /includes\/backend\/backend_login\.cfm/i);
  assert.match(auth, /isDefined\(["']qPerfil["']\)/i);
  assert.match(auth, /qPerfil\.recordcount/i);
  assert.match(auth, /\?login=1&redirect=/i);
  assert.match(auth, /urlEncodedFormat/i);
  assert.match(auth, /REQUEST\.mifReportAuthorized\s*=\s*true/i);
});

test('auth only accepts a local path as its login return target', () => {
  const auth = source('auth.cfm');

  assert.match(auth, /left\([^\n]+,\s*1\)\s+(?:EQ|==)\s*["']\/["']/i);
  assert.match(auth, /left\([^\n]+,\s*2\)\s+(?:NEQ|!=)\s*["']\/\/["']/i);
  assert.match(auth, /chr\(10\)/i);
  assert.match(auth, /chr\(13\)/i);
  assert.match(auth, /find\(["']\\["']/i);
});

test('private data loader is authorized, rooted and manifest allowlisted', () => {
  const data = source('data.cfm');

  assert.match(data, /REQUEST\.mifReportAuthorized/i);
  assert.match(data, /MIF_REPORT_DATA_ROOT/);
  assert.match(data, /\/var\/lib\/runnerhub\/reports\/mif-2026/);
  assert.match(data, /manifest\.json/i);
  assert.match(data, /manifest\.artifacts/i);
  assert.match(data, /structKeyExists\([^\n]+artifacts/i);
  assert.match(data, /\^\[a-z0-9\/_-\]\+\\\.json\$/i);
  assert.match(data, /find\(["']\.\.["']/i);
  assert.match(data, /mifReadDataset/i);
  assert.match(data, /deserializeJson/i);
});

test('data files remain outside the web route', () => {
  const data = source('data.cfm');

  assert.doesNotMatch(data, /expandPath\s*\(/i);
  assert.doesNotMatch(data, /relatorios\/maratona-floripa-2026\/data/i);
});
