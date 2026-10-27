"""Post-publication read checks, authenticated dry run and activation of the one Teams job."""
import base64,json,pathlib,shlex,subprocess,sys
ROOT=pathlib.Path(__file__).resolve().parents[2];WORK=ROOT/'_codex/teams';mode=sys.argv[1]
if mode not in ['verify','activate']:raise SystemExit('Unknown mode')
publication=json.loads((WORK/'publication.json').read_text())
if not publication.get('ok'):raise SystemExit('Successful publication required')
BODY=r'''
<cfsetting requesttimeout="90" showdebugoutput="false"><cfscript>
if(!listFind('127.0.0.1,::1',CGI.remote_addr)||(CGI.http_x_teams_operation ?: '')!='__NONCE__'){cfheader(statuscode=404);abort;}
try {
 report={};svc=new services.teams.Service();report.ready=svc.ready();
 report.production_teams=queryExecute('SELECT count(*) n FROM rr_teams.team',{}, {datasource='runner_dba'}).n[1];
 report.fixture_teams=queryExecute('SELECT count(*) n FROM rr_teams_test.team',{}, {datasource='runner_dba'}).n[1];
 if(!report.ready||report.fixture_teams!=0)throw(type='Teams.Operation',message='Schema ou limpeza diferente do esperado');
 job=queryExecute("SELECT id_cron_job,ativo,next_run_at,auth_mode,secret_ref,http_method,request_body FROM public.tb_cron_jobs WHERE endpoint_url='https://business.roadrunners.run/teams/mail-worker.cfm'",{}, {datasource='runner_dba'});
 if(job.recordCount!=1||job.auth_mode[1]!='bearer'||job.secret_ref[1]!='business_ai_mails'||job.http_method[1]!='POST')throw(type='Teams.Operation',message='Job fora do escopo esperado');
 report.job_before={id=job.id_cron_job[1],active=job.ativo[1],next_run=job.next_run_at[1]};
 include '/includes/backend/cron_jobs_service.cfm';
 secret=structKeyExists(APPLICATION,'cronJobs')&&structKeyExists(APPLICATION.cronJobs,'runnerToken')?APPLICATION.cronJobs.runnerToken&'':'';
 report.scheduler_secret_matches=len(secret)>=20&&compare(cronJobsGetSecret('business_ai_mails'),secret)==0;
 if(!report.scheduler_secret_matches)throw(type='Teams.Operation',message='Referência existente do scheduler indisponível');
 cfhttp(method='POST',url='https://business.roadrunners.run/teams/mail-worker.cfm',timeout=40,throwOnError=false,result='teamWorkerHttp') {
  cfhttpparam(type='header',name='Authorization',value='Bearer '&secret);
  cfhttpparam(type='header',name='Content-Type',value='application/json');
  cfhttpparam(type='body',value='{"limit":1,"dryRun":true}');
 }
 response=teamWorkerHttp;result=isJSON(response.fileContent)?deserializeJSON(response.fileContent):{};
 report.worker_status=val(response.statusCode);
 report.authenticated_dry_run=report.worker_status==200&&structKeyExists(result,'success')&&result.success&&result.data.dryRun&&result.data.sent==0;
 if(!report.authenticated_dry_run)throw(type='Teams.Operation',message='Dry-run autenticado falhou');
 env=createObject('java','java.lang.System').getenv();businessLocalConfig={};
 if(fileExists(expandPath('/config/business.local.cfm')))include '/config/business.local.cfm';
 if(structKeyExists(VARIABLES,'businessLocalConfig')&&isStruct(VARIABLES.businessLocalConfig))structAppend(businessLocalConfig,VARIABLES.businessLocalConfig,true);
 report.email_configured=(structKeyExists(env,'RR_MANDRILL_USERNAME')&&len(env['RR_MANDRILL_USERNAME'])||structKeyExists(businessLocalConfig,'mandrillUsername')&&len(businessLocalConfig.mandrillUsername))&&(structKeyExists(env,'RR_MANDRILL_PASSWORD')&&len(env['RR_MANDRILL_PASSWORD'])||structKeyExists(businessLocalConfig,'mandrillPassword')&&len(businessLocalConfig.mandrillPassword));
 report.email_configured=report.email_configured?true:false;
 report.native_transport_configured=new services.teams.EmailTransport().configured();
 staff=queryExecute("SELECT id FROM public.tb_usuarios u WHERE is_admin=true AND NOT EXISTS(SELECT 1 FROM public.tb_usuarios_gestao g WHERE g.id_usuario=u.id AND (NOT coalesce(g.ativo,true) OR coalesce(g.excluido,false))) ORDER BY id LIMIT 1",{}, {datasource='runner_dba'}).id[1];
 REQUEST.businessIdentity={id=staff};
 transaction {try {savecontent variable='rendered' {include '/administracao/teams/index.cfm';}}finally {transaction action='rollback';}}
 report.published_global_panel=find('Gestão de Teams',rendered)>0&&find('Teams cadastrados',rendered)>0;
 if(!report.published_global_panel)throw(type='Teams.Operation',message='Painel publicado não renderizou');
 report.activated=false;
 if('__MODE__'=='activate'){
  if(!report.email_configured||!report.native_transport_configured)throw(type='Teams.Operation',message='Transporte de email não configurado');
  if(!isJSON(job.request_body[1])||deserializeJSON(job.request_body[1]).dryRun)throw(type='Teams.Operation',message='Corpo do job fora do esperado');
  transaction {
   queryExecute("UPDATE public.tb_cron_jobs SET ativo=true,next_run_at=(CURRENT_TIMESTAMP AT TIME ZONE 'UTC')+interval '5 minutes' WHERE id_cron_job=:id AND endpoint_url='https://business.roadrunners.run/teams/mail-worker.cfm' AND NOT ativo",{id={value=job.id_cron_job[1],cfsqltype='cf_sql_integer'}},{datasource='runner_dba'});
   report.activated=queryExecute('SELECT ativo FROM public.tb_cron_jobs WHERE id_cron_job=:id',{id={value=job.id_cron_job[1],cfsqltype='cf_sql_integer'}},{datasource='runner_dba'}).ativo[1];
   if(!report.activated)throw(type='Teams.Operation',message='Ativação não confirmada');
  }
 }
 report.ok=true;cfcontent(type='application/json; charset=utf-8',reset=true);writeOutput(serializeJSON(report));
}catch(any failed){cfheader(statuscode=500);cfcontent(type='application/json; charset=utf-8',reset=true);writeOutput(serializeJSON({ok=false,type=failed.type,message=failed.message}));}
</cfscript>
'''
REMOTE=r'''
import hashlib,json,os,pathlib,secrets,subprocess,sys
p=json.load(sys.stdin);root=pathlib.Path('/var/www');sites={'business':'business.roadrunners.run','rr':'roadrunners.com.br'}
for rel,want in p['hashes'].items():
 site,path=rel.split('/',1)
 if hashlib.sha256((root/sites[site]/path).read_bytes()).hexdigest()!=want:raise RuntimeError('Published file drift: '+rel)
stage=root/'business.roadrunners.run/_codex'/('teams_operation_'+secrets.token_hex(12));nonce=secrets.token_hex(24);backup=pathlib.Path(p['backup']);result={'ok':False}
try:
 stage.mkdir(mode=0o755);(stage/'.htaccess').write_text('Require local\n')
 body=p['body'].replace('__NONCE__',nonce).replace('__MODE__',p['mode']);(stage/'run.cfm').write_text(body,encoding='utf-8-sig');os.chmod(stage/'run.cfm',0o644)
 run=subprocess.run(['curl','-sS','--max-time','100','--resolve','business.roadrunners.run:443:127.0.0.1','-H','X-Teams-Operation: '+nonce,'https://business.roadrunners.run/_codex/'+stage.name+'/run.cfm'],capture_output=True,timeout=105)
 raw=run.stdout.decode(errors='replace');(backup/('operation-'+p['mode']+'-raw.json')).write_text(raw);os.chmod(backup/('operation-'+p['mode']+'-raw.json'),0o600)
 try:result={k.lower():v for k,v in json.loads(raw).items()}
 except ValueError:result={'ok':False,'error':'Unexpected operation response; private backup contains diagnostics'}
finally:
 if stage.exists():stage.rename(backup/('operation-'+p['mode']+'-source-'+stage.name))
 result['private_probe_removed']=not stage.exists();result['backup']=str(backup)
print(json.dumps(result))
'''
run=subprocess.run(['ssh','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-o','ConnectTimeout=12','rr-prod','python3 -c '+shlex.quote(REMOTE)],input=json.dumps({'mode':mode,'body':BODY,'hashes':publication['candidate_hashes'],'backup':publication['backup']}).encode(),capture_output=True,timeout=125)
try:result=json.loads(run.stdout)
except ValueError:result={'ok':False,'error':run.stderr.decode(errors='replace')[-2000:]}
(WORK/('operation-'+mode+'.json')).write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
print(json.dumps(result,ensure_ascii=False));raise SystemExit(0 if not run.returncode and result.get('ok') else 1)
