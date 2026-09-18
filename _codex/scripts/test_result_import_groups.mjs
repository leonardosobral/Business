import assert from 'node:assert/strict';
import {existsSync,readFileSync,mkdtempSync,rmSync,mkdirSync,copyFileSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {resolve,dirname} from 'node:path';
import {spawnSync} from 'node:child_process';
const source=resolve('services/queries/result_import_context.sql');
assert.ok(existsSync(source),'A fila deve compartilhar a identificação e o corte das submissões com o processador');
const context=readFileSync(source,'utf8');
const archive=readFileSync('services/queries/result_import_archive.sql','utf8');
const scratch=mkdtempSync(resolve(tmpdir(),'result-import-pg-'));
const bin='/opt/homebrew/opt/postgresql@16/bin';
function run(name,args,input){const r=spawnSync(resolve(bin,name),args,{input,encoding:'utf8',timeout:60000,env:{PATH:process.env.PATH,LC_ALL:'C',TMPDIR:tmpdir()}});if(r.status!==0)process.stderr.write(JSON.stringify({tool:name,status:r.status,error:String(r.error||''),stderr:r.stderr,stdout:r.stdout}));assert.equal(r.status,0,r.stdout+r.stderr);return r.stdout.trim();}
const sql=s=>run('psql',['-X','-qAt','-v','ON_ERROR_STOP=1','-h',scratch,'-p',pgPort,'-U','postgres','-d','postgres'],s);
function bind(s,p={}){for(const [k,v] of Object.entries({unscoped:true,account_id:0,...p}))s=s.replace(new RegExp(`(?<!:):${k}\\b`,'g'),typeof v==='string'?`'${v.replaceAll("'","''")}'`:String(v));return s;}
const rows=(p={})=>JSON.parse(sql(bind(context+' SELECT coalesce(json_agg(r ORDER BY id_resultado_importacao),\'[]\') FROM result_import_context r',p)));
let started=false;
const pgPort=String(55600+process.pid%200);
try {
 run('initdb',['-D',resolve(scratch,'data'),'-U','postgres','-A','trust','--no-locale','--encoding=UTF8']);
 run('pg_ctl',['-D',resolve(scratch,'data'),'-l',resolve(scratch,'log'),'-o',`-F -k ${scratch} -h 127.0.0.1 -p ${pgPort}`,'-w','start']);started=true;
 sql(`CREATE TABLE tb_resultados_importacoes(id_resultado_importacao bigint PRIMARY KEY,public_id uuid,id_evento integer,client_id text DEFAULT 'timer-racezone',cod_timer text DEFAULT 'racezone',external_account_id text,external_event_id text,url_resultado text,url_resultado_publica text,status_processamento text DEFAULT 'pendente',data_recebimento timestamp,data_processamento timestamp,data_atualizacao timestamp,erro_codigo text,erro_detalhe text);
 CREATE TABLE tb_evento_corridas(id_evento integer PRIMARY KEY,nome_evento text,tag text,cidade text,estado text,data_inicial date,ativo boolean DEFAULT true,url_resultado text,url_wiclax text);
 CREATE TABLE tb_conta_integracoes_resultados(id_conta bigint,ativo boolean,client_id text,cod_timer text,external_account_id text,abrange_contas_externas boolean);
 INSERT INTO tb_conta_integracoes_resultados VALUES(1,true,'timer-racezone','racezone',NULL,false),(2,true,'timer-racezone','racezone','B',false),(3,false,'timer-racezone','racezone',NULL,true);
 INSERT INTO tb_evento_corridas(id_evento,nome_evento,url_resultado,url_wiclax) VALUES(42,'Setembro Amarelo','https://results.example/racezone/#/setembro-2026','https://results.example/racezone/data/ABC/event.json'),(43,'Outra conta','https://results.example/other/#/setembro-2026',NULL);
 INSERT INTO tb_resultados_importacoes(id_resultado_importacao,public_id,url_resultado,url_resultado_publica,data_recebimento)
 SELECT n,('00000000-0000-4000-8000-'||lpad(n::text,12,'0'))::uuid,'https://results.example/racezone/data/ABC/event.json','https://results.example/racezone/#/setembro-2026',timestamp '2026-09-14 10:40'+n*interval '1 minute' FROM generate_series(1,6)n;
 UPDATE tb_resultados_importacoes SET status_processamento='processado',id_evento=42,external_event_id='ABC',data_processamento='2026-09-14 11:00' WHERE id_resultado_importacao=4;
 UPDATE tb_resultados_importacoes SET status_processamento='falhou' WHERE id_resultado_importacao=2;
 UPDATE tb_resultados_importacoes SET status_processamento='processando' WHERE id_resultado_importacao=3;
 INSERT INTO tb_resultados_importacoes SELECT 7,'00000000-0000-4000-8000-000000000007',NULL,client_id,cod_timer,'B',external_event_id,url_resultado,url_resultado_publica,'pendente',data_recebimento,NULL,NULL,NULL,NULL FROM tb_resultados_importacoes WHERE id_resultado_importacao=1;
 INSERT INTO tb_resultados_importacoes SELECT 8,'00000000-0000-4000-8000-000000000008',NULL,'other-client',cod_timer,NULL,external_event_id,url_resultado,url_resultado_publica,'pendente',data_recebimento,NULL,NULL,NULL,NULL FROM tb_resultados_importacoes WHERE id_resultado_importacao=1;
 INSERT INTO tb_resultados_importacoes SELECT 9,'00000000-0000-4000-8000-000000000009',NULL,client_id,'other-timer',NULL,external_event_id,url_resultado,url_resultado_publica,'pendente',data_recebimento,NULL,NULL,NULL,NULL FROM tb_resultados_importacoes WHERE id_resultado_importacao=1;`);
 let r=rows();
 assert.deepEqual(r.slice(0,6).map(x=>x.queue_status),['arquivado','arquivado','processando','processado','pendente','pendente'],'cutoff uses receipt order, never completion time; running work is untouched');
 assert.equal(new Set(r.slice(0,6).map(x=>x.event_group)).size,1,'filling external_event_id after processing cannot split a URL group');
 assert.equal(new Set(r.map(x=>x.event_group)).size,4,'client, timer and external account are independent scopes');
 assert.equal(r[5].suggested_event_id,42,'successful historical linkage is reused without external_event_id');
 assert.equal(r[6].queue_status,'pendente');assert.equal(r[7].queue_status,'pendente');assert.equal(r[8].queue_status,'pendente');
 assert.deepEqual(rows({unscoped:false,account_id:1}).map(x=>x.id_resultado_importacao),[1,2,3,4,5,6]);
 assert.deepEqual(rows({unscoped:false,account_id:2}).map(x=>x.id_resultado_importacao),[7]);
 assert.equal(rows({unscoped:false,account_id:3}).length,0);
 sql(`ALTER TABLE tb_resultados_importacoes ADD COLUMN status_publicacao text DEFAULT 'atualizacao', ADD COLUMN open_results_enabled boolean DEFAULT true, ADD COLUMN id_evento_informado integer, ADD COLUMN tag_evento_informada text, ADD COLUMN idempotency_key text DEFAULT 'fixture', ADD COLUMN tentativas integer DEFAULT 0, ADD COLUMN total_resultados integer, ADD COLUMN data_inicio timestamp;
 UPDATE tb_resultados_importacoes SET open_results_enabled=false WHERE id_resultado_importacao=6;`);
 const box='/Users/Shared/Projects/ColdFusion Certification/box';
 const boxHome='/private/tmp/runnerhub-audience-cfml.j0MZzV/commandbox';
 const renderRoot=mkdtempSync(resolve(tmpdir(),'result-import-render-'));
 for(const name of ['services/ResultImportQueueService.cfc','services/queries/result_import_context.sql','services/queries/result_import_archive.sql','administracao/importacoes-resultados/home.cfm','administracao/importacoes-resultados/includes/backend.cfm','racetag/includes/backend.cfm','racetag/form.cfm','assets/js/result-import-queue.js','assets/css/mdb.min.css','assets/css/business-ui.css']) {
   mkdirSync(dirname(resolve(renderRoot,name)),{recursive:true});copyFileSync(resolve(name),resolve(renderRoot,name));
 }
 copyFileSync('_codex/tests/result-import-groups.cfm',resolve(renderRoot,'test.cfm'));
 copyFileSync('_codex/tests/racetag-candidates.cfm',resolve(renderRoot,'racetag-candidates.cfm'));
 copyFileSync('_codex/tests/result-import-default-filter.cfm',resolve(renderRoot,'result-import-default-filter.cfm'));
 const cf=spawnSync('/usr/bin/java',['-Dfile.encoding=UTF-8','-cp',box,'cliloader.LoaderCLIMain',`-CommandBox_home=${boxHome}`,'execute','test.cfm'],{cwd:renderRoot,encoding:'utf8',timeout:60000,env:{PATH:process.env.PATH,TMPDIR:tmpdir(),RESULT_IMPORT_TEST_PORT:pgPort}});
 if(cf.status!==0)process.stderr.write(cf.stdout+cf.stderr);
 assert.equal(cf.status,0,cf.stdout+cf.stderr);
 assert.match(cf.stdout,/PASS: CFML service/);
 console.log(cf.stdout.trim());console.log(`Rendered UI: ${renderRoot}/rendered.html`);
 // Archive is the exact production UPDATE. Foreign scope, later and running rows survive.
 const doArchive=(p={})=>sql(bind(context+archive,{submission_id:'00000000-0000-4000-8000-000000000004',...p}));
 assert.equal(doArchive({unscoped:false,account_id:2}),'');
 assert.deepEqual(doArchive().split('\n').sort(),['1','2']);
 assert.equal(sql('SELECT count(*) FROM tb_resultados_importacoes'), '9','archive must preserve records and IDs');
 assert.equal(doArchive(),'','archiving is idempotent');
 assert.equal(rows()[0].queue_status,'arquivado');
 // URL-only catalog resolution and ambiguity; exact URLs, not a suffix LIKE match.
 sql(`UPDATE tb_resultados_importacoes SET id_evento=NULL,status_processamento='pendente',erro_codigo=NULL;
 UPDATE tb_evento_corridas SET url_wiclax=NULL;
 INSERT INTO tb_evento_corridas(id_evento,nome_evento,url_resultado) VALUES(44,'Mesmo slug, outro provedor','https://elsewhere.example/#/setembro-2026');`);
 assert.equal(rows()[0].suggested_event_id,42);
 sql(`INSERT INTO tb_evento_corridas(id_evento,nome_evento,url_resultado) VALUES(45,'Duplicado','https://results.example/racezone/#/setembro-2026/');`);
 assert.equal(rows()[0].suggested_event_id,null,'ambiguous URL mapping is not automatically selected');
 sql(`UPDATE tb_evento_corridas SET ativo=false WHERE id_evento=45;`);
 assert.equal(rows()[0].suggested_event_id,42);
 // Exact timestamp ties use the sequence as a deterministic arrival order.
 sql(`UPDATE tb_resultados_importacoes SET data_recebimento='2026-09-14 10:44'; UPDATE tb_resultados_importacoes SET status_processamento='processado',id_evento=42 WHERE id_resultado_importacao=4;`);
 assert.deepEqual(rows().slice(0,6).map(x=>x.queue_status),['arquivado','arquivado','arquivado','processado','pendente','pendente']);
 assert.equal(sql('SELECT count(*) FROM tb_resultados_importacoes'),'9','reading the context does not mutate backlog');
 sql(`UPDATE tb_resultados_importacoes SET url_resultado='https://results.example/company/',url_resultado_publica='https://results.example/company/',external_event_id=NULL;
 UPDATE tb_resultados_importacoes SET external_event_id='A' WHERE id_resultado_importacao=1;
 UPDATE tb_resultados_importacoes SET external_event_id='B' WHERE id_resultado_importacao=4;`);
 const generic=rows();
 assert.notEqual(generic[0].event_group,generic[3].event_group,'generic provider URLs cannot override distinct external IDs');
 assert.notEqual(generic[1].event_group,generic[2].event_group,'generic sources with no identity stay isolated');
 assert.equal(generic[0].queue_status,'pendente','processing event B cannot archive event A');
 console.log('PASS: scoped grouping, receipt cutoff/ties, URL matching, ambiguity, historical links, archive effects and idempotence');
} finally {if(started)run('pg_ctl',['-D',resolve(scratch,'data'),'-m','fast','-w','stop']);rmSync(scratch,{recursive:true,force:true});}
