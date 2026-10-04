import assert from 'node:assert/strict';
import {mkdtempSync,readFileSync,writeFileSync,rmSync,mkdirSync,copyFileSync} from 'node:fs';
import {spawnSync} from 'node:child_process';
const source=process.argv[2]||'/Users/Shared/Projects/RunnerHub/RoadRunners';
const s=readFileSync(source+'/evento/index.cfm','utf8');const block=s.slice(s.indexOf('<cfscript>',s.indexOf('<!--- STRUCTURED DATA --->')),s.indexOf('</cfscript>',s.indexOf('<!--- STRUCTURED DATA --->'))+11);
const scratch=mkdtempSync('/private/tmp/seo-rr-schema-test-');
try{
 mkdirSync(scratch+'/services');
 copyFileSync(source+'/services/EventRegistrationAvailability.cfc',scratch+'/services/EventRegistrationAvailability.cfc');
 writeFileSync(scratch+'/schema.cfm',block);
 writeFileSync(scratch+'/fixture.cfm',`<cfscript>
settings=getApplicationSettings();mappings=duplicate(settings.mappings);mappings['/services']=getDirectoryFromPath(getCurrentTemplatePath()) & 'services';application action='update' mappings=mappings;
VARIABLES.canonical="https://roadrunners.run/evento/prova/";VARIABLES.description="Descrição pública";REQUEST.currentBaseUrl="https://roadrunners.run";
qEvento={nome_evento="Prova",data_inicial=createDate(2026,10,10),data_final=createDate(2026,10,10),status_evento="",url_imagem="",endereco="",cidade="Salvador",estado="BA",pais="BR",coordenadas="",url_inscricao="https://inscricao.example/prova"};
qFornecedores=queryNew("id_fornecedor_tipo,nome_fornecedor,site_fornecedor", "integer,varchar,varchar", [{id_fornecedor_tipo=2,nome_fornecedor="Cronometrador",site_fornecedor=""},{id_fornecedor_tipo=1,nome_fornecedor="Organizador correto",site_fornecedor=""}]);
</cfscript><cfinclude template="schema.cfm"><cfset first=VARIABLES.structuredDataJsonLd><cfset qFornecedores=queryNew("id_fornecedor_tipo,nome_fornecedor,site_fornecedor", "integer,varchar,varchar", [{id_fornecedor_tipo=2,nome_fornecedor="Só cronometragem",site_fornecedor=""}])><cfinclude template="schema.cfm"><cfoutput>RR_SCHEMA_RESULTS:#serializeJSON([first,VARIABLES.structuredDataJsonLd])#</cfoutput>`);
 const r=spawnSync('/usr/bin/java',['-Xms128m','-Xmx512m','-Dfile.encoding=UTF-8','-cp','/Users/Shared/Projects/ColdFusion Certification/box','cliloader.LoaderCLIMain',`-CommandBox_home=${process.env.SEO_CONTENT_CFML_HOME}`,'execute','fixture.cfm'],{cwd:scratch,encoding:'utf8',timeout:60000,maxBuffer:2*1024*1024,env:{PATH:process.env.PATH,LC_ALL:'en_US.UTF-8'}});
 const output=r.stdout+'\n'+r.stderr;assert.equal(r.status,0,output);const match=output.match(/RR_SCHEMA_RESULTS:(\[[^\n]*\])/);assert.ok(match,output);const norm=v=>Array.isArray(v)?v.map(norm):v&&typeof v==="object"?Object.fromEntries(Object.entries(v).map(([k,x])=>[k.toLowerCase(),norm(x)])):v;const rows=JSON.parse(match[1]).map(v=>norm(JSON.parse(v)));
 assert.equal(rows[0].organizer.name,'Organizador correto');assert.equal(rows[1].organizer,undefined);assert.equal(rows[0].offers.availability,undefined);assert.equal(rows[0].offers.url,'https://inscricao.example/prova');
 console.log('CFML RR schema: event role selects organizer; date does not invent ticket availability');
}finally{rmSync(scratch,{recursive:true,force:true});}
