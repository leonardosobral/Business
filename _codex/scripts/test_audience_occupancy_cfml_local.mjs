#!/usr/bin/env node
// Render real CFML with synthetic data only. Never loads Application.cfc or a DSN.
import assert from 'node:assert/strict';
import { copyFileSync, existsSync, mkdirSync, mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';
const root = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const box = process.env.AUDIENCE_CFML_BOX_RUNTIME || '/Users/Shared/Projects/ColdFusion Certification/box';
const boxHome = process.env.AUDIENCE_CFML_COMMANDBOX_HOME || '/private/tmp/runnerhub-audience-cfml.j0MZzV/commandbox';
const java = process.env.AUDIENCE_CFML_JAVA_RUNTIME || '/usr/bin/java';
for (const path of [box, java, resolve(boxHome, 'lib/lucee-5.3.10.120.jar')]) assert.ok(existsSync(path), `Offline runtime missing: ${path}`);
assert.ok(existsSync(resolve(root, 'portal/audiencia/occupancy.cfm')), 'Occupancy must expose its physical fill distribution in a renderable include');
const scratch = mkdtempSync(resolve(tmpdir(), 'audience-occupancy-cfml-'));
const output = mkdtempSync(resolve(tmpdir(), 'audience-occupancy-render-'));
try {
  for (const name of ['portal/audiencia/occupancy.cfm', 'includes/backend/require_admin.cfm']) {
    mkdirSync(dirname(resolve(scratch, name)), { recursive: true });
    copyFileSync(resolve(root, name), resolve(scratch, name));
  }
  copyFileSync(resolve(root, '_codex/tests/audience-occupancy/fixture.cfm'), resolve(scratch, 'render.cfm'));
  const result = spawnSync(java, ['-Dfile.encoding=UTF-8', '-Dsun.stdout.encoding=UTF-8', '-cp', box,
    'cliloader.LoaderCLIMain', `-CommandBox_home=${boxHome}`, 'execute', 'render.cfm'], {
    cwd: scratch, encoding: 'utf8', timeout: 60000,
    env: { PATH: process.env.PATH, LC_ALL: 'en_US.UTF-8', TMPDIR: tmpdir(), RUNNERHUB_OFFLINE_CFML_TESTS: '1' }
  });
  assert.equal(result.status, 0, `CFML must compile: ${result.error || ''}${result.stdout}${result.stderr}`);
  const html = result.stdout;
  writeFileSync(resolve(output, 'occupancy-fixture.html'), html);
  const section = name => html.split(`data-fixture="${name}"`)[1]?.split('data-fixture=')[0] || '';
  const observed = section('observed');
  // Catches using raw signals or registered/excluded positions as the applicable denominator.
  assert.match(observed, /data-occupancy="potential">\s*100</);
  assert.match(observed, /data-occupancy="filled">\s*60</);
  assert.match(observed, /data-occupancy="empty">\s*30</);
  assert.match(observed, /data-occupancy-rate="filled">\s*60\.0%/);
  assert.match(observed, /data-occupancy-rate="empty">\s*30\.0%/);
  assert.match(observed, /data-occupancy="unclassified">\s*10</, 'Unknown state is not folded into empty');
  assert.match(observed, /data-occupancy-format="ads"[^]*?data-occupancy-segment="filled"[^]*?width:\s*71\.4[0-9]*%/);
  assert.match(observed, /data-occupancy-format="banners"[^]*?data-occupancy-segment="filled"[^]*?width:\s*50(?:\.0+)?%/);
  assert.match(observed, /data-occupancy-format="other"/, 'Unmapped formats remain discoverable');
  assert.match(observed, /data-audience-people[^]*?1,106[^]*?1,551/, 'Visitors and sessions share one audience block');
  assert.match(observed, /Oportunidades de entrega/i, 'The primary unit is an applicable position/page opportunity');
  assert.doesNotMatch(observed, /Potencial observado|espaços com visibilidade|espaços visíveis/i, 'Viewability is not presented as the opportunity denominator');
  assert.match(observed, /data-occupancy-format="ads"[^]*?70 oportunidades/i, 'Format bars use opportunities as their unit');
  assert.match(observed, /data-occupancy-ad-views[^>]*>\s*1,740\s*</, 'One-second ad views are a separate visible count');
  assert.match(observed, /Anúncios vistos por 1s[^]*?50%[^]*?1 segundo/i, 'The separate seen count states its viewability criterion');
  assert.match(observed, /<details[^>]*data-occupancy-diagnostics[^>]*>/, 'Technical signals remain in a collapsed disclosure');
  assert.doesNotMatch(observed, /<details[^>]*data-occupancy-diagnostics[^>]*\bopen\b/);
  assert.match(observed, /5,923[^]*?1,719[^]*?1,740[^]*?2,526/, 'Existing technical counts are retained without relabeling');

  const applicableEmpty = section('applicable-empty-no-views');
  assert.match(applicableEmpty, /data-occupancy="potential">\s*200</, 'Applicable opportunities do not require a view event');
  assert.match(applicableEmpty, /data-occupancy="filled">\s*0</);
  assert.match(applicableEmpty, /data-occupancy="empty">\s*200</);
  assert.match(applicableEmpty, /data-occupancy-rate="empty">\s*100\.0%/, 'Two hundred explicit empty states report 100% without views');
  assert.match(applicableEmpty, /data-occupancy-ad-views[^>]*>\s*0\s*</, 'Zero one-second views remain visible as a separate fact');
  assert.match(applicableEmpty, /data-occupancy-format="ads"[^]*?data-occupancy-segment="empty"[^]*?width:\s*100(?:\.0+)?%/);

  const servedNoViews = section('served-no-views');
  assert.match(servedNoViews, /data-occupancy="filled">\s*40</, 'Served/render evidence fills an opportunity without a one-second view');
  assert.match(servedNoViews, /data-occupancy-rate="filled">\s*20\.0%/);
  assert.match(servedNoViews, /data-occupancy-ad-views[^>]*>\s*0\s*</, 'Filled and seen are independent granularities');

  const unknownState = section('unknown-state');
  assert.match(unknownState, /data-occupancy="empty">\s*190</, 'Unknown states are not sold as empty inventory');
  assert.match(unknownState, /data-occupancy="unclassified">\s*10</);
  assert.match(unknownState, /sem confirmação/i);
  assert.match(unknownState, /falhas[^]*?desligad[^]*?pendent/i, 'Unavailable states are distinguished from absence of an advertiser');

  assert.match(section('empty'), /Nenhuma posição registrada/);
  assert.match(section('excluded'), /10[^]*?não aplicáve[^]*?excluíd/i, 'Registered hidden/not-applicable positions are disclosed outside opportunities');
  assert.doesNotMatch(section('empty'), /NaN|Infinity|width:\s*100%/, 'A zero denominator must not draw full availability');
  assert.match(section('unavailable'), /ocupação.*indisponível/i);
  assert.doesNotMatch(section('unavailable'), /data-occupancy="potential"/, 'A failed read cannot reuse stale totals or fabricate zero');
  assert.match(section('unavailable'), /data-audience-people/, 'Audience remains useful when occupation read fails');
  mkdirSync(resolve(output, 'assets/css'), { recursive: true });
  for (const asset of ['mdb.min.css', 'business-ui.css', 'audience-dashboard.css']) copyFileSync(resolve(root, 'assets/css', asset), resolve(output, 'assets/css', asset));
  console.log(`Occupancy CFML rendered assertions passed.\nHTML: ${resolve(output, 'occupancy-fixture.html')}`);
} finally { rmSync(scratch, { recursive: true, force: true }); }
