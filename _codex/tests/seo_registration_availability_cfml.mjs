import assert from 'node:assert/strict';
import {mkdtempSync,readFileSync,writeFileSync,rmSync,mkdirSync,existsSync,copyFileSync} from 'node:fs';
import {spawnSync} from 'node:child_process';
import {resolve} from 'node:path';
const source=resolve(process.argv[2]||'_codex/staging/seo-availability-20261003/RoadRunners');
const text=readFileSync(source+'/evento/index.cfm','utf8');
const start=text.indexOf('<cfscript>',text.indexOf('<!--- STRUCTURED DATA --->'));
const scratch=mkdtempSync('/private/tmp/seo-availability-test-');
try {
 mkdirSync(scratch+'/services');
 const service=source+'/services/EventRegistrationAvailability.cfc';
 if(existsSync(service))copyFileSync(service,scratch+'/services/EventRegistrationAvailability.cfc');
 writeFileSync(scratch+'/schema.cfm',text.slice(start,text.indexOf('</cfscript>',start)+11));
 writeFileSync(scratch+'/fixture.cfm',`<cfscript>
settings=getApplicationSettings(); mappings=duplicate(settings.mappings);mappings['/services']=getDirectoryFromPath(getCurrentTemplatePath()) & 'services';application action='update' mappings=mappings;
VARIABLES.canonical='https://roadrunners.run/evento/prova/';VARIABLES.description='Prova';REQUEST.currentBaseUrl='https://roadrunners.run';
qEvento={nome_evento='Prova',data_inicial=createDate(2099,10,10),data_final=createDate(2099,10,10),status_evento='',url_imagem='',endereco='',cidade='Salvador',estado='BA',pais='BR',coordenadas='',url_inscricao='https://inscricao.example/prova'};
qFornecedores=queryNew('id_fornecedor_tipo,nome_fornecedor,site_fornecedor');
epoch=int(createObject('java','java.lang.System').currentTimeMillis()/1000);
base={version=1,status='open',source_url='https://organizador.example/prova',registration_url=qEvento.url_inscricao,checked_at=epoch};
cases=[];results=[];
for(status in ['open','sold_out','preorder','closed','unknown']) {m=duplicate(base);m.status=status;arrayAppend(cases,m);}
m=duplicate(base);m.checked_at=epoch-86401;arrayAppend(cases,m);
m=duplicate(base);m.checked_at=epoch+3600;arrayAppend(cases,m);
m=duplicate(base);m.registration_url='https://outro.example/prova';arrayAppend(cases,m);
m=duplicate(base);m.source_url='javascript:alert(1)';arrayAppend(cases,m);
arrayAppend(cases,{});arrayAppend(cases,'invalid-json');arrayAppend(cases,'null');arrayAppend(cases,'[]');
</cfscript>
<cfloop array='#cases#' index='metadata'><cfset qEvento.inscricao_disponibilidade=isStruct(metadata) ? serializeJSON(metadata) : metadata><cfinclude template='schema.cfm'><cfset arrayAppend(results,deserializeJSON(VARIABLES.structuredDataJsonLd))></cfloop>
<cfset qEvento.inscricao_disponibilidade=serializeJSON(base)><cfset qEvento.status_evento='cancelado'><cfinclude template='schema.cfm'><cfset arrayAppend(results,deserializeJSON(VARIABLES.structuredDataJsonLd))>
<cfset qEvento.status_evento=''><cfset qEvento.data_final=createDate(2020,1,1)><cfinclude template='schema.cfm'><cfset arrayAppend(results,deserializeJSON(VARIABLES.structuredDataJsonLd))>
<cfoutput>AVAILABILITY_RESULTS:#serializeJSON(results)#</cfoutput>`);
 const r=spawnSync('/usr/bin/java',['-Xms128m','-Xmx512m','-Dfile.encoding=UTF-8','-cp','/Users/Shared/Projects/ColdFusion Certification/box','cliloader.LoaderCLIMain','-CommandBox_home=/private/tmp/seo-availability-cfml-20261003/commandbox','execute','fixture.cfm'],{cwd:scratch,encoding:'utf8',timeout:60000,maxBuffer:3*1024*1024,env:{PATH:process.env.PATH,LC_ALL:'en_US.UTF-8'}});
 assert.equal(r.status,0,r.stdout+r.stderr);
 const match=r.stdout.match(/AVAILABILITY_RESULTS:(\[[^\n]*\])/);assert.ok(match,r.stdout);
 const norm=v=>Array.isArray(v)?v.map(norm):v&&typeof v==='object'?Object.fromEntries(Object.entries(v).map(([k,x])=>[k.toLowerCase(),norm(x)])):v;
 const rows=norm(JSON.parse(match[1]));
 for(const [i,status] of ['InStock','SoldOut','PreOrder'].entries())assert.equal(rows[i].offers.availability,'https://schema.org/'+status,'Confirmed '+status+' must reach actual JSON-LD');
 for(let i=3;i<rows.length;i++)assert.equal(rows[i].offers?.availability,undefined,'Unknown, expired, unsafe, cancelled or past status must not assert ticket availability: '+i);
 assert.equal(rows[0].offers.url,'https://inscricao.example/prova');
 console.log('CFML availability: 15 actual event-schema cases passed.');
} finally {rmSync(scratch,{recursive:true,force:true});}
