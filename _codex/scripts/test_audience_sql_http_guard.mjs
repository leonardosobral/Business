#!/usr/bin/env node
import assert from 'node:assert/strict';
import { copyFileSync, existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { createServer } from 'node:net';
import { request } from 'node:http';
import { spawn } from 'node:child_process';
import { dirname, resolve } from 'node:path';
import { tmpdir } from 'node:os';
import { fileURLToPath } from 'node:url';

const business = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const guard = resolve(business, 'portal/audiencia/queries/.htaccess');
const scratch = mkdtempSync(resolve(tmpdir(), 'rr-audience-sql-http-'));
const documentRoot = resolve(scratch, 'www');
const queryDirectory = resolve(documentRoot, 'portal/audiencia/queries');
const sqlMarker = 'RR_AUDIENCE_SYNTHETIC_SQL_DO_NOT_EXPOSE';
let apache;

const freePort = () => new Promise((done, fail) => {
  const socket = createServer();
  socket.once('error', fail);
  socket.listen(0, '127.0.0.1', () => {
    const port = socket.address().port;
    socket.close(() => done(port));
  });
});

const get = port => new Promise((done, fail) => {
  const call = request({ host: '127.0.0.1', port, path: '/portal/audiencia/queries/summary.sql' }, response => {
    let body = '';
    response.setEncoding('utf8');
    response.on('data', chunk => { body += chunk; });
    response.on('end', () => done({ status: response.statusCode, body }));
  });
  call.once('error', fail);
  call.end();
});

try {
  mkdirSync(queryDirectory, { recursive: true });
  writeFileSync(resolve(queryDirectory, 'summary.sql'), `SELECT '${sqlMarker}';\n`, { mode: 0o644 });
  if (existsSync(guard)) copyFileSync(guard, resolve(queryDirectory, '.htaccess'));

  const port = await freePort();
  const config = resolve(scratch, 'httpd.conf');
  writeFileSync(config, [
    `ServerRoot "${scratch}"`,
    `PidFile "${resolve(scratch, 'httpd.pid')}"`,
    'ErrorLog /dev/stderr',
    'LogLevel warn',
    'ServerName 127.0.0.1',
    `Listen 127.0.0.1:${port}`,
    'LoadModule mpm_prefork_module /usr/libexec/apache2/mod_mpm_prefork.so',
    'LoadModule unixd_module /usr/libexec/apache2/mod_unixd.so',
    'LoadModule authz_core_module /usr/libexec/apache2/mod_authz_core.so',
    'LoadModule authz_host_module /usr/libexec/apache2/mod_authz_host.so',
    `User #${process.getuid()}`,
    `Group #${process.getgid()}`,
    `DocumentRoot "${documentRoot}"`,
    `<Directory "${documentRoot}">`,
    '  AllowOverride All',
    '  Require all granted',
    '</Directory>',
    ''
  ].join('\n'));

  let stderr = '';
  apache = spawn('/usr/sbin/httpd', ['-f', config, '-X'], { stdio: ['ignore', 'ignore', 'pipe'] });
  apache.stderr.on('data', chunk => { stderr += chunk; });
  let response;
  for (let attempt = 0; attempt < 50; attempt++) {
    if (apache.exitCode !== null) throw Error(`local Apache exited (${apache.exitCode}): ${stderr.trim()}`);
    try { response = await get(port); break; }
    catch { await new Promise(done => setTimeout(done, 20)); }
  }
  assert.ok(response, `local Apache did not become ready: ${stderr.trim()}`);
  process.stdout.write(`Observed local loopback HTTP ${response.status}\n`);
  assert.equal(response.status, 403, 'query directory must deny direct HTTP access');
  assert.equal(response.body.includes(sqlMarker), false, 'HTTP response must not expose SQL text');
  assert.equal(readFileSync(resolve(queryDirectory, 'summary.sql'), 'utf8').includes(sqlMarker), true, 'server-side filesystem reads remain available');
  process.stdout.write('PASS local Apache denies SQL over HTTP while preserving filesystem reads\n');
} finally {
  if (apache && apache.exitCode === null) apache.kill('SIGKILL');
  rmSync(scratch, { recursive: true, force: true });
}
