#!/usr/bin/env node
// Real CFML backend, replacing only the DB boundary in an ephemeral copy.
import assert from 'node:assert/strict';
import {copyFileSync,existsSync,mkdirSync,mkdtempSync,readFileSync,rmSync,writeFileSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {dirname,resolve} from 'node:path';
import {fileURLToPath} from 'node:url';
import {spawnSync} from 'node:child_process';
const root=resolve(dirname(fileURLToPath(import.meta.url)),'../..');
const scratch=mkdtempSync(resolve(tmpdir(),'home-metrics-cfml-'));
const box=process.env.AUDIENCE_CFML_BOX_RUNTIME||'/Users/Shared/Projects/ColdFusion Certification/box';
const home=process.env.AUDIENCE_CFML_COMMANDBOX_HOME||'/private/tmp/runnerhub-audience-cfml.j0MZzV/commandbox';
const java=process.env.AUDIENCE_CFML_JAVA_RUNTIME||'/usr/bin/java';
for(const path of [box,java,resolve(home,'lib/lucee-5.3.10.120.jar')]) assert.ok(existsSync(path),`Existing offline CFML runtime required: ${path}`);
let checks=0;
const eq=(actual,expected,message)=>{assert.deepEqual(actual,expected,message);checks++;};
const lower=value=>Array.isArray(value)?value.map(lower):value&&typeof value==='object'?Object.fromEntries(Object.entries(value).map(([key,item])=>[key.toLowerCase(),lower(item)])):value;
try {
  mkdirSync(resolve(scratch,'includes/backend'),{recursive:true});
  copyFileSync(resolve(root,'includes/backend/require_admin.cfm'),resolve(scratch,'includes/backend/require_admin.cfm'));
  const source=readFileSync(resolve(root,'includes/backend/business_home_metrics.cfm'),'utf8');
  assert.ok(source.includes('queryExecute('),'Test must replace the actual database boundary');
  writeFileSync(resolve(scratch,'includes/backend/business_home_metrics.cfm'),source.replace(/\bqueryExecute\(/g,'homeFixtureQuery('));
  copyFileSync(resolve(root,'_codex/tests/business-home-metrics/backend_fixture.cfm'),resolve(scratch,'check.cfm'));
  const result=spawnSync(java,['-Dfile.encoding=UTF-8','-cp',box,'cliloader.LoaderCLIMain',`-CommandBox_home=${home}`,'execute','check.cfm'],{cwd:scratch,encoding:'utf8',timeout:60000,env:{PATH:process.env.PATH,LC_ALL:'en_US.UTF-8',TMPDIR:tmpdir(),RUNNERHUB_OFFLINE_CFML_TESTS:'1'}});
  assert.equal(result.status,0,`Backend must compile: ${result.error||''}${result.stdout||''}${result.stderr||''}`);
  const match=result.stdout.match(/HOME_METRICS_RESULT=(\{[\s\S]*\})/);
  assert.ok(match,`Compiled backend must emit the fixture: ${result.stdout.slice(-4000)}`);
  const report=lower(JSON.parse(match[1]));
  for(const row of report.results) {
    if('input' in row) eq(row.metrics.days,row.input==='30'?30:7,'Only the explicit 30-day URL value enables the long period');
    for(const name of ['audience','ads','accounts','users']) {
      eq(row.metrics[name].loaded,name!==row.failed,`${name} loaded state survives independent failures`);
      eq(Number(row.metrics[name][name==='audience'?'visitors':name==='ads'?'cost':'new_count']),row.zero||row.failed===name?0:9,`${name} preserves returned values including measured zero`);
      if(row.failed===name) eq(row.metrics[name].comparison_ready,false,'A failed source can never claim comparable data');
    }
    eq(row.metrics.audience.interactions_comparison_ready,row.failed!=='audience','Interaction coverage has its own boolean availability contract');
  }
  eq(report.calls.length,report.results.length*4,'Every source is attempted after any prior failure');
  for(const call of report.calls) {
    eq(call.datasource,'runnerhub','Runtime uses the established read datasource');
    eq(call.type,'cf_sql_integer','URL is bound as an integer');
    eq(call.timeout,5,'Each query has its own timeout');
    assert.ok(Number(call.cache)>0&&Number(call.cache)<=1/1440+1e-8,'Cache is bounded at one minute');checks++;
  }
  assert.ok(!result.stdout.includes('Synthetic unavailable source'),'Exceptions are not emitted to the response');checks++;
  console.log(`Business home metrics CFML: ${checks} assertions passed (real include, isolated DB boundary).`);
} finally {rmSync(scratch,{recursive:true,force:true});}
