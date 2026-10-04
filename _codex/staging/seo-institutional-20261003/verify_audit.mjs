import assert from 'node:assert/strict';
import {readFile,writeFile} from 'node:fs/promises';
import {fileURLToPath} from 'node:url';
import path from 'node:path';
import {loadLatest,generate} from '../../scripts/seo_scorecard.mjs';
import {hreflangReciprocity} from '../../scripts/seo_languages.mjs';
const stage=path.dirname(fileURLToPath(import.meta.url));
const publicReport=JSON.parse(await readFile(path.join(stage,'public-verification.json'),'utf8'));
assert.equal(publicReport.ok,true);
const root='/Users/Shared/RunnerHubReports/seo';
const run=await loadLatest(root,'roadrunners');
assert.ok(Date.parse(run.started_at)>Date.parse(publicReport.checked_at_utc),'Audit must start after public verification');
assert.equal(run.counts.inspected,100);assert.equal(run.discovery_complete,true);
const rows=run.observations;const statuses=hreflangReciprocity(rows);
const institutional=[];const news=[];
for(const page of publicReport.pages.filter(p=>['institutional','external_news'].includes(p.kind))){
 const index=rows.findIndex(o=>o.source_url===page.url);assert.ok(index>=0,'Inspected strategic URL: '+page.url);
 const o=rows[index];assert.equal(o.status,200);assert.equal(o.final_url,page.url);assert.equal(o.redirected,false);
 assert.equal(o.canonical_count,1);assert.equal(o.canonical_url,page.canonical[0]);
 if(page.kind==='institutional'){assert.equal(statuses[index],'pass',page.url);institutional.push({url:page.url,status:statuses[index]});}
 else{assert.deepEqual(o.hreflang,[]);news.push({url:page.url,canonical:o.canonical_url,alternates:0});}
}
assert.equal(institutional.length,9);assert.equal(news.length,6);
const marathonPublic=JSON.parse(await readFile(path.join(stage,'marathons/public-verification.json'),'utf8'));
assert.equal(marathonPublic.ok,true);assert.ok(Date.parse(run.started_at)>Date.parse(marathonPublic.checked_at_utc));
const marathon=rows.find(o=>o.source_url==='https://roadrunners.run/maratonas/');
assert.ok(marathon);assert.equal(marathon.status,200);assert.equal(marathon.redirected,false);assert.equal(marathon.h1_count,1);assert.equal(marathon.canonical_url,marathon.source_url);
const evidence={runId:run.run_id,startedAt:run.started_at,auditAt:run.finished_at,institutional,news,marathons:{url:marathon.source_url,status:'pass',h1_count:1}};
await writeFile(path.join(stage,'audit-verification.json'),JSON.stringify(evidence,null,2));
const snapshot=await generate({reportsRoot:root,output:path.join(stage,'candidate/portal/includes/seo_score_data.cfm'),historyRoot:path.join(root,'score-history')});
assert.equal(snapshot.sites.find(s=>s.id==='roadrunners').runId,run.run_id);
await writeFile(path.join(stage,'snapshot.json'),JSON.stringify(snapshot,null,2));
console.log(JSON.stringify({institutional:institutional.length,news:news.length,sites:snapshot.sites.map(s=>({id:s.id,runId:s.runId,auditAt:s.auditAt,discovered:s.discovered,inspected:s.inspected,score:s.score,reciprocity:s.aiChecks.find(c=>c.id==='hreflang-reciprocity')}))}));
