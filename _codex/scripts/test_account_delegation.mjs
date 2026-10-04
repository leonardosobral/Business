#!/usr/bin/env node
// Run real migrations/services against disposable synthetic accounts. No production config/DSNs are copied.
import {mkdtempSync,readFileSync,writeFileSync,existsSync,mkdirSync,cpSync,rmSync,realpathSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {resolve,dirname} from 'node:path';
import {fileURLToPath} from 'node:url';
import {spawn} from 'node:child_process';
import {createServer} from 'node:net';
import {loadCanonicalAdsFixture} from '../tests/ads-canonical-fixture.mjs';
import {runIntegrationHttp} from '../tests/account-delegation/http.mjs';
import {runEventsHttp} from '../tests/account-delegation/http-events.mjs';
import {runAdsHttp} from '../tests/account-delegation/http-ads.mjs';
import {runBoundaryHttp} from '../tests/account-delegation/http-boundary.mjs';
import {runReceiverHttp} from '../tests/account-delegation/http-receiver.mjs';
import {runWorkspaceHttp} from '../tests/account-delegation/http-workspace.mjs';
const root=resolve(dirname(fileURLToPath(import.meta.url)),'../..');
const suites=['schema','policy','lifecycle','accounts','boundary','receiver','workspace','ads-db','ads','events','http'];
const cli=process.argv.slice(2);
const suite=cli.length===2&&cli[0]==='--suite'?cli[1]:'';
if(![...suites,'all'].includes(suite)){console.error('Usage: test_account_delegation.mjs --suite '+[...suites,'all'].join('|'));process.exit(2);}
// Every suite owns a fresh database and servlet copy: role/schema mutations cannot leak.
if(suite==='all') {
 for(const selected of suites) {
  const status=await new Promise((done,reject)=>{const child=spawn(process.execPath,[fileURLToPath(import.meta.url),'--suite',selected],{stdio:'inherit',env:process.env});child.on('error',reject);child.on('close',done);});
  if(status!==0)process.exit(status||1);
 }
 console.log('PASS all isolated suites (0 skipped)');process.exit(0);
}
if(process.env.BUSINESS_DELEGATION_TEST_URL) {
 const target=new URL(process.env.BUSINESS_DELEGATION_TEST_URL);
 if(target.protocol!=='http:'||!['127.0.0.1','localhost','[::1]'].includes(target.hostname)||target.username||target.password)throw Error('Refusing external delegation test URL');
}
if(process.env.BUSINESS_DELEGATION_DSN && process.env.BUSINESS_DELEGATION_DSN!=='business_delegation_test'){console.error('Refusing non-isolated datasource');process.exit(2);}
const bin=process.env.BUSINESS_DELEGATION_PG_BIN||'/opt/homebrew/opt/postgresql@16/bin';
const box=process.env.BUSINESS_DELEGATION_BOX||'/Users/Shared/Projects/ColdFusion Certification/box';
const boxHome=process.env.BUSINESS_DELEGATION_BOX_HOME||'/private/tmp/seo-availability-cfml-20261003/commandbox';
for(const path of [resolve(bin,'initdb'),resolve(bin,'pg_ctl'),resolve(bin,'psql'),resolve(bin,'createdb'),box,resolve(boxHome,'lib/luceecli.jar')]){
 if(!existsSync(path)){console.error('Missing test runtime: '+path);process.exit(2);}
}
const scratch=mkdtempSync(resolve(tmpdir(),'business-delegation-'));
const env={PATH:process.env.PATH,LC_ALL:'C',TMPDIR:tmpdir(),RUNNERHUB_OFFLINE_CFML_TESTS:'1',BUSINESS_DELEGATION_DSN:'business_delegation_test'};
let startAttempted=false;
let cleanupPromise;
let interrupted=false;
const children=new Map();
function execute(command,args,input,extra={}){
 let child;
 const finished=new Promise(done=>{
  let stdout='',stderr='',failure;
  child=spawn(command,args,{env,cwd:resolve(scratch,'app'),stdio:['pipe','pipe','pipe'],...extra});
  const timer=setTimeout(()=>{failure=Error('Command timed out');child.kill('SIGKILL');},extra.timeout||120000);
  child.stdout.on('data',chunk=>stdout+=chunk);child.stderr.on('data',chunk=>stderr+=chunk);
  child.on('error',error=>failure=error);
  child.on('close',code=>{clearTimeout(timer);children.delete(child);done({status:code,stdout,stderr,error:failure});});
  child.stdin.on('error',()=>{});child.stdin.end(input);
 });
 children.set(child,finished);
 finished.child=child;
 return finished;
}
async function run(command,args,input,extra={}){
 if(interrupted)throw Error('Harness interrupted');
 const result=await execute(command,args,input,extra);
 if(result.status!==0)throw Error(`${command}: ${result.error||''}${result.stdout||''}${result.stderr||''}`);
 return result.stdout.trim();
}
function cleanup(){
 if(cleanupPromise)return cleanupPromise;
 cleanupPromise=(async()=>{
  // Only children launched by this harness and its private data directory are addressed.
  const pending=[...children.entries()];
  for(const [child] of pending)child.kill('SIGTERM');
  await Promise.all(pending.map(([,finished])=>finished));
  const data=resolve(scratch,'db');
  if(startAttempted){
   const pidFile=resolve(data,'postmaster.pid');
   if(existsSync(pidFile)){
    const recorded=readFileSync(pidFile,'utf8').split('\n')[1];
    if(!recorded||realpathSync(recorded)!==realpathSync(data))throw Error('Private cluster identity mismatch');
   }
   const status=await execute(resolve(bin,'pg_ctl'),['-D',data,'status'],undefined,{timeout:30000});
   if(status.status===0){
    const stopped=await execute(resolve(bin,'pg_ctl'),['-D',data,'-m','fast','-w','stop'],undefined,{timeout:30000});
    if(stopped.status!==0)throw Error(stopped.stderr||stopped.stdout||'Private cluster did not stop');
   }else if(status.status!==3)throw Error(status.stderr||status.stdout||'Private cluster status failed');
   if(existsSync(pidFile))throw Error('Private cluster PID remains after shutdown');
  }
  rmSync(scratch,{recursive:true,force:true});
  return true;
 })().catch(error=>{console.error('Cleanup failed; inspect '+scratch+': '+error.message);process.exitCode=1;return false;});
 return cleanupPromise;
}
for(const [signal,code] of [['SIGINT',130],['SIGTERM',143]])process.on(signal,async()=>{
 interrupted=true;
 const cleaned=await cleanup();
 process.exit(cleaned?code:1);
});

const pg=(name,args,input)=>run(resolve(bin,name),args,input);
const dbArgs=['-X','-qAt','-v','ON_ERROR_STOP=1','-h',scratch,'-U','business_delegation_test','-d','business_delegation_test'];
const sql=text=>pg('psql',dbArgs,text);
const file=path=>readFileSync(resolve(root,path),'utf8');
try {
 mkdirSync(resolve(scratch,'app/_codex/tests/account-delegation'),{recursive:true});
 await pg('initdb',['-D',resolve(scratch,'db'),'-U','business_delegation_test','-A','trust','--no-locale','-c','shared_memory_type=mmap','-c','dynamic_shared_memory_type=mmap']);
 const server=createServer();await new Promise(r=>server.listen(0,'127.0.0.1',r));const port=server.address().port;await new Promise(r=>server.close(r));
 env.BUSINESS_DELEGATION_TEST_PORT=String(port);
 startAttempted=true;
 await pg('pg_ctl',['-D',resolve(scratch,'db'),'-l',resolve(scratch,'postgres.log'),'-o',`-F -h 127.0.0.1 -p ${port} -k ${scratch}`,'-w','start']);
 await pg('createdb',['-h',scratch,'-p',String(port),'-U','business_delegation_test','business_delegation_test']);
 dbArgs.push('-p',String(port));
 await sql(`CREATE TYPE papel_usuario_conta AS ENUM('OWNER','ADMIN','OPERADOR','VISUALIZADOR','MEDICO');
 CREATE TABLE tb_usuarios(id integer PRIMARY KEY,name text,email text,is_admin boolean DEFAULT false,is_dev boolean DEFAULT false,is_partner boolean DEFAULT false);
 CREATE TABLE tb_contas(id_conta bigint PRIMARY KEY,nome_conta text,status text);
 CREATE TABLE tb_conta_usuarios(id_conta_usuario bigint PRIMARY KEY,id_conta bigint REFERENCES tb_contas,id_usuario integer REFERENCES tb_usuarios,papel papel_usuario_conta,status text,UNIQUE(id_conta,id_usuario));
 CREATE TABLE tb_conta_cadastro_solicitacoes(id_solicitacao bigint PRIMARY KEY,id_conta bigint REFERENCES tb_contas,id_usuario integer REFERENCES tb_usuarios,status text);
 CREATE TABLE tb_business_permissoes(id_permissao bigserial PRIMARY KEY,codigo varchar(100) NOT NULL UNIQUE,descricao varchar(255) NOT NULL,ativo boolean NOT NULL DEFAULT true,data_criacao timestamptz NOT NULL DEFAULT now(),data_atualizacao timestamptz NOT NULL DEFAULT now());`);
 const fixtureParts=file('_codex/tests/account-delegation/fixtures.sql').split('-- DELEGATION_FIXTURES');
 await sql(fixtureParts[0]);
 const migration=resolve(root,'_codex/sql/2026-10-03_business_account_delegation.sql');
 if(!existsSync(migration))throw Error('missing delegation schema: migration not implemented');
 await sql(readFileSync(migration,'utf8'));await sql(readFileSync(migration,'utf8'));
 if(existsSync(resolve(root,'services')))cpSync(resolve(root,'services'),resolve(scratch,'app/services'),{recursive:true});
 cpSync(resolve(root,'_codex/tests/account-delegation'),resolve(scratch,'app/_codex/tests/account-delegation'),{recursive:true});
 if(suite==='events'){
  cpSync(resolve(root,'eventos'),resolve(scratch,'app/eventos'),{recursive:true});
  cpSync(resolve(root,'includes/backend'),resolve(scratch,'app/includes/backend'),{recursive:true});
  cpSync(resolve(root,'includes/parts'),resolve(scratch,'app/includes/parts'),{recursive:true});
 }
 if(suite==='ads'||suite==='http'){
  cpSync(resolve(root,'ads'),resolve(scratch,'app/ads'),{recursive:true});
  cpSync(resolve(root,'portal/includes'),resolve(scratch,'app/portal/includes'),{recursive:true});
  mkdirSync(resolve(scratch,'app/includes/parts'),{recursive:true});
  cpSync(resolve(root,'includes/parts/business_delegation_form.cfm'),resolve(scratch,'app/includes/parts/business_delegation_form.cfm'));
 }
 if(suite==='workspace'||suite==='all'){
  cpSync(resolve(root,'gestao-clientes'),resolve(scratch,'app/gestao-clientes'),{recursive:true});
  mkdirSync(resolve(scratch,'app/administracao/contas/includes'),{recursive:true});
  for(const name of ['delegation_workspace_backend.cfm'])cpSync(resolve(root,'administracao/contas/includes',name),resolve(scratch,'app/administracao/contas/includes',name));
  for(const name of ['delegation_home.cfm','delegation_queue.cfm'])cpSync(resolve(root,'administracao/contas',name),resolve(scratch,'app/administracao/contas',name));
  mkdirSync(resolve(scratch,'app/includes/parts'),{recursive:true});
  cpSync(resolve(root,'includes/parts/business_delegation_form.cfm'),resolve(scratch,'app/includes/parts/business_delegation_form.cfm'));
 }
 if(suite==='accounts'||suite==='all') {
  mkdirSync(resolve(scratch,'app/administracao/contas/includes'),{recursive:true});
  for(const name of ['backend.cfm','delegation_backend.cfm']) if(existsSync(resolve(root,'administracao/contas/includes',name))) cpSync(resolve(root,'administracao/contas/includes',name),resolve(scratch,'app/administracao/contas/includes',name));
 }
 cpSync(resolve(root,'Application.cfc'),resolve(scratch,'app/ProductionApplication.cfc'));
 mkdirSync(resolve(scratch,'app/config'));
 writeFileSync(resolve(scratch,'app/Application.cfc'),'component { this.name="DelegationIsolated"; this.sessionManagement=true; }');
 const schemaCf=`
 assertThrowsType(function(){createObject("component","services.accountDelegation.Store").init("");},"BusinessDelegationDatasource","empty datasource is rejected");
 store=createObject("component","services.accountDelegation.Store").init("business_delegation_test");
 assertEqual(store.schemaReady(),true,"fully installed schema is ready");
 queryExecute("ALTER TABLE tb_conta_gestao_equipe DROP CONSTRAINT tb_conta_gestao_equipe_id_conta_usuario_fkey",{}, {datasource="business_delegation_test"});
 queryExecute("ALTER TABLE tb_conta_gestao_equipe ADD CONSTRAINT tb_conta_gestao_equipe_id_conta_usuario_fkey FOREIGN KEY(id_conta_usuario) REFERENCES tb_conta_usuarios(id_conta_usuario)",{}, {datasource="business_delegation_test"});
 assertEqual(store.schemaReady(),false,"membership FK without cascade fails closed");
 queryExecute("ALTER TABLE tb_conta_gestao_equipe DROP CONSTRAINT tb_conta_gestao_equipe_id_conta_usuario_fkey",{}, {datasource="business_delegation_test"});
 queryExecute("ALTER TABLE tb_conta_gestao_equipe ADD CONSTRAINT tb_conta_gestao_equipe_id_conta_usuario_fkey FOREIGN KEY(id_conta_usuario) REFERENCES tb_conta_usuarios(id_conta_usuario) ON DELETE CASCADE",{}, {datasource="business_delegation_test"});
 assertEqual(store.schemaReady(),true,"restored membership cascade is ready");
 queryExecute("DELETE FROM tb_business_delegacao_schema WHERE version=1",{}, {datasource="business_delegation_test"});
 assertEqual(store.schemaReady(),false,"missing version fails closed");
 queryExecute("INSERT INTO tb_business_delegacao_schema(version) VALUES(1)",{}, {datasource="business_delegation_test"});
 queryExecute("ALTER TABLE tb_conta_gestao_auditoria RENAME TO missing_audit",{}, {datasource="business_delegation_test"});
 assertEqual(store.schemaReady(),false,"missing required object fails closed");
 queryExecute("ALTER TABLE missing_audit RENAME TO tb_conta_gestao_auditoria",{}, {datasource="business_delegation_test"});
 queryExecute("ALTER INDEX uq_business_delegation_owner_pending RENAME TO missing_owner_index",{}, {datasource="business_delegation_test"});
 assertEqual(store.schemaReady(),false,"missing pending owner uniqueness fails closed");
 queryExecute("ALTER INDEX missing_owner_index RENAME TO uq_business_delegation_owner_pending",{}, {datasource="business_delegation_test"});
 queryExecute("DROP INDEX uq_business_delegation_owner_pending",{}, {datasource="business_delegation_test"});
 queryExecute("CREATE INDEX uq_business_delegation_owner_pending ON tb_conta_gestao_convites(id_conta,tipo) WHERE tipo='TITULAR' AND status='PENDENTE'",{}, {datasource="business_delegation_test"});
 assertEqual(store.schemaReady(),false,"same named nonunique owner index fails closed");
 queryExecute("DROP INDEX uq_business_delegation_owner_pending",{}, {datasource="business_delegation_test"});
 queryExecute("CREATE UNIQUE INDEX uq_business_delegation_owner_pending ON tb_conta_gestao_convites(id_conta,tipo) WHERE tipo='TITULAR' AND status='ACEITO'",{}, {datasource="business_delegation_test"});
 assertEqual(store.schemaReady(),false,"owner index with wrong predicate fails closed");
 queryExecute("DROP INDEX uq_business_delegation_owner_pending",{}, {datasource="business_delegation_test"});
 queryExecute("CREATE UNIQUE INDEX uq_business_delegation_owner_pending ON tb_conta_gestao_convites(id_conta,tipo) WHERE tipo='TITULAR' AND status='PENDENTE'",{}, {datasource="business_delegation_test"});
 assertEqual(store.schemaReady(),true,"restored unique pending owner index is ready");
 queryExecute("ALTER TABLE tb_conta_gestao_equipe DISABLE TRIGGER business_delegation_team_scope",{}, {datasource="business_delegation_test"});
 assertEqual(store.schemaReady(),false,"disabled scope trigger fails closed");
 queryExecute("ALTER TABLE tb_conta_gestao_equipe ENABLE TRIGGER business_delegation_team_scope",{}, {datasource="business_delegation_test"});
 assertEqual(store.schemaReady(),true,"restored enabled scope trigger is ready");
 queryExecute("DROP TRIGGER business_delegation_team_scope ON tb_conta_gestao_equipe",{}, {datasource="business_delegation_test"});
 queryExecute("CREATE TRIGGER business_delegation_team_scope BEFORE INSERT ON tb_conta_gestao_vinculos FOR EACH ROW EXECUTE FUNCTION business_delegation_team_scope()",{}, {datasource="business_delegation_test"});
 assertEqual(store.schemaReady(),false,"same named trigger on wrong table fails closed");
 queryExecute("DROP TRIGGER business_delegation_team_scope ON tb_conta_gestao_vinculos",{}, {datasource="business_delegation_test"});
 queryExecute("CREATE TRIGGER business_delegation_team_scope BEFORE INSERT OR UPDATE OF id_vinculo,id_conta_usuario ON tb_conta_gestao_equipe FOR EACH ROW EXECUTE FUNCTION business_delegation_team_scope()",{}, {datasource="business_delegation_test"});
 assertEqual(store.schemaReady(),true,"restored scope trigger target is ready");
 queryExecute("DROP TRIGGER business_delegation_grant_catalog ON tb_conta_gestao_permissoes",{}, {datasource="business_delegation_test"});
 queryExecute("CREATE TRIGGER business_delegation_grant_catalog BEFORE INSERT OR UPDATE OF id_permissao ON tb_conta_gestao_permissoes FOR EACH ROW EXECUTE FUNCTION business_delegation_team_scope()",{}, {datasource="business_delegation_test"});
 assertEqual(store.schemaReady(),false,"same named trigger with wrong function fails closed");
 queryExecute("DROP TRIGGER business_delegation_grant_catalog ON tb_conta_gestao_permissoes",{}, {datasource="business_delegation_test"});
 queryExecute("CREATE TRIGGER business_delegation_grant_catalog BEFORE INSERT OR UPDATE OF id_permissao ON tb_conta_gestao_permissoes FOR EACH ROW EXECUTE FUNCTION business_delegation_grant_catalog()",{}, {datasource="business_delegation_test"});
 assertEqual(store.schemaReady(),true,"restored catalog trigger function is ready");
 for (target in ["tb_conta_gestao_equipe","tb_conta_gestao_permissoes"]) {
  constraint=queryExecute("SELECT conname FROM pg_constraint WHERE conrelid=CAST('public.tb_conta_gestao_equipe_permissoes' AS regclass) AND confrelid=CAST(:target AS regclass) AND contype='f'",{target={value="public." & target,cfsqltype="cf_sql_varchar"}}, {datasource="business_delegation_test"});
  queryExecute("ALTER TABLE tb_conta_gestao_equipe_permissoes DROP CONSTRAINT " & constraint.conname[1],{}, {datasource="business_delegation_test"});
  assertEqual(store.schemaReady(),false,"removed containment FK to " & target & " fails closed");
  keyColumns=target=="tb_conta_gestao_equipe"?"id_equipe,id_vinculo":"id_vinculo,id_permissao";
  queryExecute("ALTER TABLE tb_conta_gestao_equipe_permissoes ADD CONSTRAINT " & constraint.conname[1] & " FOREIGN KEY(" & keyColumns & ") REFERENCES " & target & "(" & keyColumns & ") ON DELETE CASCADE NOT VALID",{}, {datasource="business_delegation_test"});
  assertEqual(store.schemaReady(),false,"unvalidated containment FK fails closed");
  queryExecute("ALTER TABLE tb_conta_gestao_equipe_permissoes VALIDATE CONSTRAINT " & constraint.conname[1],{}, {datasource="business_delegation_test"});
  assertEqual(store.schemaReady(),true,"restored validated containment FK is ready");
 }
 createObject("component","ProductionApplication").OnApplicationStart();
 assertEqual(application.businessAccountDelegationEnabled,expectedEnabled,"feature flag configuration");
 `;
 let delegationFixturesApplied=false;
 for(const selected of suite==='all'?suites:[suite]){
  if(selected==='schema') {
   console.log(await sql(file('_codex/tests/account-delegation/schema.sql')));
   await sql("ALTER TABLE tb_conta_gestao_equipe DROP CONSTRAINT tb_conta_gestao_equipe_id_conta_usuario_fkey; ALTER TABLE tb_conta_gestao_equipe ADD CONSTRAINT tb_conta_gestao_equipe_id_conta_usuario_fkey FOREIGN KEY(id_conta_usuario) REFERENCES tb_conta_usuarios(id_conta_usuario)");
   let incompatibleRejected=false;
   try {await sql(readFileSync(migration,'utf8'));} catch(error) {if(!error.message.includes('Incompatible delegation membership foreign key'))throw error;incompatibleRejected=true;}
   if(!incompatibleRejected)throw Error('Migration silently accepted incompatible membership foreign key');
   await sql("ALTER TABLE tb_conta_gestao_equipe DROP CONSTRAINT tb_conta_gestao_equipe_id_conta_usuario_fkey; ALTER TABLE tb_conta_gestao_equipe ADD CONSTRAINT tb_conta_gestao_equipe_id_conta_usuario_fkey FOREIGN KEY(id_conta_usuario) REFERENCES tb_conta_usuarios(id_conta_usuario) ON DELETE CASCADE");
   console.log('PASS schema incompatible membership FK refused without repair');
  }
  else if(!existsSync(resolve(root,`_codex/tests/account-delegation/${selected}.cfm`))&&!existsSync(resolve(root,`_codex/tests/account-delegation/${selected}.sql`)))throw Error('Missing suite '+selected);
  if(!delegationFixturesApplied){await sql(fixtureParts[1]);delegationFixturesApplied=true;}
  if(['ads-db','ads','http'].includes(selected)) {
   await sql(`CREATE ROLE runner LOGIN; CREATE ROLE runner_dba LOGIN;
    ALTER DATABASE business_delegation_test SET ads.paid_banner_test_fixture='isolated-local-v1';
    CREATE TABLE public.tb_evento_corridas(id_evento integer PRIMARY KEY,ativo boolean NOT NULL,estado text);
    CREATE TABLE public.tb_conta_eventos(id_conta bigint,id_evento integer,status text,PRIMARY KEY(id_conta,id_evento));
    CREATE TABLE public.tb_conta_evento_solicitacoes(id_conta bigint,id_evento integer,id_usuario_solicitante integer,status text);`);
   await loadCanonicalAdsFixture(sql,root);
   await sql(readFileSync(resolve(root,'../RoadRunners/_codex/sql/2026-09-16_ads_paid_banners.sql'),'utf8'));
   const adsMigration=resolve(root,'_codex/sql/2026-10-03_business_account_delegation_ads.sql');
   if(existsSync(adsMigration)) {
    const migrationText=readFileSync(adsMigration,'utf8');
    const baseline=JSON.parse(file('_codex/tests/account-delegation/ads-helper-baseline.json'));
    const actual=JSON.parse(await sql(`SELECT json_build_object('DEFINITION',pg_get_functiondef(oid),'OWNER_NAME',pg_get_userbyid(proowner),'ACL',proacl::text) FROM pg_proc WHERE oid='ads.paid_banner_actor_allowed(bigint,integer)'::regprocedure`));
    if(JSON.stringify(actual)!==JSON.stringify(baseline)) throw Error('Canonical fixture helper differs from recovered production baseline');
    const refused=async(text,pattern)=>{let rejected=false;try{await sql(text);}catch(error){if(!pattern.test(error.message))throw error;rejected=true;}if(!rejected)throw Error('Migration accepted invalid baseline/privilege');};
    await sql(`CREATE OR REPLACE FUNCTION ads.paid_banner_actor_allowed(p_account_id bigint,p_actor_id integer) RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog AS 'SELECT true'`);
    await refused(migrationText,/baseline drift/); await sql(baseline.DEFINITION);
    await sql('GRANT EXECUTE ON FUNCTION ads.paid_banner_actor_allowed(bigint,integer) TO PUBLIC');
    await refused(migrationText,/baseline drift/);await sql('REVOKE EXECUTE ON FUNCTION ads.paid_banner_actor_allowed(bigint,integer) FROM PUBLIC');
    await sql('ALTER FUNCTION ads.paid_banner_actor_allowed(bigint,integer) OWNER TO runner_dba');
    await refused(migrationText,/baseline drift/);await sql('ALTER FUNCTION ads.paid_banner_actor_allowed(bigint,integer) OWNER TO ads_owner');
    await sql('REVOKE SELECT ON public.tb_conta_gestoras FROM ads_owner');
    await refused(migrationText,/SELECT privilege missing/);await sql('GRANT SELECT ON public.tb_conta_gestoras TO ads_owner');
    await refused('SET ROLE runner_dba;'+migrationText,/replacement privilege required/);
    await sql(migrationText);
    await refused(migrationText,/baseline drift/);
    console.log('PASS ads-db recovered helper baseline, definition/owner/ACL drift, missing SELECT/replace privileges, repeat install refused');
   }
   if(selected==='ads'||selected==='http') {
    const campaignMigration=file('_codex/sql/2026-10-03_business_account_delegation_campaigns.sql');
    const rejectCampaign=async(text,pattern)=>{let rejected=false;try{await sql(text);}catch(error){if(!pattern.test(error.message))throw error;rejected=true;}if(!rejected)throw Error('Campaign migration accepted invalid baseline/privilege');};
    await sql('REVOKE EXECUTE ON FUNCTION ads.submit_campaign_review(uuid,bigint,integer,integer) FROM ads_business');
    await rejectCampaign(campaignMigration,/baseline drift/);
    await sql('GRANT EXECUTE ON FUNCTION ads.submit_campaign_review(uuid,bigint,integer,integer) TO ads_business');
    await rejectCampaign('SET ROLE runner_dba;'+campaignMigration,/privilege/);
    await sql(campaignMigration);await rejectCampaign(campaignMigration,/baseline drift/);
    for(const expected of JSON.parse(file('_codex/tests/account-delegation/ads-campaign-baseline.json'))){
      const installed=JSON.parse(await sql(`SELECT json_build_object('owner',pg_get_userbyid(proowner),'acl',proacl::text) FROM pg_proc WHERE pronamespace='ads'::regnamespace AND proname='${expected.PRONAME}'`));
      if(installed.owner!==expected.OWNER_NAME||installed.acl!==expected.ACL)throw Error('Campaign migration changed owner/ACL');
    }
    console.log('PASS ads campaign SQL baseline/ACL/privilege drift and reapply refused; owners/ACL preserved');
   }
   await sql(`CREATE ROLE runnerhub LOGIN; GRANT ads_business,ads_reader TO runnerhub;
    GRANT SELECT ON ads.account_balances,ads.campaign_budget_state TO runnerhub;
    GRANT SELECT,UPDATE ON ALL TABLES IN SCHEMA public TO runnerhub;
    GRANT INSERT ON public.tb_conta_gestao_auditoria TO runnerhub;
    GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO runnerhub;`);
  }
  const base=`<cfinclude template="_codex/tests/account-delegation/assertions.cfm"><cfscript>
  offlineEnv=createObject("java","java.lang.System").getenv();
  if(offlineEnv.get("BUSINESS_DELEGATION_DSN")!="business_delegation_test")throw(type="UnsafeTestDatasource",message="Refusing datasource");
  testMappings=duplicate(getApplicationSettings().mappings); testMappings["/services"]=expandPath("./services"); testMappings["/ads"]=expandPath("./ads"); testMappings["/delegationTests"]=expandPath("./_codex/tests/account-delegation");
  application action="update" mappings=testMappings datasources={runnerhub={class="org.postgresql.Driver",bundleName="org.postgresql.jdbc",bundleVersion="42.2.20",connectionString="jdbc:postgresql://127.0.0.1:${port}/business_delegation_test",username="runnerhub",password=""},business_delegation_test={class="org.postgresql.Driver",bundleName="org.postgresql.jdbc",bundleVersion="42.2.20",connectionString="jdbc:postgresql://127.0.0.1:${port}/business_delegation_test",username="business_delegation_test",password=""},business_delegation_runtime={class="org.postgresql.Driver",bundleName="org.postgresql.jdbc",bundleVersion="42.2.20",connectionString="jdbc:postgresql://127.0.0.1:${port}/business_delegation_test",username="runnerhub",password="",connectionLimit=1}};
  application.delegationTest={datasource="business_delegation_test",mailTransport="FAKE",paymentTransport="FAKE",root=expandPath(".")};
  expectedEnabled=${env.BUSINESS_ACCOUNT_DELEGATION_ENABLED==='true'||env.BUSINESS_ACCOUNT_DELEGATION_ENABLED==='1'?'true':'false'};
  ${selected==='schema'?schemaCf:''}
  </cfscript>${selected==='schema'?'':existsSync(resolve(root,`_codex/tests/account-delegation/${selected}.cfm`))?`<cfinclude template="_codex/tests/account-delegation/${selected}.cfm">`:''}<cfoutput>PASS ${selected} CFML#chr(10)#</cfoutput>`;
  if(selected!=='schema'&&existsSync(resolve(root,`_codex/tests/account-delegation/${selected}.sql`)))console.log(await sql(file(`_codex/tests/account-delegation/${selected}.sql`)));
  const checks=selected==='schema'?['default','local','env-false','env-true']:[selected];
  for(const check of checks){
   delete env.BUSINESS_ACCOUNT_DELEGATION_ENABLED;
   writeFileSync(resolve(scratch,'app/config/business.local.cfm'),check==='default'?'':'<cfset VARIABLES.businessLocalConfig={accountDelegationEnabled=true}/>');
   if(check==='env-false')env.BUSINESS_ACCOUNT_DELEGATION_ENABLED='false';
   if(check==='env-true')env.BUSINESS_ACCOUNT_DELEGATION_ENABLED='true';
   writeFileSync(resolve(scratch,'app/run.cfm'),base.replace(/expectedEnabled=(?:true|false);/,`expectedEnabled=${check==='local'||check==='env-true'};`));
   const output=selected==='events'?await runEventsHttp({root,scratch,port,boxHome,execute,sql}):await run('/usr/bin/java',['-cp',box,'cliloader.LoaderCLIMain',`-CommandBox_home=${boxHome}`,'execute','run.cfm']);
   if(!output.includes(`PASS ${selected} CFML`))throw Error('CFML suite failed: '+output);
   if(['policy','accounts','ads-db','ads'].includes(selected)) for(const line of output.split(/\r?\n/)) if(line.startsWith(`PASS ${selected} `)) console.log(line);
   console.log(`PASS ${selected} CFML ${check}`);
  }
  if(selected==='http') await runIntegrationHttp({root,scratch,port,boxHome,execute,sql,env});
  if(selected==='ads') await runAdsHttp({root,scratch,port,boxHome,execute,sql});
  if(selected==='boundary') await runBoundaryHttp({root,scratch,port,boxHome,execute,sql,env});
  if(selected==='receiver') await runReceiverHttp({root,scratch,port,boxHome,execute,sql,env});
  if(selected==='workspace') await runWorkspaceHttp({root,scratch,port,boxHome,execute});
  console.log('PASS '+selected);
 }
} catch(error){console.error('FAIL '+suite+': '+error.message);process.exitCode=1;}
finally {
 await cleanup();
}
