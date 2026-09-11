#!/usr/bin/env node
// Integration only: Adobe CF on a local-only temporary dev directory, disposable PG.
// Does not deploy application files to any existing route or use a configured server DSN.
import assert from 'node:assert/strict';
import { spawn, spawnSync } from 'node:child_process';
import { randomBytes, randomUUID } from 'node:crypto';
import { mkdtempSync, mkdirSync, readFileSync, writeFileSync, copyFileSync } from 'node:fs';
import { dirname, resolve, basename } from 'node:path';
import { fileURLToPath } from 'node:url';
import { tmpdir } from 'node:os';
import net from 'node:net';

const business = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const road = resolve(business, '../RoadRunners');
const fixtures = resolve(business, '_codex/tests/audience-native-http');
const pgBin = '/opt/homebrew/opt/postgresql@16/bin';
const sshArgs = ['-o', 'BatchMode=yes', '-o', 'ConnectTimeout=10', '-i', '/Users/leonardosobral/.ssh/webs'];
const sshTarget = 'root@ssh.runnerhub.run';
const remoteHost = 'dev.roadrunners.run';
const remotePrefix = '/var/www/dev.roadrunners.run/rr-audience-http-';
const marker = randomUUID();
const rrDatasource = `rr_audience_native_${marker.replaceAll('-', '')}_rr`;
const businessDatasource = `rr_audience_native_${marker.replaceAll('-', '')}_business`;
const testToken = randomBytes(32).toString('hex');
const dbPassword = randomBytes(24).toString('hex');
const cleanEnv = { PATH: process.env.PATH, LC_ALL: 'C', TMPDIR: tmpdir() };
let scratch, remoteDir, remoteArchive, tunnel, pgStarted = false, assertions = 0, cleaning = false;
const q = value => "'" + String(value).replaceAll("'", "'\\''") + "'";
function run(command, args, input, opts = {}) {
  const result = spawnSync(command, args, { input, encoding: 'utf8', maxBuffer: 4e6, timeout: 45000, ...opts });
  if (result.status !== 0) {
    // Configs contain only ephemeral test credentials, but do not include them in output.
    const detail = String(result.stderr || result.error || '').replaceAll(testToken, '[test-token]').replaceAll(dbPassword, '[test-password]');
    throw Error(`${basename(command)} failed (${result.status}): ${detail.slice(0, 2000)}`);
  }
  return result.stdout;
}
const ssh = (command, input) => run('ssh', [...sshArgs, sshTarget, command], input);
const pg = (command, args, input) => run(resolve(pgBin, command), args, input, { env: cleanEnv });
function check(value, expected, message) { assert.deepEqual(value, expected, message); assertions++; process.stdout.write(`PASS ${message}\n`); }
function put(fromRoot, relativePath, target = relativePath) {
  const destination = resolve(scratch, 'web', target);
  mkdirSync(dirname(destination), { recursive: true });
  copyFileSync(resolve(fromRoot, relativePath), destination);
}
const curlValue = value => '"' + String(value).replaceAll('\\', '\\\\').replaceAll('"', '\\"').replaceAll('\n', '\\n').replaceAll('\r', '\\r') + '"';
function request(path, { method = 'GET', body, type = 'application/json', origin = `https://${remoteHost}`, token = true, headers = {} } = {}) {
  assert.match(path, /^[a-zA-Z0-9_/.?=&%:-]*$/);
  const config = [
    'silent', 'show-error', 'include', 'max-time = 20',
    `url = ${curlValue(`https://${remoteHost}/${basename(remoteDir)}/${path}`)}`,
    `resolve = ${curlValue(`${remoteHost}:443:127.0.0.1`)}`,
    `request = ${curlValue(method)}`,
    `write-out = ${curlValue('\nRR_TEST_STATUS:%{http_code}')}`,
    `header = ${curlValue(`Content-Type: ${type}`)}`,
    `header = ${curlValue(`Origin: ${origin}`)}`,
    'header = "Sec-Fetch-Site: same-origin"',
    `user-agent = ${curlValue(headers['User-Agent'] || 'Mozilla/5.0 RunnerHubAudienceNativeTest')}`,
    ...Object.entries(headers).filter(([key])=>key!=='User-Agent').map(([key,value])=>`header = ${curlValue(key+': '+value)}`),
    ...(token ? [`header = ${curlValue(`X-RR-Audience-Test: ${testToken}`)}`] : []),
    ...(body === undefined ? [] : [`data = ${curlValue(typeof body === 'string' ? body : JSON.stringify(body))}`])
  ].join('\n');
  const raw = ssh('curl --config -', config);
  const match = raw.match(/\nRR_TEST_STATUS:(\d{3})$/);
  assert.ok(match, 'curl returned status');
  let content=raw.slice(0,match.index), responseHeaders={};
  while (content.startsWith('HTTP/')) {
    const end=content.search(/\r?\n\r?\n/); assert.ok(end>=0,'response header delimiter');
    const separator=content.slice(end).match(/^\r?\n\r?\n/)[0];
    responseHeaders=Object.fromEntries(content.slice(0,end).split(/\r?\n/).slice(1).filter(line=>line.includes(':')).map(line=>[line.slice(0,line.indexOf(':')).toLowerCase(),line.slice(line.indexOf(':')+1).trim()]));
    content=content.slice(end+separator.length);
  }
  return { status: Number(match[1]), body: content, headers: responseHeaders };
}
function decoded(response) {
  try { return JSON.parse(response.body.trim()); }
  catch { throw Error(`Expected JSON, HTTP ${response.status}; response saved only to private scratch.`); }
}
function reportSummary(response) {
  const data = response.body.match(/<script type="application\/json" id="audience-test-summary">([^<]+)<\/script>/);
  assert.ok(data, 'real Business summary embedded by isolated wrapper');
  const envelope = JSON.parse(data[1]);
  check(Boolean(envelope.ready ?? envelope.READY), true, 'Business confirms audience schema ready');
  check(envelope.unavailable ?? envelope.UNAVAILABLE, false, 'all Business report queries completed');
  return envelope.summary ?? envelope.SUMMARY;
}
async function freePort() {
  return new Promise((done, fail) => {
    const server = net.createServer(); server.on('error', fail);
    server.listen(0, '127.0.0.1', () => { const port = server.address().port; server.close(() => done(port)); });
  });
}
function cleanup() {
  if (cleaning) return;
  cleaning = true;
  if (remoteDir) {
    assert.match(remoteDir, /^\/var\/www\/dev\.roadrunners\.run\/rr-audience-http-[a-zA-Z0-9]{6}$/);
    remoteArchive = `/var/tmp/${basename(remoteDir)}-closed`;
    try { ssh(`chmod 700 ${q(remoteDir)}; chown root:root ${q(remoteDir)}; test ! -e ${q(remoteArchive)} && mv ${q(remoteDir)} ${q(remoteArchive)}`); console.log(`Test route removed; private recovery copy: ${remoteArchive}`); }
    catch (error) { console.error(`CLEANUP REQUIRED for ${remoteDir}: ${error.message}`); process.exitCode = 1; }
  }
  if (tunnel) tunnel.kill('SIGTERM');
  if (pgStarted) {
    try { pg('pg_ctl', ['-D', resolve(scratch, 'data'), '-m', 'immediate', '-w', 'stop']); pgStarted = false; }
    catch (error) { console.error(`POSTGRES CLEANUP REQUIRED: ${error.message}`); process.exitCode = 1; }
  }
  if (scratch) console.log(`Disposable PostgreSQL ${pgStarted ? 'NEEDS STOP' : 'stopped'}; private test diagnostics: ${scratch}`);
}
for (const signal of ['SIGINT', 'SIGTERM']) process.once(signal, () => { cleanup(); process.exit(130); });

if (!process.argv.includes('--run-isolated-dev')) {
  console.log('Requires --run-isolated-dev: creates a local disposable PG and a guarded temporary directory on dev only.');
  process.exit(2);
}

try {
  // Fail before remote writes if the entire guarded harness is not available.
  for (const name of ['Application.cfc.in', 'business/Application.cfc.in', 'fixture.cfm', 'business/report.cfm', 'business/binding.cfm', 'context.cfm', 'diagnose.cfm', 'privacy.cfm', '.htaccess']) readFileSync(resolve(fixtures, name));
  scratch = mkdtempSync(resolve(tmpdir(), 'rr-audience-native-'));
  process.stdout.write(`Scratch: ${scratch}\n`);
  const port = await freePort();
  pg('initdb', ['-D', resolve(scratch, 'data'), '-U', 'postgres', '-A', 'trust', '--no-locale']);
  pg('pg_ctl', ['-D', resolve(scratch, 'data'), '-l', resolve(scratch, 'postgres.log'), '-o', `-F -k ${scratch} -h 127.0.0.1 -p ${port}`, '-w', 'start']);
  pgStarted = true;
  pg('psql', ['-X', '-q', '-v', 'ON_ERROR_STOP=1', '-h', scratch, '-U', 'postgres', '-p', String(port), '-d', 'postgres'],
    `CREATE DATABASE rr_audience_http; CREATE ROLE runner LOGIN PASSWORD '${dbPassword}'; CREATE ROLE runner_dba LOGIN PASSWORD '${dbPassword}';`);
  const socketSql = text => pg('psql', ['-X', '-qAt', '-v', 'ON_ERROR_STOP=1', '-h', scratch, '-p', String(port), '-U', 'postgres', '-d', 'rr_audience_http'], text);
  socketSql(`CREATE TABLE public.rr_audience_test_marker (run_id text NOT NULL); INSERT INTO public.rr_audience_test_marker VALUES ('${marker}'); GRANT SELECT ON public.rr_audience_test_marker TO runner,runner_dba;`);
  // Only generated test users can authenticate over TCP; no passwordless localhost DSN.
  writeFileSync(resolve(scratch, 'data/pg_hba.conf'), 'local all all trust\nhost rr_audience_http runner,runner_dba 127.0.0.1/32 scram-sha-256\nhost all all 0.0.0.0/0 reject\n');
  pg('pg_ctl', ['-D', resolve(scratch, 'data'), 'reload']);
  const remotePort = Number(ssh(`python3 -c ${q('import socket; s=socket.socket(); s.bind(("127.0.0.1",0)); print(s.getsockname()[1]); s.close()')}`).trim());
  assert.ok(remotePort > 1024 && remotePort < 65536);
  let tunnelOutput = '';
  tunnel = spawn('ssh', [...sshArgs, '-o', 'ExitOnForwardFailure=yes', '-N', '-R', `127.0.0.1:${remotePort}:127.0.0.1:${port}`, sshTarget], { stdio: ['ignore', 'ignore', 'pipe'] });
  tunnel.stderr.on('data', data => { tunnelOutput += data; });
  // Poll readiness by checking the remote socket, not a fixed startup sleep.
  for (let attempts = 0; ; attempts++) {
    if (tunnel.exitCode !== null || attempts > 15) throw Error(`Reverse tunnel failed: ${tunnelOutput.slice(0, 500)}`);
    const ready = ssh(`python3 -c "import socket; s=socket.socket(); s.settimeout(1); print(s.connect_ex(('127.0.0.1',${remotePort}))); s.close()"`).trim();
    if (ready === '0') break;
  }
  remoteDir = ssh(`mktemp -d ${q(remotePrefix + 'XXXXXX')}`).trim();
  assert.match(remoteDir, /^\/var\/www\/dev\.roadrunners\.run\/rr-audience-http-[a-zA-Z0-9]{6}$/);
  process.stdout.write(`Isolated dev directory: ${remoteDir}\n`);
  mkdirSync(resolve(scratch, 'web'), { recursive: true });
  put(fixtures, '.htaccess');
  writeFileSync(resolve(scratch, 'web/probe.txt'), 'RR_AUDIENCE_HTTP_ISOLATED\n');
  // Directory is initially 0700. Install access control first, then prove it externally.
  run('scp', [...sshArgs, resolve(scratch, 'web/.htaccess'), resolve(scratch, 'web/probe.txt'), `${sshTarget}:${remoteDir}/`]);
  ssh(`chmod 755 ${q(remoteDir)}; chmod 644 ${q(remoteDir + '/.htaccess')} ${q(remoteDir + '/probe.txt')}`);
  const externalStatus = run('curl', ['--silent', '--show-error', '--max-time', '20', '--output', '/dev/null', '--write-out', '%{http_code}', `https://${remoteHost}/${basename(remoteDir)}/probe.txt`]);
  check(externalStatus, '403', 'Apache denies external access before CFML is copied');
  check(request('probe.txt').status, 200, 'Apache allows loopback access to isolated probe');
  for (const file of ['Application.cfc.in', 'business/Application.cfc.in', 'fixture.cfm', 'business/report.cfm', 'business/binding.cfm', 'context.cfm', 'diagnose.cfm', 'privacy.cfm']) {
    const rendered = readFileSync(resolve(fixtures, file), 'utf8').replaceAll('__RUN_ID__', marker).replaceAll('__PG_PORT__', String(remotePort)).replaceAll('__PG_PASSWORD__', dbPassword).replaceAll('__TEST_TOKEN__', testToken).replaceAll('__DATASOURCE_RR__', rrDatasource).replaceAll('__DATASOURCE_BUSINESS__', businessDatasource);
    assert.ok(!/__\w+__/.test(rendered), `all ${file} placeholders resolved`);
    const target = resolve(scratch, 'web', file.replace(/\.in$/, ''));
    mkdirSync(dirname(target), {recursive:true}); writeFileSync(target, rendered);
  }
  for (const file of ['services/AudienceMeasurementService.cfc', 'services/AudienceRequestControlService.cfc', 'api/analytics/collect.cfm', 'includes/analytics/bootstrap.cfm', 'includes/analytics/privacy_controls.cfm', 'i18n/pt-BR.cfm', 'i18n/en.cfm', 'i18n/es.cfm']) put(road, file);
  for (const file of ['portal/includes/audience_backend.cfm', 'portal/audiencia/home.cfm', 'includes/backend/require_admin.cfm', 'portal/audiencia/queries/.htaccess', ...['filter','summary','inventory','regions','content','acquisition','daily','coverage'].map(name => `portal/audiencia/queries/${name}.sql`)]) put(business, file, `business/${file}`);
  // A unique DSN cannot fall back to the server's runnerhub. Only this literal changes
  // in temporary source copies; no query, validation, signature or UI logic is adapted.
  for (const [file, expectedCount, datasource] of [
    ['services/AudienceMeasurementService.cfc', 1, rrDatasource],
    ['business/portal/includes/audience_backend.cfm', 3, businessDatasource]
  ]) {
    const path = resolve(scratch, 'web', file), original = readFileSync(path, 'utf8');
    check(original.split('datasource="runnerhub"').length - 1, expectedCount, `${file}: only known DSN literals remapped in test copy`);
    writeFileSync(path, original.replaceAll('datasource="runnerhub"', `datasource="${datasource}"`));
  }
  const tar = spawnSync('tar', ['-C', resolve(scratch, 'web'), '-cf', '-', '.'], { maxBuffer: 4e6 });
  assert.equal(tar.status, 0);
  ssh(`tar -xf - -C ${q(remoteDir)}; chown -R nobody:nogroup ${q(remoteDir)}; find ${q(remoteDir)} -type f -exec chmod 640 {} +`, tar.stdout);
  // Apache must read htaccess; CF owns the rest. Directory is traversable only behind the gate.
  ssh(`chmod 644 ${q(remoteDir + '/.htaccess')} ${q(remoteDir + '/probe.txt')} ${q(remoteDir + '/business/portal/audiencia/queries/.htaccess')}`);
  // Make SQL templates web-readable so the HTTP denial is proven to come from
  // their directory guard, not incidentally from fixture filesystem ownership.
  ssh(`find ${q(remoteDir + '/business/portal/audiencia/queries')} -type f -name '*.sql' -exec chmod 644 {} +`);
  check(request('fixture.cfm', {token:false}).status, 403, 'CFML rejects missing test token even over loopback');
  let page = request('fixture.cfm');
  writeFileSync(resolve(scratch, 'fixture-response.html'), page.body);
  check(page.status, 200, 'isolated CF application validates disposable datasource');
  const bootstrap = page.body.match(/window\.RoadRunnersAudienceConfig=(\{[^<]+\});<\/script>/);
  assert.ok(bootstrap, 'actual bootstrap emitted signed configuration'); assertions++;
  const config = JSON.parse(bootstrap[1]);
  check(config.context.visitorUf, 'SP', 'native bootstrap keeps SP access origin');
  check(config.context.marketUf, 'SC', 'native bootstrap attributes SC commercial context');
  for(const lang of ['pt-BR','en','es']) {
    const privacy=request('privacy.cfm?lang='+lang);
    writeFileSync(resolve(scratch,'privacy-'+lang+'.html'),privacy.body);
    check(privacy.status,200,'actual privacy include and '+lang+' catalog compile and render in Adobe');
    check(privacy.body.includes('data-audience-privacy-deny') && privacy.body.includes('data-audience-privacy-allow') && !privacy.body.includes('common.audiencePrivacy'),true,'privacy controls resolve translated labels in '+lang);
  }
  const beforeSchema = request('business/report.cfm?admin=1&ambiente=dev');
  check(beforeSchema.status, 200, 'Business renders before schema exists');
  assert.ok(beforeSchema.body.includes('Medição aguardando instalação')); assertions++;
  socketSql(readFileSync(resolve(road, '_codex/sql/2026-09-07_audience_inventory.sql'), 'utf8'));
  const payload = { contextToken: config.contextToken, signature: config.signature, visitorId: randomUUID(), sessionId: randomUUID(), source:'homologacao', medium:'test', campaign:'isolated-native', events:[{kind:'page_view',key:'page_view',deviceClass:'DESKTOP'}] };
  const endpoint = 'api/analytics/collect.cfm';
  for(const headers of [{'Sec-GPC':'1'},{'Purpose':'prefetch'},{'Sec-Purpose':'prerender'},{'User-Agent':'Googlebot/2.1'}]) {
    const ignored=request(endpoint,{method:'POST',body:payload,headers});
    check(ignored.status,204,'collector suppresses '+Object.keys(headers)[0]);
    check(ignored.body.trim(),'','suppressed collection has no response payload');
  }
  check(socketSql('SELECT count(*) FROM audience.events;').trim(),'0','GPC, bots and speculative requests insert no events');
  check(request(endpoint).status, 405, 'collector rejects GET');
  check(request(endpoint+'?disabled=1', {method:'POST',body:payload}).status, 503, 'collector remains fail-closed when disabled');
  check(request(endpoint, {method:'POST',body:payload,type:'application/xml'}).status, 415, 'collector rejects unsupported content type');
  check(request(endpoint, {method:'POST',body:'x'.repeat(65537)}).status, 413, 'collector rejects oversized body');
  check(request(endpoint, {method:'POST',body:'{'}).status, 400, 'collector rejects malformed JSON');
  check(request(endpoint, {method:'POST',body:{...payload,signature:'0'.repeat(64)}}).status, 400, 'collector rejects tampered signature');
  check(request(endpoint, {method:'POST',body:payload,origin:'https://invalid.example'}).status, 400, 'collector rejects cross origin');
  const expired = decoded(request('context.cfm?mode=expired'));
  check(request(endpoint, {method:'POST',body:{...payload,contextToken:expired.contextToken,signature:expired.signature}}).status, 400, 'collector rejects expired signature');
  let posted = request(endpoint, {method:'POST',body:payload});
  writeFileSync(resolve(scratch, 'collect-response.txt'), posted.body);
  if (posted.status !== 200) console.log('CFML isolated diagnostic (no payload/credentials):', decoded(request('diagnose.cfm?persist=1',{method:'POST',body:payload})));
  check(posted.status, 200, 'valid signed HTTP batch reaches actual PostgreSQL ingestion');
  check(decoded(posted).accepted, 1, 'first page-view accepted');
  check(decoded(request(endpoint, {method:'POST',body:payload,type:'text/plain'})).accepted, 1, 'text/plain beacon replay is accepted as idempotent upsert');
  check(socketSql('SELECT count(*) FROM audience.events;').trim(), '1', 'beacon replay does not duplicate persisted page-view');
  check(socketSql('SELECT visitor_uf||\'/\'||market_uf FROM audience.events;').trim(), 'SP/SC', 'persisted region preserves SP origin and SC market');
  const slotPayload = {...payload, events:[
    {kind:'slot_opportunity',key:'slot:home:one',slotKey:'home-one',placementKey:'home-native',slotState:'empty',deviceClass:'DESKTOP'},
    {kind:'slot_render',key:'render:home:one',slotKey:'home-one',placementKey:'home-native',slotState:'empty',deviceClass:'DESKTOP'},
    {kind:'slot_viewable',key:'view:home:one',slotKey:'home-one',placementKey:'home-native',slotState:'empty',deviceClass:'DESKTOP',ratio:.5,maxContinuousMs:1000,visibleMs:1000}
  ]};
  check(decoded(request(endpoint,{method:'POST',body:slotPayload})).accepted, 3, 'empty but rendered and visible position has three distinct events');
  check(request('business/report.cfm?admin=0&ambiente=dev').status, 403, 'actual Business admin guard denies non-admin fixture');
  check(request('business/portal/includes/audience_backend.cfm').status, 403, 'direct backend include denies access before queries');
  check(request('business/portal/audiencia/home.cfm').status, 403, 'direct Business view denies access');
  const directSql = request('business/portal/audiencia/queries/summary.sql');
  check(directSql.status, 403, 'direct Business SQL template access is denied even over loopback');
  check(directSql.body.includes('AUDIENCE_FILTER') || directSql.body.includes('count(DISTINCT page_view_id)'), false, 'direct Business SQL response never exposes query text');
  const report = request('business/report.cfm?admin=1&ambiente=dev&uf=SC');
  writeFileSync(resolve(scratch, 'business-report.html'), report.body);
  check(report.status, 200, 'Business CFML filters and tables render through HTTP');
  check(report.body.includes('id="audience-chart-data"'), true, 'Business renders source-backed chart payload');
  check(report.body.includes('id="audience-daily-chart"'), true, 'Business exposes daily chart with exact table fallback');
  check(report.body.includes('Retenção ainda não instalada'), true, 'Business distinguishes missing retention from a healthy job');
  check(report.body.includes('Política de retenção: 90 dias') && !report.body.includes('Eventos detalhados: retenção de 90 dias'), true, 'Business labels retention as a target policy, not an unconditional guarantee');
  if (report.body.includes('Não foi possível consultar')) {
    const reportDebug = report.body.match(/<script type="application\/json" id="audience-test-summary">([^<]+)<\/script>/);
    if (reportDebug) console.log('Business isolated diagnostic:', JSON.parse(reportDebug[1]));
    console.log('Business binding isolation:', decoded(request('business/binding.cfm')));
  }
  assert.ok(report.body.includes('home-one') && report.body.includes('Posições visíveis') && !report.body.includes('Não foi possível consultar')); assertions++;
  const summary = reportSummary(report);
  for (const [key, expected] of Object.entries({pageviews:1,active_pages:1,visitors:1,sessions:1,opportunities:1,renders:1,slot_views:1,ad_renders:0,ad_views:0})) check(Number(summary[key] ?? summary[key.toUpperCase()]), expected, `real Business summary ${key}=${expected}`);
  check(socketSql('SELECT count(*) FROM audience.events;').trim(), '4', 'read-only Business queries do not mutate ingested events');
  socketSql(readFileSync(resolve(road,'_codex/sql/2026-09-07_audience_retention.sql'),'utf8'));
  check(request('business/report.cfm?admin=1&ambiente=dev&uf=SC').body.includes('Rotina instalada, ainda sem execução confirmada'),true,'retention never-run state is not healthy');
  socketSql('SELECT * FROM audience.purge_expired_events(1000);');
  check(request('business/report.cfm?admin=1&ambiente=dev&uf=SC').body.includes('Em dia: última execução concluída'),true,'actual retention execution updates Business health');
  socketSql("UPDATE audience.maintenance_state SET last_success_at=now()-interval '3 hours';");
  check(request('business/report.cfm?admin=1&ambiente=dev&uf=SC').body.includes('há mais de 2 horas'),true,'stale success is not reported as healthy');
  socketSql("UPDATE audience.maintenance_state SET last_success_at=now(),has_more=true;");
  check(request('business/report.cfm?admin=1&ambiente=dev&uf=SC').body.includes('eventos vencidos aguardando'),true,'retention backlog appears in Business');
  socketSql("UPDATE audience.maintenance_state SET last_status='error',last_error_code='42501';");
  check(request('business/report.cfm?admin=1&ambiente=dev&uf=SC').body.includes('A rotina informou erro'),true,'retention error appears in Business');
  check(socketSql('SELECT count(*) FROM audience.events;').trim(),'4','retention never deletes fresh test events');
  check(request(endpoint+'?limited=1',{method:'POST',body:payload}).status,200,'isolated low-limit app allows its first batch');
  const limited=request(endpoint+'?limited=1',{method:'POST',body:payload});
  check(limited.status,429,'isolated low-limit app rejects excess request');
  check(Number(limited.headers['retry-after'])>0 && Number(limited.headers['retry-after'])<=60,true,'rate limit includes bounded Retry-After');
  socketSql('REVOKE SELECT ON audience.events FROM runner_dba;');
  const unavailable = request('business/report.cfm?admin=1&ambiente=dev&uf=PR');
  check(unavailable.status, 200, 'Business handles query unavailability without breaking page');
  assert.ok(unavailable.body.includes('Não foi possível consultar')); assertions++;
  socketSql('REVOKE EXECUTE ON FUNCTION audience.ingest_events(jsonb,jsonb,jsonb) FROM runner;');
  check(request(endpoint,{method:'POST',body:payload}).status, 503, 'collector returns safe 503 when database ingestion is unavailable');
  process.stdout.write(`PASS: ${assertions} Adobe ColdFusion HTTP + PostgreSQL checks. Google login and complete live page layouts were not exercised.\n`);
} finally {
  cleanup();
}
