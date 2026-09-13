#!/usr/bin/env node
// Executes the real service against synthetic text and a test-only provider subclass.
import assert from 'node:assert/strict';
import {copyFileSync,existsSync,mkdirSync,mkdtempSync,rmSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {dirname,resolve} from 'node:path';
import {fileURLToPath} from 'node:url';
import {spawnSync} from 'node:child_process';

const root=resolve(dirname(fileURLToPath(import.meta.url)),'../..');
const box=process.env.EVENT_REWRITE_CFML_BOX_RUNTIME || '/Users/Shared/Projects/ColdFusion Certification/box';
const runtimeHome=process.env.EVENT_REWRITE_CFML_COMMANDBOX_HOME || '/private/tmp/runnerhub-audience-cfml.j0MZzV/commandbox';
const java=process.env.EVENT_REWRITE_CFML_JAVA_RUNTIME || '/usr/bin/java';
for(const path of [box,java,resolve(runtimeHome,'lib/lucee-5.3.10.120.jar')]) assert.ok(existsSync(path),`Existing CFML runtime required: ${path}`);
const scratch=mkdtempSync(resolve(tmpdir(),'event-description-rewrite-cfml-'));
try {
  mkdirSync(resolve(scratch,'services'));
  for(const [from,to] of [
    ['services/EventDescriptionRewriteService.cfc','services/EventDescriptionRewriteService.cfc'],
    ['_codex/tests/event-description-rewrite/ProviderFixture.cfc','services/ProviderFixture.cfc'],
    ['_codex/tests/event-description-rewrite/service.cfm','run.cfm']
  ]) if(existsSync(resolve(root,from))) copyFileSync(resolve(root,from),resolve(scratch,to));
  const result=spawnSync(java,['-Dfile.encoding=UTF-8','-Dsun.stdout.encoding=UTF-8','-cp',box,'cliloader.LoaderCLIMain',`-CommandBox_home=${runtimeHome}`,'execute','run.cfm'],{
    cwd:scratch,encoding:'utf8',timeout:60000,maxBuffer:2e6,
    env:{PATH:process.env.PATH,LC_ALL:'en_US.UTF-8',TMPDIR:tmpdir(),RUNNERHUB_OFFLINE_CFML_TESTS:'1'}
  });
  const output=String(result.stdout || '')+String(result.stderr || '');
  assert.equal(result.status,0,`CFML execution failed: ${result.error || ''}\n${output}`);
  assert.match(output,/EVENT_REWRITE_TESTS_PASSED:\d+/,`Service assertions failed:\n${output}`);
  process.stdout.write(output);
} finally {rmSync(scratch,{recursive:true,force:true});}
