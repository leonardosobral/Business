import assert from 'node:assert/strict';
import {mkdtempSync,readFileSync,writeFileSync,mkdirSync,copyFileSync,existsSync,rmSync} from 'node:fs';
import {spawnSync} from 'node:child_process';
import path from 'node:path';
const source=process.argv[2]||'/Users/Shared/Projects/RunnerHub/OpenResults';
const runtime=process.env.SEO_CONTENT_CFML_HOME;
const include=path.join(source,'includes/seo_event_schema.cfm');
assert.ok(existsSync(include),'Event schema include must exist');
assert.ok(runtime&&existsSync(path.join(runtime,'lib/lucee-5.3.10.120.jar')),'Existing isolated CFML runtime required');
const scratch=mkdtempSync('/private/tmp/seo-event-schema-test-');
try{
 mkdirSync(path.join(scratch,'includes'));copyFileSync(include,path.join(scratch,'includes/schema.cfm'));
 writeFileSync(path.join(scratch,'fixture.cfm'),`<cfsetting showdebugoutput="false"><cfscript>
VARIABLES.canonical="https://openresults.run/evento/prova%3F/";
VARIABLES.eventoStatusTitulo="Resultados disponíveis";VARIABLES.eventoStatusDescricao="Consulte a fonte.";
qFornecedores=queryNew("tag_tipo,id_fornecedor_tipo,nome_fornecedor", "varchar,integer,varchar", [{tag_tipo="org",id_fornecedor_tipo=2,nome_fornecedor="Cronometrador"},{tag_tipo="timer",id_fornecedor_tipo=1,nome_fornecedor="Organizador correto"}]);
cases=[{name='Corrida "Sol" & </script><script>unsafe()</script>',start="2026-10-10",finish="2026-10-10",status=""},{name="Cancelada",start="2026-01-01",finish="2025-12-31",status="cancelado"},{name="Sem data",start="",finish="",status=""}];results=[];
</cfscript><cfloop array="#cases#" index="item"><cfscript>
qEvento=queryNew("nome_evento,cidade,estado,pais,data_inicial,data_final,status_evento", "varchar,varchar,varchar,varchar,varchar,varchar,varchar", [{nome_evento=item.name,cidade="Salvador",estado="BA",pais="BR",data_inicial=item.start,data_final=item.finish,status_evento=item.status}]);
</cfscript><cfinclude template="includes/schema.cfm"><cfset arrayAppend(results, VARIABLES.eventSchemaJsonLd)></cfloop><cfoutput>SEO_EVENT_SCHEMA_RESULTS:#serializeJSON(results)#</cfoutput>`);
 const r=spawnSync('/usr/bin/java',['-Xms128m','-Xmx512m','-Dfile.encoding=UTF-8','-cp','/Users/Shared/Projects/ColdFusion Certification/box','cliloader.LoaderCLIMain',`-CommandBox_home=${runtime}`,'execute','fixture.cfm'],{cwd:scratch,encoding:'utf8',timeout:60000,maxBuffer:2*1024*1024,env:{PATH:process.env.PATH,LC_ALL:'en_US.UTF-8',RUNNERHUB_OFFLINE_CFML_TESTS:'1'}});
 assert.equal(r.status,0,r.stdout+'\n'+r.stderr);
 const output=(r.stdout||'')+'\n'+(r.stderr||'');
 writeFileSync('/private/tmp/seo-event-schema-cfml-output.log',output);
 const match=output.match(/SEO_EVENT_SCHEMA_RESULTS:(\[[^\n]*\])/);assert.ok(match,output);
 const rows=JSON.parse(match[1]);const first=JSON.parse(rows[0]),cancelled=JSON.parse(rows[1]);
 assert.equal(first['@type'],'SportsEvent');assert.equal(first.name,'Corrida "Sol" & </script><script>unsafe()</script>');
 assert.doesNotMatch(rows[0],/<\/script/i);assert.equal(first.startDate,'2026-10-10');assert.equal(first.location.address.addressLocality,'Salvador');assert.equal(first.organizer.name,'Organizador correto');assert.equal(first.url,'https://openresults.run/evento/prova%3F/');
 assert.equal(first.eventStatus,undefined);assert.equal(first.offers,undefined);assert.equal(first.image,undefined);assert.equal(cancelled.eventStatus,'https://schema.org/EventCancelled');assert.equal(cancelled.endDate,undefined);assert.equal(rows[2],'');
 console.log('CFML schema: dates, cancellation, truthful fields, organizer role and script escaping passed');
}finally{rmSync(scratch,{recursive:true,force:true});}
