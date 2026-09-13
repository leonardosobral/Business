#!/usr/bin/env node
// Actual backend, with only queryExecute replaced at the database boundary.
import assert from 'node:assert/strict';
import {copyFileSync,mkdirSync,mkdtempSync,rmSync,readdirSync,readFileSync,writeFileSync,existsSync} from 'node:fs';
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
const scratch=mkdtempSync(resolve(tmpdir(),'audience-occupancy-backend-'));
try {
  const files=['portal/includes/audience_backend.cfm','includes/backend/require_admin.cfm',
    ...readdirSync(resolve(root,'portal/audiencia/queries')).filter(f=>f.endsWith('.sql')).map(f=>'portal/audiencia/queries/'+f)];
  for(const file of files){mkdirSync(dirname(resolve(scratch,file)),{recursive:true});copyFileSync(resolve(root,file),resolve(scratch,file));}
  // Lucee cannot shadow builtin names. Remap just the database call boundary
  // in this disposable test copy; no condition, parameter or query is rewritten.
  const backendPath=resolve(scratch,'portal/includes/audience_backend.cfm');
  const backend=readFileSync(backendPath,'utf8');
  assert.ok(backend.includes('queryExecute('),'Fixture must exercise the real database boundary');
  writeFileSync(backendPath,backend.replace(/\bqueryExecute\(/g,'occupancyFixtureQuery('));
  copyFileSync(resolve(root,'_codex/tests/audience-occupancy/backend_fixture.cfm'),resolve(scratch,'check.cfm'));
  const result=spawnSync(java,['-Dfile.encoding=UTF-8','-cp',box,'cliloader.LoaderCLIMain',`-CommandBox_home=${runtimeHome}`,'execute','check.cfm'],{
    cwd:scratch,encoding:'utf8',timeout:60000,env:{PATH:process.env.PATH,LC_ALL:'en_US.UTF-8',TMPDIR:tmpdir(),RUNNERHUB_OFFLINE_CFML_TESTS:'1'}
  });
  assert.equal(result.status,0,`Backend must compile: ${result.error || ''}${result.stdout || ''}${result.stderr || ''}`);
  assert.ok(result.stdout.includes('OCCUPANCY_BACKEND_PASS_17'),`Backend contract failed: ${result.stdout.slice(-9000)}`);
  console.log('Occupancy backend: 17 behavior assertions passed (isolated database boundary).');
} finally {rmSync(scratch,{recursive:true,force:true});}
