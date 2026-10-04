import assert from 'node:assert/strict';
import {readFileSync,writeFileSync,mkdtempSync,rmSync} from 'node:fs';
import {spawnSync} from 'node:child_process';
import {parseHtml} from '/Users/Shared/Projects/RunnerHub/RoadRunners/_codex/scripts/seo/html.mjs';
const source=process.argv[2]||'_codex/staging/seo-languages-20261003/baseline/RoadRunners';
const page=readFileSync(source+'/busca/index.cfm','utf8');
const prefix=page.slice(page.indexOf('<!--- IDENTIFICA A ROTA'),page.indexOf('<!--- NORMALIZA A TAG'));
const head=readFileSync(source+'/includes/estrutura/head.cfm','utf8');
const start=head.search(/<cfif (?:VARIABLES.includeHreflang AND )?structKeyExists\(REQUEST, "currentRouteKey"\)/);
assert.ok(start>=0,'Locate the actual hreflang conditional');
const block=(head.match(/<cfparam name="VARIABLES.includeHreflang"[^>]*>/)?.[0]||'')+head.slice(start,head.indexOf('</cfif>',start)+7);
const scratch=mkdtempSync('/private/tmp/seo-search-hreflang-');
try{
 writeFileSync(scratch+'/prefix.cfm',prefix);writeFileSync(scratch+'/head.cfm',block);
 writeFileSync(scratch+'/fixture.cfm',`<cfscript>
paths={'pt-BR'='/busca/',en='/en/search/',es='/es/busqueda/'};
REQUEST.availableLanguages=[{code='pt-BR',hreflang='pt-BR'},{code='en',hreflang='en'},{code='es',hreflang='es'}];
REQUEST.i18nBuildAbsoluteUrl=function(route,lang){if(route NEQ 'search')throw(message='Wrong route');return 'https://roadrunners.run' & paths[lang];};
rows=[];
</cfscript><cfloop array="#[ 'pt-BR','en','es' ]#" index="lang"><cfset REQUEST.currentRouteKey=lang EQ 'pt-BR' ? '' : 'search'><cfset URL.termo='corrida'><cfset URL.estado='BA'><cfinclude template="prefix.cfm"><cfsavecontent variable="html"><head><cfinclude template="head.cfm"></head></cfsavecontent><cfset arrayAppend(rows,{lang=lang,url='https://roadrunners.run' & paths[lang],html=toBase64(html,'utf-8'),term=URL.termo,state=URL.estado})></cfloop><cfoutput>SEARCH_HREFLANG:#serializeJSON(rows)#</cfoutput>`);
 const r=spawnSync('/usr/bin/java',['-Xms128m','-Xmx512m','-Dfile.encoding=UTF-8',`-Djava.io.tmpdir=${scratch}`,'-cp','/Users/Shared/Projects/ColdFusion Certification/box','cliloader.LoaderCLIMain','-CommandBox_home=/private/tmp/seo-availability-cfml-20261003/commandbox','execute','fixture.cfm'],{cwd:scratch,encoding:'utf8',timeout:60000,maxBuffer:2*1024*1024,env:{PATH:process.env.PATH,LC_ALL:'en_US.UTF-8'}});
 assert.equal(r.status,0,r.stdout+r.stderr);const match=r.stdout.match(/SEARCH_HREFLANG:(\[[^\n]*\])/);assert.ok(match,r.stdout);
 for(const raw of JSON.parse(match[1])){
  const row=Object.fromEntries(Object.entries(raw).map(([k,v])=>[k.toLowerCase(),v]));
  const parsed=parseHtml(Buffer.from(row.html,'base64').toString('utf8'),row.url);
  assert.equal(parsed.hreflang.length,4,`${row.lang} must have all three languages and x-default`);
  assert.ok(parsed.hreflang.some(a=>a.url===row.url));assert.equal(row.term,'corrida');assert.equal(row.state,'BA');
 }
 console.log('CFML search: 3 languages declare reciprocal alternates and preserve term/state.');
}finally{rmSync(scratch,{recursive:true,force:true});}
