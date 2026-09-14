import test from 'node:test';
import assert from 'node:assert/strict';
import {mkdtemp,readFile,writeFile,rm} from 'node:fs/promises';
import {writeReport} from '../scripts/seo_report.mjs';
const api=await import('../scripts/seo_scorecard.mjs').catch(e=>{if(e.code!=='ERR_MODULE_NOT_FOUND')throw e;return {};});
const call=(name,...args)=>{assert.equal(typeof api[name],'function',`Export obrigatório ausente: ${name}`);return api[name](...args);};
const url='https://roadrunners.run/prova/';
const obs=(extra={})=>({source_url:url,status:200,final_url:url,redirected:false,content_type:'text/html;charset=UTF-8',html_evaluation:'evaluated',title:'Prova',h1_count:1,canonical_count:1,canonical_invalid:false,canonical_url:url,meta_robots:'',x_robots_tag:'',robots_by_agent:{},robots_header_by_agent:{},robots_policy:{googlebot:{allowed:true}},...extra});
const run=(extra={})=>({schema_version:1,rules_version:'1',collector_version:'2.0.0',collector_hash:'a'.repeat(64),site_id:'roadrunners',run_id:'run-1',base_url:'https://roadrunners.run',sitemap_url:'https://roadrunners.run/sitemap.xml',started_at:'2026-09-13T10:00:00Z',finished_at:'2026-09-13T10:00:01Z',mode:'audit',scope:'sample',completion:'complete',discovery_complete:true,exit_code:0,config_hash:'b'.repeat(64),selection_hash:'c'.repeat(64),selected_urls:[url],counts:{discovered:1,selected:1,inspected:1,duplicates:0,errors:0,warnings:0},limits:{},sitemaps:[{url:'https://roadrunners.run/sitemap.xml',status:200,count:1}],errors:[],observations:[obs()],findings:[],...extra});
const criterion=(s,id)=>s.criteria.find(c=>c.id===id);
test('fixed weights and worst status yield 100, 85 and 97.5, independently of finding counts',()=>{
 assert.equal(call('scoreRun',run()).score,100);
 const s=call('scoreRun',run({observations:[obs(),obs({status:403})]}));assert.equal(s.score,85);assert.equal(criterion(s,'http').status,'error');assert.equal(criterion(s,'title').partial,true);
 assert.equal(call('scoreRun',run({observations:[obs({redirected:true})],findings:[]})).score,97.5);
 assert.equal(call('scoreRun',run()).criteria.reduce((n,c)=>n+c.weight,0),100);
});
test('multiple H1 is informative only, absent H1 warns',()=>{
 const s=call('scoreRun',run({observations:[obs({h1_count:3})]}));assert.equal(s.score,100);assert.equal(criterion(s,'h1').status,'pass');assert.equal(criterion(s,'hierarchy').status,'warning');assert.equal(criterion(s,'hierarchy').weight,0);
 assert.equal(call('scoreRun',run({observations:[obs({h1_count:0})]})).score,95);
});
test('zero observations and sitemaps never green; network failure is error, absent response unknown',()=>{
 const empty=call('scoreRun',run({observations:[],sitemaps:[]}));assert.equal(empty.score,null);assert.equal(empty.counts.pass,0);assert.equal(empty.counts.unknown,16);
 assert.equal(criterion(call('scoreRun',run({observations:[obs({status:0,error_code:'TIMEOUT'})]})),'http').status,'error');
 assert.equal(criterion(call('scoreRun',run({observations:[obs({status:undefined})]})),'http').status,'unknown');
});
test('only usable HTML proves index directives; irrelevant agents never penalize Googlebot',()=>{
 for(const patch of [{status:403},{html_evaluation:'not_evaluated'},{error:'timeout'},{content_type:'application/pdf'}])assert.equal(criterion(call('scoreRun',run({observations:[obs(patch)]})),'index').status,'unknown');
 for(const patch of [{robots_by_agent:{bingbot:['noindex']}},{x_robots_tag:'bingbot: noindex',robots_header_by_agent:{bingbot:['noindex']}}])assert.equal(criterion(call('scoreRun',run({observations:[obs(patch)]})),'index').status,'pass');
 for(const patch of [{meta_robots:'noindex'},{robots_by_agent:{googlebot:['noindex']}},{x_robots_tag:'googlebot: noindex',robots_header_by_agent:{googlebot:['noindex']}}])assert.equal(criterion(call('scoreRun',run({observations:[obs(patch)]})),'index').status,'warning');
});
test('sitemap success requires parsed counts and complete discovery, not only HTTP200',()=>{
 for(const patch of [{discovery_complete:false},{sitemaps:[{url,status:200}]},{errors:[{url,code:'INVALID_SITEMAP'}]}])assert.notEqual(criterion(call('scoreRun',run(patch)),'sitemaps').status,'pass');
});
test('history is idempotent and rejects changed cohort, coverage, rules or method as comparable',()=>{
 const r=run();const s=call('scoreRun',r);const h=call('appendHistory',[],r,s);assert.equal(h.length,1);assert.equal(call('appendHistory',h,r,s).length,1);
 const next=run({run_id:'run-2'});assert.equal(call('appendHistory',h,next,call('scoreRun',next)).at(-1).comparable,true);
 for(const patch of [{rules_version:'2'},{selected_urls:['https://roadrunners.run/other/']},{observations:[obs({status:403})]},{scope:'full'},{config_hash:'d'.repeat(64)}]){const changed=run({run_id:'run-2',...patch});assert.equal(call('appendHistory',h,changed,call('scoreRun',changed)).at(-1).comparable,false);}
 const old=structuredClone(h);old[0].methodVersion='old';assert.equal(call('appendHistory',old,next,call('scoreRun',next)).at(-1).comparable,false);
});
test('cases reject controls, credentials, deceptive domains, protocols and encoded controls',()=>{
 for(const bad of ['https://evil.test/','https://roadrunners.run.evil.test/','https://u:p@roadrunners.run/','https://roadrunners.run/\\a','https://roadrunners.run/\na','https://roadrunners.run/%0a','javascript:alert(1)'])assert.equal(call('safeCaseUrl',bad),null);
 assert.equal(call('safeCaseUrl',url),url);
});
test('valid bundle reads; corrupt payload and changed pointer hash are rejected',async t=>{
 const root=await mkdtemp('/private/tmp/seo-score-test-');t.after(()=>rm(root,{recursive:true,force:true}));await writeReport(run(),root);
 assert.equal((await call('loadLatest',root,'roadrunners')).run_id,'run-1');
 const pointer=root+'/roadrunners/latest-complete.json';const raw=await readFile(pointer,'utf8');const p=JSON.parse(raw);p.manifest_sha256='0'.repeat(64);await writeFile(pointer,JSON.stringify(p));await assert.rejects(()=>call('loadLatest',root,'roadrunners'),/ponteiro|hash|Integridade/i);await writeFile(pointer,raw);
 await writeFile(root+'/roadrunners/run-1/findings.json','[] ');await assert.rejects(()=>call('loadLatest',root,'roadrunners'),/Integridade/i);
});
test('runtime preserves guard and stores JSON only as base64, without private paths',()=>{
 const cf=call('renderCfml',{methodVersion:'technical-checks-v1',sites:[call('scoreRun',run())]});assert.match(cf,/require_admin.cfm/);assert.match(cf,/getBaseTemplatePath/);assert.match(cf,/statuscode="405"/);assert.match(cf,/VARIABLES.seoScoreSnapshot/);assert.doesNotMatch(cf,/\/Users\/|\/private\//);
 const encoded=cf.match(/binaryDecode\("([A-Za-z0-9+/=]+)", "base64"\)/);assert.ok(encoded);assert.equal(JSON.parse(Buffer.from(encoded[1],'base64').toString()).sites[0].score,100);
});
test('collector defaults without an HTTP response cannot prove direct delivery or HTTPS',()=>{
 const s=call('scoreRun',run({observations:[obs({status:0,final_url:'',redirected:false,error_code:'TIMEOUT',html_evaluation:'not_evaluated'})]}));assert.equal(criterion(s,'direct').status,'unknown');assert.equal(criterion(s,'https').status,'unknown');
});

test('missing or malformed relevant robots map is unknown rather than implicitly green',()=>{
 for(const patch of [{robots_by_agent:undefined},{robots_header_by_agent:[]},{robots_by_agent:{googlebot:undefined}},{robots_by_agent:{googlebot:'noindex'}}])assert.equal(criterion(call('scoreRun',run({observations:[obs(patch)]})),'index').status,'unknown');
});
test('collector changes break comparability and an older audit cannot become a progress point',()=>{
 const r=run(),h=call('appendHistory',[],r,call('scoreRun',r));
 for(const patch of [{collector_hash:'e'.repeat(64)},{collector_version:'3.0.0'}]){const next=run({run_id:'run-2',...patch});const entry=call('appendHistory',h,next,call('scoreRun',next)).at(-1);assert.equal(entry.comparable,false);assert.equal(entry.deltaLabel,'Amostra, método ou cobertura diferente');}
 const old=run({run_id:'run-old',finished_at:'2026-09-12T00:00:00Z'});assert.throws(()=>call('appendHistory',h,old,call('scoreRun',old)),/anterior|cronol/i);
});
test('site summary uses its own audit findings, operational errors and inventory rather than queue data',()=>{
 const s=call('scoreRun',run({counts:{discovered:99360,inspected:100},errors:[{url,code:'TEST'}],findings:[{severity:'error'},{severity:'warning'},{severity:'warning'},{severity:'info'}]}));
 assert.equal(s.operationalErrors,1);assert.equal(s.pageErrors,1);assert.equal(s.warnings,2);
 assert.equal(s.coverageNote,'Foram analisadas 100 de 99.360 URLs descobertas nos sitemaps. A amostra não representa todas as páginas do site.');
});
test('equal coverage counts with different evaluated URLs cannot claim progress; same URL repair can',()=>{
 const a='https://roadrunners.run/a/',b='https://roadrunners.run/b/';
 const before=run({selected_urls:[a,b],observations:[obs({source_url:a,title:''}),obs({source_url:b,title:undefined})]});
 const site=call('scoreRun',before),history=call('appendHistory',[],before,site);
 const shifted=run({run_id:'run-2',selected_urls:[a,b],observations:[obs({source_url:a,title:undefined}),obs({source_url:b,title:'Presente'})]});
 assert.equal(call('appendHistory',history,shifted,call('scoreRun',shifted)).at(-1).comparable,false);
 const repaired=run({run_id:'run-3',selected_urls:[a,b],observations:[obs({source_url:a,title:'Reparado'}),obs({source_url:b,title:undefined})]});
 assert.equal(call('appendHistory',history,repaired,call('scoreRun',repaired)).at(-1).comparable,true);
});
