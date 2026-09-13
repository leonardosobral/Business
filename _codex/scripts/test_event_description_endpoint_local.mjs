#!/usr/bin/env node
// Compile and run the real endpoint guards in offline Lucee; substitute only HTTP I/O.
import assert from 'node:assert/strict';
import {copyFileSync, existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {dirname, resolve} from 'node:path';
import {fileURLToPath} from 'node:url';
import {spawnSync} from 'node:child_process';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const endpoint = resolve(root, 'api/eventos/jobs/rewrite-descriptions.cfm');
assert.ok(existsSync(endpoint), 'Description rewrite endpoint must exist before its guards can pass');
const box = process.env.EVENT_DESCRIPTION_TEST_BOX || '/Users/Shared/Projects/ColdFusion Certification/box';
const boxHome = process.env.EVENT_DESCRIPTION_TEST_BOX_HOME || '/private/tmp/runnerhub-audience-cfml.j0MZzV/commandbox';
const scratch = mkdtempSync(resolve(tmpdir(), 'event-description-endpoint-'));
const pgBin = process.env.EVENT_DESCRIPTION_TEST_PG_BIN || '/opt/homebrew/opt/postgresql@16/bin';
const pgPort = process.env.EVENT_DESCRIPTION_TEST_PG_PORT || String(55500 + process.pid % 300);
let pgStarted = false;
function pg(command, args) {
  const result = spawnSync(resolve(pgBin, command), args, {encoding: 'utf8', timeout: 30000});
  assert.equal(result.status, 0, `${command}: ${result.stdout}${result.stderr}`);
}
try {
  pg('initdb', ['-D', resolve(scratch, 'db'), '-U', 'rewrite_test', '-A', 'trust', '--no-locale', '--encoding=UTF8']);
  pg('pg_ctl', ['-D', resolve(scratch, 'db'), '-l', resolve(scratch, 'postgres.log'), '-o', `-h 127.0.0.1 -p ${pgPort} -k ${scratch}`, '-w', 'start']);
  pgStarted = true;
  mkdirSync(resolve(scratch, 'api/eventos/jobs'), {recursive: true});
  mkdirSync(resolve(scratch, 'services'), {recursive: true});
  mkdirSync(resolve(scratch, 'config'), {recursive: true});
  writeFileSync(resolve(scratch, 'config/business.local.cfm'), '<cfset businessLocalConfig=REQUEST.fixtureConfig />');
  let source = readFileSync(endpoint, 'utf8');
  source = source.replaceAll('CGI.request_method', 'REQUEST.fixtureMethod');
  source = source.replaceAll('getHttpRequestData(', 'fixtureHttpRequestData(');
  source = source.replace('expandPath("/config/business.local.cfm")', JSON.stringify(resolve(scratch, 'config/business.local.cfm')));
  source = source.replace('function rewriteJsonResponse(required numeric statusCode, required struct payload) {',
    'function rewriteJsonResponse(required numeric statusCode, required struct payload) { REQUEST.fixtureResponse={code=arguments.statusCode,payload=arguments.payload}; throw(type="FixtureResponse");');
  writeFileSync(resolve(scratch, 'api/eventos/jobs/rewrite-descriptions.cfm'), source);
  copyFileSync(resolve(root, '_codex/tests/event-description-endpoint.cfm'), resolve(scratch, 'test.cfm'));
  copyFileSync(resolve(root, '_codex/tests/event-description-endpoint-integration.cfm'), resolve(scratch, 'integration.cfm'));
  copyFileSync(resolve(root, '_codex/tests/event-description-endpoint-service.cfc'), resolve(scratch, 'services/EventDescriptionRewriteService.cfc'));
  copyFileSync(resolve(root, 'api/eventos/jobs/schema.sql'), resolve(scratch, 'schema.sql'));
  const result = spawnSync('/usr/bin/java', ['-Dfile.encoding=UTF-8', '-cp', box, 'cliloader.LoaderCLIMain', `-CommandBox_home=${boxHome}`, 'execute', 'test.cfm'], {
    cwd: scratch, encoding: 'utf8', timeout: 60000,
    env: {PATH: process.env.PATH, TMPDIR: tmpdir(), RUNNERHUB_OFFLINE_CFML_TESTS: '1', EVENT_DESCRIPTION_TEST_PG_PORT: pgPort},
  });
  assert.equal(result.status, 0, `${result.error || ''}${result.stdout}${result.stderr}`);
  assert.match(result.stdout, /Endpoint guards passed: 22/);
  assert.match(result.stdout, /Endpoint database flow passed: 10/);
  console.log(result.stdout.trim());
} finally {
  if (pgStarted) pg('pg_ctl', ['-D', resolve(scratch, 'db'), '-m', 'fast', '-w', 'stop']);
  rmSync(scratch, {recursive: true, force: true});
}
