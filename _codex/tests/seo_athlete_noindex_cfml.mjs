import assert from 'node:assert/strict';
import {mkdtempSync,copyFileSync,writeFileSync,rmSync} from 'node:fs';
import {spawnSync} from 'node:child_process';
import {parseHtml} from '/Users/Shared/Projects/RunnerHub/RoadRunners/_codex/scripts/seo/html.mjs';
const source=process.argv[2];assert.ok(source,'Source with includes/head.cfm required');
const scratch=mkdtempSync('/private/tmp/seo-noindex-test-');
try {
 copyFileSync(source+'/includes/head.cfm',scratch+'/head.cfm');
 // The external analytics include is independent from indexing metadata.
 writeFileSync(scratch+'/seo-web-tools-head.cfm','');
 writeFileSync(scratch+'/fixture.cfm',`<cfscript>
VARIABLES.title='Página';VARIABLES.description='Teste';VARIABLES.keywords='corridas';VARIABLES.canonical='https://openresults.run/evento/prova/';
cases=['/resultados/','/evento/','/','/busca/','/ranking/','/estatisticas/',''];results=[];
</cfscript><cfloop array="#cases#" index="route"><cfif len(route)><cfset VARIABLES.template=route><cfelse><cfset structDelete(VARIABLES,'template')></cfif><cfsavecontent variable="html"><cfinclude template="head.cfm"></cfsavecontent><cfset arrayAppend(results,{route=route,html=toBase64(html,'utf-8')})></cfloop><cfoutput>NOINDEX_RESULTS:#serializeJSON(results)#</cfoutput>`);
 const r=spawnSync('/usr/bin/java',['-Xms128m','-Xmx512m',`-Djava.io.tmpdir=${scratch}`,'-Dfile.encoding=UTF-8','-cp','/Users/Shared/Projects/ColdFusion Certification/box','cliloader.LoaderCLIMain',`-CommandBox_home=${process.env.SEO_CONTENT_CFML_HOME}`,'execute','fixture.cfm'],{cwd:scratch,encoding:'utf8',timeout:60000,maxBuffer:2*1024*1024,env:{PATH:process.env.PATH,LC_ALL:'en_US.UTF-8'}});
 assert.equal(r.status,0,r.stdout+r.stderr);const match=r.stdout.match(/NOINDEX_RESULTS:(\[[^\n]*\])/);assert.ok(match,r.stdout+r.stderr);
 for(const raw of JSON.parse(match[1])) {
  const row=Object.fromEntries(Object.entries(raw).map(([k,v])=>[k.toLowerCase(),v]));
  const html=Buffer.from(row.html,'base64').toString('utf8');
  const robots=[...html.matchAll(/<meta name="robots" content="([^"]+)"/g)].map(m=>m[1]);
  assert.deepEqual(robots,row.route==='/resultados/'?['noindex, follow']:[],`Only athlete histories must be excluded: ${row.route}`);
  assert.equal(parseHtml(html,'https://openresults.run/').canonical_raw,'https://openresults.run/evento/prova/');
 }
 console.log('CFML noindex: 7 route/head cases passed; event, home, search, rankings and statistics remain indexable.');
} finally {rmSync(scratch,{recursive:true,force:true});}
