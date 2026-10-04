import assert from 'node:assert/strict';
import {readFileSync,writeFileSync,mkdtempSync,rmSync} from 'node:fs';
import {spawnSync} from 'node:child_process';
const source=process.argv[2]||'_codex/staging/seo-routes-20261003/baseline/RoadRunners';
const event=readFileSync(source+'/evento/index.cfm','utf8');
const assignment=event.match(/<cfset REQUEST\.currentRouteParams =[^\n]*\/>/)[0];
const app=readFileSync('/Users/Shared/Projects/RunnerHub/RoadRunners/Application.cfc','utf8');
const start=app.indexOf('<cffunction name="buildLocalizedRoutePath"');
const builder=app.slice(start,app.indexOf('</cffunction>',start)+13).replace('access="private"','access="public"');
const scratch=mkdtempSync('/private/tmp/seo-event-url-');
try {
 writeFileSync(scratch+'/Builder.cfc','<cfcomponent>'+builder+'</cfcomponent>');
 writeFileSync(scratch+'/params.cfm',assignment);
 writeFileSync(scratch+'/fixture.cfm',`<cfscript>
VARIABLES.builder=createObject('component','Builder');APPLICATION.i18nConfig={defaultLanguage='pt-BR'};
APPLICATION.i18nRoutes={event={'pt-BR'='/evento/{tag}/',en='/en/event/{tag}/',es='/es/evento/{tag}/'},results={'pt-BR'='/resultados/{tag}/',en='/en/results/{tag}/',es='/es/resultados/{tag}/'}};
tags=['2026-operario' & chr(13) & chr(10) & 'night' & chr(13) & chr(10) & 'run','2026-rock-n-run' & chr(10) & '----nashville-2026','2026-atibaia-run-fest-trail-mode-' & chr(35) & '03-socorro-pico-do-gaviao','evento&escopo=site','evento+á-100%','evento%26literal','evento%2fliteral','prova-comum'];rows=[];
</cfscript><cfloop array='#tags#' index='tag'><cfset URL.tag=tag><cfinclude template='params.cfm'><cfloop array="#[ 'pt-BR','en','es' ]#" index='lang'><cfset arrayAppend(rows,{tag=tag,url_tag=URL.tag,lang=lang,path=VARIABLES.builder.buildLocalizedRoutePath('event',lang),results_path=VARIABLES.builder.buildLocalizedRoutePath('results',lang)})></cfloop></cfloop><cfoutput>EVENT_URL_RESULTS:#serializeJSON(rows)#</cfoutput>`);
 const run=spawnSync('/usr/bin/java',['-Xms128m','-Xmx512m','-Dfile.encoding=UTF-8',`-Djava.io.tmpdir=${scratch}`,'-cp','/Users/Shared/Projects/ColdFusion Certification/box','cliloader.LoaderCLIMain','-CommandBox_home=/private/tmp/seo-availability-cfml-20261003/commandbox','execute','fixture.cfm'],{cwd:scratch,encoding:'utf8',timeout:60000,maxBuffer:2*1024*1024,env:{PATH:process.env.PATH,LC_ALL:'en_US.UTF-8'}});
 assert.equal(run.status,0,run.stdout+run.stderr);
 const match=run.stdout.match(/EVENT_URL_RESULTS:(\[[^\n]*\])/);assert.ok(match,run.stdout);
 const normalize=v=>Array.isArray(v)?v.map(normalize):v&&typeof v==='object'?Object.fromEntries(Object.entries(v).map(([k,x])=>[k.toLowerCase(),normalize(x)])):v;
 const rows=normalize(JSON.parse(match[1]));
 for(const row of rows){
  assert.equal(row.url_tag,row.tag,'URL.tag must remain raw for lookup');
  for(const path of [row.path,row.results_path]) {
   assert.doesNotMatch(path,/[\r\n]/,'No raw controls may remain in a URL');
   const url=new URL(path,'https://roadrunners.run');assert.equal(url.hash,'','Tag must not become a fragment');assert.equal(url.search,'','Tag must not inject query parameters');
   assert.equal(decodeURIComponent(url.pathname.split('/').filter(Boolean).at(-1)),row.tag,'Identifier must be encoded exactly once');
  }
 }
 console.log('CFML event metadata: '+rows.length+' language/tag cases passed with actual route builder; raw lookup tag preserved.');
} finally {rmSync(scratch,{recursive:true,force:true});}
