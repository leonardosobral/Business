#!/usr/bin/env node
// Render the real view with synthetic data. No application bootstrap, DB, or production HTTP.
import assert from 'node:assert/strict';
import {copyFileSync, existsSync, mkdirSync, mkdtempSync, rmSync, writeFileSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {dirname,resolve} from 'node:path';
import {fileURLToPath} from 'node:url';
import {spawnSync} from 'node:child_process';
const root=resolve(dirname(fileURLToPath(import.meta.url)),'../..');
const scratch=mkdtempSync(resolve(tmpdir(),'audience-live-cfml-'));
const output=mkdtempSync(resolve(tmpdir(),'audience-live-render-'));
const box=process.env.AUDIENCE_LIVE_BOX_RUNTIME || '/Users/Shared/Projects/ColdFusion Certification/box';
const home=process.env.AUDIENCE_LIVE_COMMANDBOX_HOME || '/private/tmp/runnerhub-audience-cfml.j0MZzV/commandbox';
try {
  assert.ok(existsSync(resolve(root,'portal/audiencia/live_journey.cfm')),'LIVE journeys must render independently from inventory and purchases');
  mkdirSync(resolve(scratch,'portal/audiencia'),{recursive:true});mkdirSync(resolve(scratch,'includes/backend'),{recursive:true});
  copyFileSync(resolve(root,'portal/audiencia/live_journey.cfm'),resolve(scratch,'portal/audiencia/live_journey.cfm'));
  copyFileSync(resolve(root,'includes/backend/require_admin.cfm'),resolve(scratch,'includes/backend/require_admin.cfm'));
  copyFileSync(resolve(root,'_codex/tests/audience-live-business/fixture.cfm'),resolve(scratch,'render.cfm'));
  const result=spawnSync(process.env.AUDIENCE_LIVE_JAVA_RUNTIME || '/usr/bin/java',['-Dfile.encoding=UTF-8','-Dsun.stdout.encoding=UTF-8','-Dsun.stderr.encoding=UTF-8','-cp',box,'cliloader.LoaderCLIMain',`-CommandBox_home=${home}`,'execute','render.cfm'],{cwd:scratch,encoding:'utf8',env:{PATH:process.env.PATH,LC_ALL:'en_US.UTF-8',TMPDIR:tmpdir(),RUNNERHUB_OFFLINE_CFML_TESTS:'1'}});
  assert.equal(result.status,0,`CFML render must compile: ${result.error || ''}${result.stdout || ''}${result.stderr || ''}`);
  const html=result.stdout;
  const observed=html.split('data-fixture="observed"')[1]?.split('data-fixture="historical"')[0] || '';
  const history=html.split('data-fixture="historical"')[1]?.split('data-fixture="unavailable"')[0] || '';
  const unavailable=html.split('data-fixture="unavailable"')[1] || '';
  assert.match(observed,/25[.,]0%/,'campaign progression divides the matched session by four arrivals');
  assert.match(observed,/50[.,]0%/,'event rate divides matched exits by two event visits');
  assert.match(observed,/sem abertura correspondente/i,'missing page beacons remain visible instead of inflating rates');
  assert.ok(!html.includes('<script>alert(1)</script>'),'campaign names and reflected filters must be HTML escaped');
  assert.match(html,/Live &lt;teste&gt;/,'event names are rendered as text');
  assert.ok(!history.includes('href="https://roadrunners.run/evento/javascript:'),'catalog tags cannot become unsafe links');
  assert.match(history,/Cidade não informada/,'missing catalog city remains explicit');
  assert.match(history,/Nenhuma saída recebida/,'historical zero cannot claim instrumented zero intent');
  assert.ok(!history.includes('0.0%') && !history.includes('0,0%'),'unproven outbound collection cannot claim a measured zero percent rate');
  assert.match(history,/—/,'zero event denominator has no fabricated conversion rate');
  assert.match(observed,/name="dias" value="7"/,'section filter preserves the reporting period');
  assert.match(observed,/name="uf" value="SC"/,'section filter preserves the global regional scope');
  assert.match(observed,/name="dispositivo" value="MOBILE"/,'section filter preserves device scope');
  assert.match(unavailable,/indisponível/i,'optional report failure must be visible without inventing zero');
  assert.ok(!unavailable.includes('<table'),'unavailable data is not presented as an empty valid table');
  mkdirSync(resolve(output,'assets/css'),{recursive:true});
  for(const asset of ['mdb.min.css','business-ui.css','audience-dashboard.css']) copyFileSync(resolve(root,'assets/css',asset),resolve(output,'assets/css',asset));
  writeFileSync(resolve(output,'live-fixture.html'),html,'utf8');
  console.log(`Audience LIVE CFML: 15 rendered behavior assertions passed.\nHTML: ${resolve(output,'live-fixture.html')}`);
} finally {rmSync(scratch,{recursive:true,force:true});}
