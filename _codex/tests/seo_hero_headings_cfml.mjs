import assert from 'node:assert/strict';
import {mkdtempSync,readFileSync,writeFileSync,rmSync,copyFileSync} from 'node:fs';
import {spawnSync} from 'node:child_process';
import {parseHtml} from '/Users/Shared/Projects/RunnerHub/RoadRunners/_codex/scripts/seo/html.mjs';
const source=process.argv[2]||'/Users/Shared/Projects/RunnerHub/RoadRunners';
const scratch=mkdtempSync('/private/tmp/seo-hero-headings-');
try {
 copyFileSync(source+'/includes/estrutura/home_hero_busca.cfm',scratch+'/hero.cfm');
 // The shared hero is real; the independent search form is outside this fixture.
 writeFileSync(scratch+'/busca.cfm','<form role="search"><input aria-label="Busca"></form>');
 writeFileSync(scratch+'/fixture.cfm',`<cfscript>
REQUEST.currentBaseUrl='https://roadrunners.run';URL.estado='BA';REQUEST.LocationContext={uf='BA'};
REQUEST.homeDiscoveryText=function(key){return 'Corridas & comunidade';};
REQUEST.t=function(key,args={}){return key EQ 'search.legacy.heroTitle' ? VARIABLES.caseItem.title : 'Busca & comunidade';};
cases=[];results=[];
for(title in ['Resultado da busca','Search results','Resultado de la búsqueda']) {
 for(route in ['/','/busca/','/evento/','/noticias/']) arrayAppend(cases,{route=route,title=title});
}
</cfscript><cfloop array="#cases#" index="caseItem"><cfset VARIABLES.template=caseItem.route><cfsavecontent variable="html"><cfinclude template="hero.cfm"></cfsavecontent><cfset arrayAppend(results,{route=caseItem.route,title=caseItem.title,html=toBase64(html,'utf-8')})></cfloop><cfoutput>HERO_RESULTS:#serializeJSON(results)#</cfoutput>`);
 const r=spawnSync('/usr/bin/java',['-Xms128m','-Xmx512m','-Dfile.encoding=UTF-8','-cp','/Users/Shared/Projects/ColdFusion Certification/box','cliloader.LoaderCLIMain',`-CommandBox_home=${process.env.SEO_CONTENT_CFML_HOME}`,'execute','fixture.cfm'],{cwd:scratch,encoding:'utf8',timeout:60000,maxBuffer:3*1024*1024,env:{PATH:process.env.PATH,LC_ALL:'en_US.UTF-8'}});
 assert.equal(r.status,0,r.stdout+r.stderr);
 const match=r.stdout.match(/HERO_RESULTS:(\[[^\n]*\])/);assert.ok(match,r.stdout+r.stderr);
 const rows=JSON.parse(match[1]);
 for(const raw of rows) {
  const row=Object.fromEntries(Object.entries(raw).map(([k,v])=>[k.toLowerCase(),v]));
  const html=Buffer.from(row.html,'base64').toString('utf8');
  assert.equal(parseHtml(html,'https://roadrunners.run/').h1_count,['/','/busca/'].includes(row.route)?1:0,`${row.route}: only home and search own the hero's main heading`);
  if(row.route==='/busca/') assert.ok(html.includes(row.title),`Search title must use the current language: ${row.title}`);
  assert.ok(html.includes('role="search"'),'Search form must remain present');
  assert.ok(html.includes('class="home-hero-chip home-hero-chip-select"'),'State selector must remain present');
 }
 console.log('CFML hero: 12 route/language cases preserve search and heading roles.');
} finally {rmSync(scratch,{recursive:true,force:true});}
