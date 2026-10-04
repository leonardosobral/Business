import assert from 'node:assert/strict';
import {mkdtempSync,mkdirSync,copyFileSync,writeFileSync,readFileSync,rmSync} from 'node:fs';
import {spawnSync} from 'node:child_process';
import {userInfo} from 'node:os';
const port=process.env.SEO_AVAILABILITY_TEST_PG_PORT;
assert.ok(/^\d+$/.test(port||''),'Set SEO_AVAILABILITY_TEST_PG_PORT for the disposable localhost database');
const scratch=mkdtempSync('/private/tmp/seo-registration-persistence-');
try {
 mkdirSync(scratch+'/services');
 for(const n of ['EventRegistrationAvailability','EventRegistrationAvailabilityService'])copyFileSync('services/'+n+'.cfc',scratch+'/services/'+n+'.cfc');
 copyFileSync('_codex/sql/2026-10-03_event_registration_availability.sql',scratch+'/migration.sql');
 const backend=readFileSync('eventos/includes/backend/event_mutations.cfm','utf8');
 const at=backend.indexOf('UPDATE tb_evento_corridas\n');
 const qStart=backend.lastIndexOf('<cfquery',at);
 writeFileSync(scratch+'/basic-update.cfm','<cffunction name="runBasicUpdate" output="false"><cfargument name="fresh" required="true"/><cfargument name="state" required="true"/>'+backend.slice(qStart,backend.indexOf('</cfquery>',at)+10)+'</cffunction><cfset runBasicUpdate({datasource="runner_dba"},VARIABLES)/>');
 writeFileSync(scratch+'/fixture.cfm',`<cfscript>
settings=getApplicationSettings();mappings=duplicate(settings.mappings);mappings['/services']=getDirectoryFromPath(getCurrentTemplatePath()) & 'services';
application action='update' mappings=mappings datasource='runner_dba' datasources={runner_dba={class='org.postgresql.Driver',bundleName='org.postgresql.jdbc',bundleVersion='42.2.20',connectionString='jdbc:postgresql://127.0.0.1:${port}/postgres',username='${userInfo().username}',password=''}};
queryExecute('DROP TABLE IF EXISTS public.tb_log');queryExecute('DROP TABLE IF EXISTS public.tb_evento_corridas');
queryExecute("CREATE TABLE public.tb_evento_corridas(id_evento integer PRIMARY KEY,url_inscricao text,status_evento text,data_final date,nome_evento text,cidade text,cod_cidade integer,estado text,data_inicial date,tag text,tipo_corrida text,endereco text,coordenadas text,url_hotsite text)");
queryExecute("CREATE TABLE public.tb_log(log_item text,log_item_id text,log_user text,site text)");
queryExecute("INSERT INTO public.tb_evento_corridas(id_evento,url_inscricao,status_evento,data_final) VALUES (1,'https://inscricao.example/prova','','2099-10-10'),(2,'https://inscricao.example/outra','','2099-10-10')");
service=new services.EventRegistrationAvailabilityService();checks={missingSchema=!service.isSchemaReady()};
transaction {queryExecute(fileRead('migration.sql'));}transaction {queryExecute(fileRead('migration.sql'));}
checks.schemaReady=service.isSchemaReady();
base={status='open',source_url='https://organizador.example/prova',registration_url='https://inscricao.example/prova',confirmed='1'};
service.save(1,99,base,true,true,true,'127.0.0.1');
q=queryExecute('SELECT inscricao_disponibilidade FROM public.tb_evento_corridas WHERE id_evento=1');first=deserializeJSON(q.inscricao_disponibilidade[1]);checks.storedOpen=first.status EQ 'open' AND first.registration_url EQ base.registration_url AND first.source_url EQ base.source_url AND abs(first.checked_at-int(createObject('java','java.lang.System').currentTimeMillis()/1000)) LTE 3;
q=queryExecute('SELECT count(*) AS n FROM public.tb_evento_corridas WHERE id_evento=2 AND inscricao_disponibilidade IS NULL');checks.otherEventUntouched=q.n[1] EQ 1;
changed=duplicate(base);changed.registration_url='https://inscricao.example/changed';checks.changedRejected=false;try{service.save(1,99,changed,true,true,true);}catch(RegistrationAvailability rejected){checks.changedRejected=true;}
queryExecute("UPDATE public.tb_evento_corridas SET status_evento='cancelado' WHERE id_evento=1");checks.cancelledRejected=false;try{service.save(1,99,base,true,true,true);}catch(RegistrationAvailability rejected){checks.cancelledRejected=true;}
queryExecute("UPDATE public.tb_evento_corridas SET status_evento='',data_final='2020-01-01' WHERE id_evento=1");checks.pastRejected=false;try{service.save(1,99,base,true,true,true);}catch(RegistrationAvailability rejected){checks.pastRejected=true;}
queryExecute("UPDATE public.tb_evento_corridas SET data_final='2099-10-10' WHERE id_evento=1");
for(s in ['sold_out','preorder','closed']){base.status=s;service.save(1,99,base,true,true,true);q=queryExecute('SELECT inscricao_disponibilidade FROM public.tb_evento_corridas WHERE id_evento=1');checks['stored_' & s]=deserializeJSON(q.inscricao_disponibilidade[1]).status EQ s;}
q=queryExecute('SELECT inscricao_disponibilidade::text AS saved FROM public.tb_evento_corridas WHERE id_evento=1');before=q.saved[1];queryExecute('ALTER TABLE public.tb_log RENAME COLUMN log_item TO unavailable_log_item');base.status='open';checks.logFailureRejected=false;try{service.save(1,99,base,true,true,true);}catch(any rejected){checks.logFailureRejected=true;}
q=queryExecute('SELECT inscricao_disponibilidade::text AS saved FROM public.tb_evento_corridas WHERE id_evento=1');checks.auditRollback=compare(q.saved[1],before) EQ 0;queryExecute('ALTER TABLE public.tb_log RENAME COLUMN unavailable_log_item TO log_item');
structAppend(FORM,{id_evento=1,nome_evento='Prova',estado='BA',data_inicial='2099-10-10',data_final='2099-10-10',tipo_corrida='rua',endereco='',coordenadas='',url_inscricao=base.registration_url,url_hotsite=''},true);qCidade={nome_cidade='Salvador',cod_cidade=1,uf='BA'};VARIABLES.adminEventoResolvedTag='prova';VARIABLES.inscricaoBasicSchemaReady=true;
</cfscript><cfinclude template='basic-update.cfm'><cfscript>
q=queryExecute('SELECT inscricao_disponibilidade::text AS saved FROM public.tb_evento_corridas WHERE id_evento=1');checks.sameLinkKeepsConfirmation=compare(q.saved[1],before) EQ 0;
FORM.url_inscricao='https://inscricao.example/alterada';</cfscript><cfinclude template='basic-update.cfm'><cfscript>
q=queryExecute('SELECT count(*) AS n FROM public.tb_evento_corridas WHERE id_evento=1 AND inscricao_disponibilidade IS NULL');checks.linkEditClears=q.n[1] EQ 1;
base.status='unknown';service.save(1,99,base,true,true,true);q=queryExecute('SELECT count(*) AS n FROM public.tb_evento_corridas WHERE id_evento=1 AND inscricao_disponibilidade IS NULL');checks.unknownClears=q.n[1] EQ 1;
q=queryExecute('SELECT count(*) AS n FROM public.tb_log');checks.auditCount=q.n[1] EQ 5;
writeOutput('PERSISTENCE_RESULTS:' & serializeJSON(checks));
queryExecute('DROP TABLE public.tb_log');queryExecute('DROP TABLE public.tb_evento_corridas');
</cfscript>`);
 const r=spawnSync('/usr/bin/java',['-Xms128m','-Xmx512m','-Dfile.encoding=UTF-8','-cp','/Users/Shared/Projects/ColdFusion Certification/box','cliloader.LoaderCLIMain','-CommandBox_home=/private/tmp/seo-availability-cfml-20261003/commandbox','execute','fixture.cfm'],{cwd:scratch,encoding:'utf8',timeout:60000,maxBuffer:3e6,env:{PATH:process.env.PATH,LC_ALL:'en_US.UTF-8'}});
 assert.equal(r.status,0,r.stdout+r.stderr);const m=r.stdout.match(/PERSISTENCE_RESULTS:(\{[^\n]*\})/);assert.ok(m,r.stdout);
 const checks=JSON.parse(m[1]);for(const [name,value] of Object.entries(checks))assert.equal(value,true,name);
 console.log('CFML/PostgreSQL persistence: '+Object.keys(checks).length+' checks passed.');
}finally{rmSync(scratch,{recursive:true,force:true});}
