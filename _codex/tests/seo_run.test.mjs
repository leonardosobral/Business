import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, mkdir, writeFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { validateReportRoot, runSite } from '../scripts/seo_run.mjs';
import { readReport } from '../scripts/seo_report.mjs';

test('report storage rejects repository paths before creating artifacts', async()=>{
  await assert.rejects(validateReportRoot('/Users/Shared/Projects/RunnerHub/Business/reports'),/fora|outside|reposit/i);
  await assert.rejects(validateReportRoot('relative/path'),/absolut/i);
});
test('unknown site never launches the collector',async()=>{
  await assert.rejects(runSite({site_id:'../../escape'},{}),/site/i);
});
test('simultaneous site run does not launch a second crawler',async t=>{
  const root=await mkdtemp(path.join(tmpdir(),'seo-run-test-'));
  t.after(()=>rm(root,{recursive:true,force:true}));
  await mkdir(path.join(root,'.locks'),{mode:0o700});
  await writeFile(path.join(root,'.locks','roadrunners.lock'),JSON.stringify({pid:process.pid}));
  const result=await runSite({site_id:'roadrunners',base_url:'https://roadrunners.run',sitemap_url:'https://roadrunners.run/sitemap.xml',strategic_urls:[]},{reportRoot:root,collectorCli:'/does/not/exist'});
  assert.equal(result.status,'already_running');
  assert.equal(result.exit_code,1);
});
test('collector crash persists a failed report instead of losing monitoring evidence',async t=>{
  const root=await mkdtemp(path.join(tmpdir(),'seo-run-crash-'));
  t.after(()=>rm(root,{recursive:true,force:true}));
  const cli=path.join(root,'crash.mjs');await writeFile(cli,'process.exitCode=1;');
  const result=await runSite({site_id:'roadrunners',base_url:'https://roadrunners.run',sitemap_url:'https://roadrunners.run/sitemap.xml',strategic_urls:[]},{reportRoot:root,collectorCli:cli});
  assert.equal(result.exit_code,1);assert.equal(result.completion,'failed');
  const report=await readReport(result.run_dir);assert.ok(report.errors.some(e=>e.code==='COLLECTOR_FAILED'));
});
test('interrupted JSONL preserves complete observations before a truncated tail',async t=>{
  const root=await mkdtemp(path.join(tmpdir(),'seo-run-truncated-'));
  t.after(()=>rm(root,{recursive:true,force:true}));
  const cli=path.join(root,'truncated.mjs');
  await writeFile(cli,`import {writeFileSync} from 'node:fs'; const out=process.argv[process.argv.indexOf('--json-output')+1]; writeFileSync(out+'.observations.jsonl',JSON.stringify({source_url:'https://roadrunners.run/a',status:200})+'\\n{"source_url":');process.exitCode=1;`);
  const result=await runSite({site_id:'roadrunners',base_url:'https://roadrunners.run',sitemap_url:'https://roadrunners.run/sitemap.xml',strategic_urls:[]},{reportRoot:root,collectorCli:cli});
  const run=await readReport(result.run_dir);
  assert.equal(run.completion,'partial');assert.equal(run.observations.length,1);
  assert.ok(run.errors.some(e=>e.code==='TRUNCATED_OBSERVATIONS'));
});
