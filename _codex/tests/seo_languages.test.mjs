import test from 'node:test';
import assert from 'node:assert/strict';
const api=await import('../scripts/seo_languages.mjs').catch(e=>{if(e.code!=='ERR_MODULE_NOT_FOUND')throw e;return {};});
const pt='https://roadrunners.run/evento/prova/',en='https://roadrunners.run/en/event/prova/',es='https://roadrunners.run/es/evento/prova/';
const links=[{lang:'pt-BR',url:pt},{lang:'en',url:en},{lang:'es',url:es},{lang:'x-default',url:pt}];
const row=(url,extra={})=>({source_url:url,final_url:url,status:200,redirected:false,content_type:'text/html',html_evaluation:'evaluated',metadata_version:1,canonical_url:url,canonical_count:1,canonical_invalid:false,hreflang:structuredClone(links),...extra});
const evaluate=rows=>{assert.equal(typeof api.hreflangReciprocity,'function');return api.hreflangReciprocity(rows);};
test('complete bidirectional cluster passes, independently of link order and language case',()=>{
 const rows=[row(pt),row(en,{hreflang:[...links].reverse().map(a=>({...a,lang:a.lang.toUpperCase()}))}),row(es)];
 assert.deepEqual(evaluate(rows),['pass','pass','pass']);
});
test('uninspected targets are unknown; one observed broken return link warns despite missing others',()=>{
 assert.deepEqual(evaluate([row(pt)]),['unknown']);
 const missingReturn=links.filter(a=>a.url!==pt);
 assert.equal(evaluate([row(pt),row(en,{hreflang:missingReturn})])[0],'warning');
});
test('observed target failure, redirects, mismatched canonical and missing HTML cannot prove reciprocity',()=>{
 for(const patch of [{status:403},{error_code:'TIMEOUT'},{redirected:true},{canonical_url:pt},{canonical_count:2},{html_evaluation:'not_evaluated'}])
  assert.equal(evaluate([row(pt),row(en,patch),row(es)])[0],'warning',JSON.stringify(patch));
 assert.equal(evaluate([row(pt),row(en,{metadata_version:undefined}),row(es)])[0],'unknown');
});
test('duplicate or malformed alternates and missing self reference warn, absent metadata remains unknown',()=>{
 for(const patch of [{hreflang:[...links,links[0]]},{hreflang:[...links,{lang:'en',url:'javascript:alert(1)'}]},{hreflang:links.filter(a=>a.url!==pt)}])assert.equal(evaluate([row(pt,patch)])[0],'warning');
 for(const patch of [{hreflang:[]},{metadata_version:undefined},{hreflang:[links[0],links[3]]}])assert.equal(evaluate([row(pt,patch)])[0],'unknown');
});
test('same language pointing to a different URL breaks the cluster; x-default may reuse the Portuguese URL',()=>{
 assert.deepEqual(evaluate([row(pt),row(en),row(es)]),['pass','pass','pass']);
 assert.equal(evaluate([row(pt),row(en,{hreflang:links.map(a=>a.lang==='es'?{...a,url:pt}:a)}),row(es)])[0],'warning');
});
test('cross-domain alternates are allowed but never followed outside the observed cohort',()=>{
 const other='https://example.test/es/';const cross=links.map(a=>a.lang==='es'?{...a,url:other}:a);
 assert.deepEqual(evaluate([row(pt,{hreflang:cross}),row(en,{hreflang:cross})]),['unknown','unknown']);
 assert.deepEqual(evaluate([row(pt,{hreflang:cross}),row(en,{hreflang:cross}),row(other,{hreflang:cross})]),['pass','pass','pass']);
});
test('conflicting duplicate observations are inconclusive and do not overwrite evidence silently',()=>{
 assert.equal(evaluate([row(pt),row(en),row(en,{status:403}),row(es)])[0],'unknown');
});
test('an inspected alternate with metadata but no return links is a demonstrated warning',()=>{
 assert.equal(evaluate([row(pt),row(en,{hreflang:[]}),row(es)])[0],'warning');
});
test('percent-escape case is equivalent, without decoding slashes or changing path case',()=>{
 const lower=links.map(a=>({...a,url:a.url.replace('prova','prova%3f')}));
 const rows=lower.filter(a=>a.lang!=='x-default').map(a=>row(a.url.replace('%3f','%3F'),{canonical_url:a.url,hreflang:lower}));
 assert.deepEqual(evaluate(rows),['pass','pass','pass']);
 const different=lower.map(a=>a.lang==='en'?{...a,url:a.url.replace('prova%3f','Prova%3f')}:a);
 assert.notEqual(evaluate([rows[0],{...rows[1],hreflang:different},rows[2]])[0],'pass');
 const encoded=lower.map(a=>({...a,url:a.url.replace('prova%3f','prova%2fparte')}));
 const decoded=encoded.map(a=>row(a.url.replace('%2f','/'),{hreflang:encoded}));
 assert.notEqual(evaluate(decoded)[0],'pass');
});
test('scorecard includes reciprocity without changing technical weights and keeps translation unmeasured',async()=>{
 const {aiChecks}=await import('../scripts/seo_scorecard.mjs');
 const checks=aiChecks({observations:[row(pt),row(en),row(es)]});
 assert.equal(checks.find(c=>c.id==='hreflang-reciprocity')?.pass,3);
 assert.equal(checks.find(c=>c.id==='translations')?.status,'unknown');
});
test('examples prioritize observed warnings over targets missing from the sample',async()=>{
 const {aiChecks}=await import('../scripts/seo_scorecard.mjs');
 const first=row('https://roadrunners.run/other/',{hreflang:[]});
 const check=aiChecks({observations:[first,row(pt),row(en,{hreflang:[]}),row(es)]}).find(c=>c.id==='hreflang-reciprocity');
 assert.equal(check.cases[0],pt);
});
