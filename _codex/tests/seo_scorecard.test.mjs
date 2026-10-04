import test from 'node:test';
import assert from 'node:assert/strict';
import {mkdtemp,readFile,writeFile,rm,mkdir} from 'node:fs/promises';
import {writeReport} from '../scripts/seo_report.mjs';
const api=await import('../scripts/seo_scorecard.mjs').catch(e=>{if(e.code!=='ERR_MODULE_NOT_FOUND')throw e;return {};});
const call=(name,...args)=>{assert.equal(typeof api[name],'function',`Export obrigatório ausente: ${name}`);return api[name](...args);};
const url='https://roadrunners.run/prova/';
const obs=(extra={})=>({source_url:url,status:200,final_url:url,redirected:false,content_type:'text/html;charset=UTF-8',html_evaluation:'evaluated',title:'Prova',h1_count:1,canonical_count:1,canonical_invalid:false,canonical_url:url,meta_robots:'',x_robots_tag:'',robots_by_agent:{},robots_header_by_agent:{},robots_policy:{googlebot:{allowed:true}},...extra});
const run=(extra={})=>({schema_version:1,rules_version:'1',collector_version:'2.0.0',collector_hash:'a'.repeat(64),site_id:'roadrunners',run_id:'run-1',base_url:'https://roadrunners.run',sitemap_url:'https://roadrunners.run/sitemap.xml',started_at:'2026-09-13T10:00:00Z',finished_at:'2026-09-13T10:00:01Z',mode:'audit',scope:'sample',completion:'complete',discovery_complete:true,exit_code:0,config_hash:'b'.repeat(64),selection_hash:'c'.repeat(64),selected_urls:[url],counts:{discovered:1,selected:1,inspected:1,duplicates:0,errors:0,warnings:0},limits:{},sitemaps:[{url:'https://roadrunners.run/sitemap.xml',status:200,count:1}],errors:[],observations:[obs()],findings:[],...extra});
const criterion=(s,id)=>s.criteria.find(c=>c.id===id);
test('later generation keeps the private complementary evidence with its original date',async t=>{
 const root=await mkdtemp('/private/tmp/seo-evidence-generation-');t.after(()=>rm(root,{recursive:true,force:true}));
 await writeReport(run(),root);
 const other='https://openresults.run/prova/';await writeReport(run({site_id:'openresults',run_id:'or-1',base_url:'https://openresults.run',sitemap_url:'https://openresults.run/sitemap.cfm',selected_urls:[other],observations:[obs({source_url:other,final_url:other,canonical_url:other})],sitemaps:[{url:'https://openresults.run/sitemap.cfm',status:200,count:1}]}),root);
 await mkdir(root+'/evidence');await writeFile(root+'/evidence/latest.json',JSON.stringify({schemaVersion:1,access:{measured_at:'2026-10-03T22:00:00Z',files_scanned:9,site_attribution:false,vhosts:{'roadrunners.run':{shared_combined_log:true},'openresults.run':{shared_combined_log:true}}}}));
 const snapshot=await call('generate',{reportsRoot:root,output:root+'/output.cfm',historyRoot:root+'/history'});
 for(const site of snapshot.sites){assert.match(site.aiChecks.find(c=>c.id==='provider-access').note,/03\/10\/2026/);assert.equal(site.score,100);}
});
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

test('AI readiness separates declared crawl permission, HTML delivery and unmeasured outcomes',()=>{
 const o=obs({robots_policy:{'oai-searchbot':{allowed:true},perplexitybot:{allowed:false}}});
 const checks=call('aiChecks',run({observations:[o]}));const get=id=>checks.find(c=>c.id===id);
 assert.equal(get('oai-searchbot').status,'pass');assert.equal(get('perplexitybot').status,'warning');assert.equal(get('html').status,'pass');
 for(const id of ['provider-access','citations','referrals','structured','facts','training'])assert.equal(get(id).status,'unknown');
 const fail=call('aiChecks',run({observations:[{...o,status:403,html_evaluation:'not_evaluated'}]}));assert.equal(fail.find(c=>c.id==='html').status,'error');assert.equal(fail.find(c=>c.id==='oai-searchbot').status,'pass');
});
test('AI permission is unknown without evidence, and redirects must check source and destination',()=>{
 for(const patch of [{robots_policy:{}},{redirected:true},{robots_policy:{'oai-searchbot':{allowed:'true'}}}]){
  const c=call('aiChecks',run({observations:[obs(patch)]})).find(c=>c.id==='oai-searchbot');assert.equal(c.status,'unknown');
 }
 const c=call('aiChecks',run({observations:[obs({redirected:true,source_robots_policy:{'oai-searchbot':{allowed:false}},robots_policy:{'oai-searchbot':{allowed:true}}})]})).find(c=>c.id==='oai-searchbot');assert.equal(c.status,'warning');
 const empty=call('aiChecks',run({observations:[]}));assert.equal(empty.find(c=>c.id==='html').status,'unknown');
});

test('new metadata checks keep unmeasured audits unknown and technical weights unchanged',()=>{
 const measured=obs({metadata_version:1,description_values:['Prova pública'],hreflang:[{lang:'pt-BR',url}],jsonld:{count:1,invalid:0,types:['SportsEvent']},event_metadata:[{name:'Prova',start_date:'2026-10-10',has_location:true,name_in_body:true,city_in_body:true,has_organizer:true}]});
 const audit=run({observations:[measured]});
 const s=call('scoreRun',audit);assert.equal(s.score,100);assert.equal(criterion(s,'description').status,'pass');assert.equal(criterion(s,'structured').status,'pass');assert.equal(criterion(s,'hreflang').status,'pass');
 assert.equal(criterion(call('scoreRun',run()),'structured').status,'unknown');
 const ai=call('aiChecks',audit);assert.equal(ai.find(c=>c.id==='structured').status,'pass');assert.equal(ai.find(c=>c.id==='facts').status,'unknown');
});
test('malformed JSON-LD, duplicate descriptions and invalid alternates produce evidence without changing the note',()=>{
 const s=call('scoreRun',run({observations:[obs({metadata_version:1,description_values:['A','B'],hreflang:[{lang:'en',url:null}],jsonld:{count:2,invalid:1,types:[]}})]}));
 assert.equal(s.score,100);assert.equal(criterion(s,'structured').status,'error');assert.equal(criterion(s,'description').status,'warning');assert.equal(criterion(s,'hreflang').status,'warning');
 assert.equal(criterion(call('scoreRun',run({observations:[obs({status:403,metadata_version:1,jsonld:{count:1,invalid:0}})]})),'structured').status,'unknown');
});
test('event metadata is a coverage check: missing markup warns, other page types and failed HTML remain unknown',()=>{
 const event='https://roadrunners.run/evento/prova/';
 const ai=extra=>call('aiChecks',run({observations:[obs({source_url:event,final_url:event,metadata_version:1,jsonld:{count:1,invalid:0},event_metadata:[],...extra})]})).find(c=>c.id==='event-fields');
 assert.equal(ai({}).status,'warning');assert.equal(ai({status:403}).status,'unknown');
 assert.equal(ai({event_metadata:[{name:'Prova',start_date:'2026-02-30',has_location:true,name_in_body:true,city_in_body:true,has_organizer:true}]}).status,'warning');
 assert.equal(ai({event_metadata:[{name:'Prova',start_date:'2026-10-10',has_location:true,name_in_body:true,city_in_body:true,has_organizer:true}]}).status,'pass');
});


test('canonical alignment and hreflang self compare percent escapes without changing path or query case',()=>{
 const source='https://roadrunners.run/evento/a%0D%0Ab/?q=%C3%A9';
 const canonical='https://roadrunners.run/evento/a%0d%0ab/?q=%c3%a9';
 const row=obs({source_url:source,final_url:source,canonical_url:canonical,metadata_version:1,hreflang:[{lang:'pt-BR',url:canonical}]});
 const s=call('scoreRun',run({observations:[row]}));
 assert.equal(criterion(s,'alignment').status,'pass');
 assert.equal(criterion(s,'hreflang').status,'pass');
 assert.equal(row.canonical_url,canonical);
 for(const other of ['https://roadrunners.run/evento/A%0D%0Ab/?q=%C3%A9','https://roadrunners.run/evento/a%250D%0Ab/?q=%C3%A9','https://roadrunners.run/evento/a%0D%0Ab/?q=%C3%A8','https://openresults.run/evento/a%0D%0Ab/?q=%C3%A9']) {
  assert.equal(criterion(call('scoreRun',run({observations:[{...row,canonical_url:other}]})),'alignment').status,'warning');
 }
});
