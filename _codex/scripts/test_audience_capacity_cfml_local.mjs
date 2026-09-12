#!/usr/bin/env node
// Real CFML template with synthetic rows only; no app bootstrap or production access.
import assert from 'node:assert/strict';
import {copyFileSync,existsSync,mkdirSync,mkdtempSync,rmSync,writeFileSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {dirname,resolve} from 'node:path';
import {fileURLToPath} from 'node:url';
import {spawnSync} from 'node:child_process';
const root=resolve(dirname(fileURLToPath(import.meta.url)),'../..');
const box=process.env.AUDIENCE_CFML_BOX_RUNTIME || '/Users/Shared/Projects/ColdFusion Certification/box';
const runtimeHome=process.env.AUDIENCE_CFML_COMMANDBOX_HOME || '/private/tmp/runnerhub-audience-cfml.j0MZzV/commandbox';
const java=process.env.AUDIENCE_CFML_JAVA_RUNTIME || '/usr/bin/java';
for (const [name,path] of [['AUDIENCE_CFML_BOX_RUNTIME',box],['AUDIENCE_CFML_JAVA_RUNTIME',java],['AUDIENCE_CFML_COMMANDBOX_HOME',resolve(runtimeHome,'lib/lucee-5.3.10.120.jar')]]) {
  assert.ok(existsSync(path),`Missing local CFML runtime: ${path}. Configure ${name}; this test does not install or access production.`);
}
assert.ok(existsSync(resolve(root,'portal/audiencia/capacity.cfm')),'Capacity must have a renderable independent section');
const scratch=mkdtempSync(resolve(tmpdir(),'audience-capacity-cfml-'));
const output=mkdtempSync(resolve(tmpdir(),'audience-capacity-render-'));
try {
  mkdirSync(resolve(scratch,'portal/audiencia'),{recursive:true});
  mkdirSync(resolve(scratch,'includes/backend'),{recursive:true});
  copyFileSync(resolve(root,'portal/audiencia/capacity.cfm'),resolve(scratch,'portal/audiencia/capacity.cfm'));
  copyFileSync(resolve(root,'includes/backend/require_admin.cfm'),resolve(scratch,'includes/backend/require_admin.cfm'));
  copyFileSync(resolve(root,'_codex/tests/audience-capacity/fixture.cfm'),resolve(scratch,'render.cfm'));
  const result=spawnSync(java,['-Dfile.encoding=UTF-8','-Dsun.stdout.encoding=UTF-8','-cp',box,'cliloader.LoaderCLIMain',`-CommandBox_home=${runtimeHome}`,'execute','render.cfm'],{
    cwd:scratch,encoding:'utf8',timeout:60000,env:{PATH:process.env.PATH,LC_ALL:'en_US.UTF-8',TMPDIR:tmpdir(),RUNNERHUB_OFFLINE_CFML_TESTS:'1'}
  });
  assert.equal(result.status,0,`Template must compile: ${result.error || ''}${result.stdout || ''}${result.stderr || ''}`);
  const html=result.stdout;
  writeFileSync(resolve(output,'capacity-fixture.html'),html,'utf8');
  console.log(`Rendered fixture: ${resolve(output,'capacity-fixture.html')}`);
  const section=name=>html.split(`data-fixture="${name}"`)[1]?.split('data-fixture=')[0] || '';
  assert.match(section('observed'),/data-capacity="opportunities">\s*420</,'Physical total is supplied separately, not summed across UF rows');
  assert.match(section('observed'),/data-capacity="views">\s*210</,'Visible exposures retain their measured count');
  assert.match(section('observed'),/data-scenario="low">\s*300</,'Weakest observed week feeds lower scenario');
  assert.match(section('observed'),/data-scenario="base">\s*450</,'Baseline feeds the distinct modeled scenario');
  assert.match(section('observed'),/14 dias/,'Each modeled row identifies its baseline');
  assert.match(section('observed'),/Desconhecida/,'Missing commercial UF is explicit');
  assert.ok(!html.includes('<script>alert(1)</script>'),'Slot keys must render as escaped text');
  assert.match(section('observed'),/home-&lt;script&gt;/,'Escaped key remains inspectable');
  assert.match(section('observed'),/Histórico insuficiente/,'A new slot cannot inherit another row’s maturity');
  assert.match(section('short'),/30 ou 90 dias/,'Short filter tells the reader how to include a baseline');
  assert.ok(!section('short').includes('data-scenario="base"'),'Insufficient baseline is not a zero forecast');
  assert.match(section('noncommercial'),/Contexto comercial/,'Incompatible filters cannot relabel physical origin as market capacity');
  assert.ok(!section('noncommercial').includes('<table'),'Diagnostic/internal filters do not show commercial scenarios');
  assert.match(section('unavailable'),/indisponível/,'Read failure remains distinct from no traffic');
  assert.ok(!section('unavailable').includes('<table'),'Failed query cannot present stale synthetic counts');
  assert.match(section('empty'),/Nenhuma posição/,'Empty selection is an observed absence, not a forecast');
  assert.ok(!section('empty').includes('data-scenario="base"'),'No data never projects zero');
  assert.match(section('observed'),/não.*garantia/i,'Modeled capacity is not a delivery commitment');
  mkdirSync(resolve(output,'assets/css'),{recursive:true});
  for(const asset of ['mdb.min.css','business-ui.css','audience-dashboard.css']) copyFileSync(resolve(root,'assets/css',asset),resolve(output,'assets/css',asset));
  console.log(`Capacity CFML: 18 rendered assertions passed.\nHTML: ${resolve(output,'capacity-fixture.html')}`);
} finally {rmSync(scratch,{recursive:true,force:true});}
