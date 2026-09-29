"""Run scoped CRM DDL/activation or read-only smoke checks via a one-use loopback probe."""
from pathlib import Path
import base64, hashlib, json, secrets, shlex, subprocess, sys
ROOT=Path(__file__).resolve().parents[2];LEDGER=ROOT/'.superpowers/sdd/2026-09-24-crm-interno'
SSH=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
mode=sys.argv[1];assert mode in ('migrate','smoke','client_smoke','jobs_fix','worker_smoke','enable','disable','filters_smoke','counts_smoke','program_smoke','program_worker_smoke','program_job_install','program_job_enable','program_job_pause','program_job_verify','program_history_baseline','program_history_diagnostic')
if mode=='program_job_enable':
    smoke=json.loads((LEDGER/'production-program_worker_smoke.json').read_text())
    smoke={str(k).lower():v for k,v in smoke.items()}
    if smoke.get('signed_status')!=200 or smoke.get('unsigned_status')!=403 or smoke.get('success') is not True or smoke.get('failed')!=0:
        raise SystemExit('matching signed worker smoke required before enabling commerce job')
nonce=secrets.token_hex(32);name='__crm_release_'+secrets.token_hex(12)+'.cfm'
header="""<cfsetting showdebugoutput="false" requesttimeout="110"><cfscript>
req=getHttpRequestData(false);if(!listFind('127.0.0.1,::1',CGI.REMOTE_ADDR)||!structKeyExists(req.headers,'X-CRM-Probe')||req.headers['X-CRM-Probe']!='NONCE'){cfheader(statuscode=404);abort;}
function scalar(sql){return queryExecute(sql,{},{datasource='runner_dba',timeout=30});}
try {report={};
""".replace('NONCE',nonce)
if mode=='migrate':
 sql=(ROOT.parent/'RoadRunners/_codex/sql/migrations/2026-09-24_crm_interno.sql').read_text()+'\n'+(ROOT/'administracao/cron-jobs/crm_interno_jobs.sql').read_text()
 body="""if(scalar("SELECT to_regnamespace('crm_interno') IS NOT NULL AS present").present)throw(message='CRM schema already exists; migration requires a reviewed receipt');
+scalar(toString(binaryDecode('PAYLOAD','base64')));report={migrated=true,enabled=scalar("SELECT value FROM crm_interno.settings WHERE key='enabled'").value,campaigns=scalar('SELECT count(*) n FROM crm_interno.campaigns').n,jobs=scalar("SELECT count(*) n FROM tb_cron_jobs WHERE endpoint_url IN ('https://business.roadrunners.run/api/crm-interno-notifications.cfm','https://business.roadrunners.run/api/crm-interno-email.cfm') AND NOT ativo").n};
""".replace('\n+','\n').replace('PAYLOAD',base64.b64encode(sql.encode()).decode())
elif mode=='jobs_fix':
 body="""transaction {scalar("UPDATE tb_cron_jobs SET endpoint_url='https://business.roadrunners.run/api/crm-interno-notifications.cfm',request_body=CAST(json_build_object('scope','crm.notifications.worker','environment','prod') AS text),secret_ref='business_ai_mails' WHERE endpoint_url='https://roadrunners.run/api/crm-interno/worker.cfm' AND NOT ativo");scalar("UPDATE tb_cron_jobs SET secret_ref='business_ai_mails' WHERE endpoint_url='https://business.roadrunners.run/api/crm-interno-email.cfm' AND NOT ativo");}report.updated=true;"""
elif mode=='client_smoke':
 body="""mailEnv=createObject('java','java.lang.System').getenv();businessLocalConfig={};if(fileExists(expandPath('/config/business.local.cfm')))include '/config/business.local.cfm';report.email_transport_configured=(structKeyExists(mailEnv,'RR_MANDRILL_USERNAME')&&len(mailEnv['RR_MANDRILL_USERNAME'])||structKeyExists(businessLocalConfig,'mandrillUsername')&&len(businessLocalConfig.mandrillUsername))&&(structKeyExists(mailEnv,'RR_MANDRILL_PASSWORD')&&len(mailEnv['RR_MANDRILL_PASSWORD'])||structKeyExists(businessLocalConfig,'mandrillPassword')&&len(businessLocalConfig.mandrillPassword));report.secure_client_secret=len(APPLICATION.notificationDispatch.secret)&&compareNoCase(APPLICATION.notificationDispatch.secret,hash('RoadRunners::handoff::roadrunners.run::v1','SHA-256'))!=0;
 actor=scalar("SELECT u.id FROM tb_usuarios u WHERE (u.is_admin OR u.is_dev) AND NOT EXISTS(SELECT 1 FROM tb_usuarios_gestao g WHERE g.id_usuario=u.id AND (NOT g.ativo OR g.excluido)) ORDER BY u.id LIMIT 1").id;
 include '/includes/backend/cron_jobs_service.cfm';report.matching_scheduler_refs=[];if(structKeyExists(APPLICATION,'cronJobs')&&structKeyExists(APPLICATION.cronJobs,'secrets'))for(ref in APPLICATION.cronJobs.secrets)if(compare(cronJobsGetSecret(ref),APPLICATION.notificationDispatch.secret)==0)arrayAppend(report.matching_scheduler_refs,ref);if(structKeyExists(businessLocalConfig,'cronSecrets'))for(ref in businessLocalConfig.cronSecrets)if(compare(cronJobsGetSecret(ref),APPLICATION.notificationDispatch.secret)==0&&!arrayFind(report.matching_scheduler_refs,ref))arrayAppend(report.matching_scheduler_refs,ref);report.crm_scheduler_ready=structKeyExists(APPLICATION,'cronJobs')&&len(APPLICATION.cronJobs.runnerToken)>0&&compare(cronJobsGetSecret('business_ai_mails'),APPLICATION.cronJobs.runnerToken)==0;report.scheduler_secret_matches=compare(cronJobsGetSecret('road_runners_handoff'),APPLICATION.notificationDispatch.secret)==0;report.email_transport_configured=report.email_transport_configured?true:false;
 report.response=new services.CrmClient().init(APPLICATION.notificationDispatch).request('catalog',{},actor);"""
elif mode=='program_smoke':
 body="""actor=scalar("SELECT u.id FROM tb_usuarios u WHERE (u.is_admin OR u.is_dev) AND NOT EXISTS(SELECT 1 FROM tb_usuarios_gestao g WHERE g.id_usuario=u.id AND (NOT g.ativo OR g.excluido)) ORDER BY u.id LIMIT 1").id;
 before=scalar('SELECT count(*) AS n FROM crm_interno.deliveries').n;
 crmClient=new services.CrmClient().init(APPLICATION.notificationDispatch);
 period={from=dateFormat(dateAdd('d',-30,now()),'yyyy-mm-dd'),to=dateFormat(now(),'yyyy-mm-dd'),bucket='week'};
 overview=crmClient.request('programs.report',period,actor);
 people=crmClient.request('programs.users',{source='registrants',page=1},actor);
 buyers=crmClient.request('programs.users',{source='buyers',page=1},actor);
 july=crmClient.request('programs.report',{from='2026-07-01',to='2026-07-31',bucket='week'},actor);
 julyPurchases=crmClient.request('programs.purchases',{from='2026-07-01',to='2026-07-31',page=1},actor);
 historicalRows=0;historicalEntitlementSafe=true;
 if(julyPurchases.success)for(purchase in julyPurchases.data.items){if(purchase.coverage_kind=='provider_historical'){historicalRows++;if(val(purchase.user_id)||(structKeyExists(purchase,'term_end')&&isDate(purchase.term_end)))historicalEntitlementSafe=false;}}
 report={report_success=overview.success,users_success=people.success,buyers_success=buyers.success,july_success=july.success,july_purchases_success=julyPurchases.success,code=overview.success?overview.data.code:'',status=overview.success?overview.data.status:'',registrants=overview.success?overview.data.totals.registrants:-1,signup_starts=overview.success?overview.data.totals.signup_starts:-1,signup_coverage=overview.success&&isDate(overview.data.coverage.signups_from),finance_status=overview.success?overview.data.finance.coverage.status:'unavailable',paid_orders=overview.success?overview.data.totals.paid_orders:-1,finance_verified=overview.success?overview.data.finance.coverage.linked_verified:-1,buyers_profile=overview.success?overview.data.profile.buyers.status:'unavailable',buyers_total=buyers.success?buyers.data.total:-1,july_orders=july.success?july.data.totals.paid_orders:-1,july_financial_series=july.success?arrayLen(july.data.finance.series):-1,july_purchases_total=julyPurchases.success?julyPurchases.data.total:-1,linked_campaigns=overview.success?arrayLen(overview.data.linked_campaigns):-1,users_total=people.success?people.data.total:-1,deliveries_before=before,deliveries_after=scalar('SELECT count(*) AS n FROM crm_interno.deliveries').n};
 report.historical_rows=historicalRows;report.historical_entitlement_safe=historicalEntitlementSafe;
 """
elif mode=='program_worker_smoke':
 body="""before=scalar('SELECT count(*) AS n FROM crm_interno.deliveries').n;
 target='https://business.roadrunners.run/api/crm-interno-commerce.cfm';
 unsigned=new http(method='post',url=target,timeout=15,throwOnError=false);unsigned.addParam(type='header',name='Content-Type',value='application/json');unsigned.addParam(type='body',value='{}');unsignedResponse=unsigned.send().getPrefix();
 payload=serializeJSON({scope='crm.commerce.worker',environment='prod'});stamp=dateTimeFormat(now(),'yyyy-mm-dd HH:nn:ss');
 signed=new http(method='post',url=target,timeout=100,throwOnError=false);signed.addParam(type='header',name='Content-Type',value='application/json');signed.addParam(type='header',name='X-RR-Handoff-Timestamp',value=stamp);signed.addParam(type='header',name='X-RR-Handoff-Signature',value=lCase(hmac(stamp & '.' & payload,APPLICATION.cronJobs.runnerToken,'HmacSHA256')));signed.addParam(type='body',value=payload);signedResponse=signed.send().getPrefix();
 response=isJSON(signedResponse.fileContent)?deserializeJSON(signedResponse.fileContent):{};
 report={unsigned_status=val(listFirst(unsignedResponse.statusCode,' ')),signed_status=val(listFirst(signedResponse.statusCode,' ')),success=structKeyExists(response,'success')&&response.success,selected=structKeyExists(response,'data')&&structKeyExists(response.data,'selected')?response.data.selected:-1,checked=structKeyExists(response,'data')&&structKeyExists(response.data,'checked')?response.data.checked:-1,failed=structKeyExists(response,'data')&&structKeyExists(response.data,'failed')?response.data.failed:-1,historical_status=structKeyExists(response,'data')&&structKeyExists(response.data,'historical')?response.data.historical.status:'unavailable',historical_scanned=structKeyExists(response,'data')&&structKeyExists(response.data,'historical')?response.data.historical.scanned:-1,historical_accepted=structKeyExists(response,'data')&&structKeyExists(response.data,'historical')?response.data.historical.accepted:-1,historical_pending=structKeyExists(response,'data')&&structKeyExists(response.data,'historical')?response.data.historical.pending:-1,deliveries_before=before,deliveries_after=scalar('SELECT count(*) AS n FROM crm_interno.deliveries').n};"""
elif mode=='program_job_install':
 sql=(ROOT/'administracao/cron-jobs/crm_interno_jobs.sql').read_text().split('-- Conciliação de pedidos Todo Santo Dia:')[1]
 sql=sql[sql.index('INSERT INTO'):]
 body="""if(scalar("SELECT count(*) AS n FROM public.tb_cron_jobs WHERE secret_ref='business_ai_mails'").n<1)throw(message='Existing scheduler secret reference unavailable');
 transaction {scalar(toString(binaryDecode('PAYLOAD','base64')));}
 report={job=scalar("SELECT count(*) AS n FROM public.tb_cron_jobs WHERE endpoint_url='https://business.roadrunners.run/api/crm-interno-commerce.cfm'").n,inactive=scalar("SELECT count(*) AS n FROM public.tb_cron_jobs WHERE endpoint_url='https://business.roadrunners.run/api/crm-interno-commerce.cfm' AND NOT ativo AND secret_ref='business_ai_mails' AND auth_mode='hmac_sha256'").n};""".replace('PAYLOAD',base64.b64encode(sql.encode()).decode())
elif mode=='program_job_enable':
 body="""transaction {scalar("UPDATE public.tb_cron_jobs SET ativo=true,next_run_at=now()+interval '5 minutes' WHERE endpoint_url='https://business.roadrunners.run/api/crm-interno-commerce.cfm' AND NOT ativo AND secret_ref='business_ai_mails' AND auth_mode='hmac_sha256'");}report={job=scalar("SELECT count(*) AS n FROM public.tb_cron_jobs WHERE endpoint_url='https://business.roadrunners.run/api/crm-interno-commerce.cfm'").n,active=scalar("SELECT count(*) AS n FROM public.tb_cron_jobs WHERE endpoint_url='https://business.roadrunners.run/api/crm-interno-commerce.cfm' AND ativo AND secret_ref='business_ai_mails' AND auth_mode='hmac_sha256'").n};"""
elif mode=='program_job_pause':
 body="""transaction {scalar("UPDATE public.tb_cron_jobs SET ativo=false WHERE endpoint_url='https://business.roadrunners.run/api/crm-interno-commerce.cfm' AND ativo");}report={job=scalar("SELECT count(*) AS n FROM public.tb_cron_jobs WHERE endpoint_url='https://business.roadrunners.run/api/crm-interno-commerce.cfm'").n,active=scalar("SELECT count(*) AS n FROM public.tb_cron_jobs WHERE endpoint_url='https://business.roadrunners.run/api/crm-interno-commerce.cfm' AND ativo").n};"""
elif mode=='program_job_verify':
 body="""transaction {scalar('SET TRANSACTION READ ONLY');report={job=scalar("SELECT count(*) AS n FROM public.tb_cron_jobs WHERE endpoint_url='https://business.roadrunners.run/api/crm-interno-commerce.cfm'").n,active=scalar("SELECT count(*) AS n FROM public.tb_cron_jobs WHERE endpoint_url='https://business.roadrunners.run/api/crm-interno-commerce.cfm' AND ativo AND secret_ref='business_ai_mails' AND auth_mode='hmac_sha256'").n,deliveries=scalar('SELECT count(*) AS n FROM crm_interno.deliveries').n};}"""
elif mode=='program_history_baseline':
 body="""transaction {scalar('SET TRANSACTION READ ONLY');report=scalar("WITH orders AS (SELECT json_transacao->'data' AS data FROM public.tb_transacoes WHERE origem_transacao='pagarme' AND status_atual='order.paid'), matching AS (SELECT data FROM orders WHERE EXISTS (SELECT 1 FROM jsonb_array_elements(CASE WHEN jsonb_typeof(data->'items')='array' THEN data->'items' ELSE '[]'::jsonb END) item WHERE item->>'code' IN ('todosantodia','todosantodiavip','todosantodiaupg'))) SELECT count(DISTINCT data->>'id') AS matching_orders,min(left(data->>'created_at',10)) AS earliest_day,max(left(data->>'created_at',10)) AS latest_day FROM matching");}"""
elif mode=='program_history_diagnostic':
 body="""transaction {scalar('SET TRANSACTION READ ONLY');reasons=scalar("SELECT reason_code,count(*) AS n FROM crm_interno.pagarme_order_audit WHERE coverage_kind='provider_historical' GROUP BY reason_code ORDER BY n DESC");state=scalar("SELECT count(*) AS n,count(*) FILTER(WHERE classification='confirmed') AS confirmed,count(*) FILTER(WHERE classification='pending') AS pending FROM crm_interno.conversion_order_state WHERE source='pagarme' AND coverage_kind='provider_historical'");window=scalar("SELECT window_start,window_end,cursor,status,scanned,accepted,pending FROM crm_interno.program_coverage WHERE source='pagarme_historical' ORDER BY window_start DESC LIMIT 1");}report={reasons=reasons,state=state,window=window};"""
elif mode=='worker_smoke':
 body="""if(scalar('SELECT count(*) n FROM crm_interno.deliveries').n!=0)throw(message='Nonempty delivery queue: do not run smoke worker');report.workers=[];for(kind in ['notifications','email']){body=serializeJSON({scope='crm.' & kind & '.worker',environment='prod'});stamp=dateTimeFormat(now(),'yyyy-mm-dd HH:nn:ss');req=new http(method='post',url='https://business.roadrunners.run/api/crm-interno-' & kind & '.cfm',timeout=100,throwOnError=false);req.addParam(type='header',name='Content-Type',value='application/json');req.addParam(type='header',name='X-RR-Handoff-Timestamp',value=stamp);req.addParam(type='header',name='X-RR-Handoff-Signature',value=lCase(hmac(stamp & '.' & body,APPLICATION.cronJobs.runnerToken,'HmacSHA256')));req.addParam(type='body',value=body);response=req.send().getPrefix();arrayAppend(report.workers,{channel=kind,status=response.statusCode,response=isJSON(response.fileContent)?deserializeJSON(response.fileContent):{error='non_json'}});}"""
elif mode=='counts_smoke':
 body="""audience=new services.crm.CrmAudienceService().init();began=getTickCount();report.list=audience.listAudiences('',1,true);report.elapsed_ms=getTickCount()-began;report.campaigns=scalar('SELECT count(*) n FROM crm_interno.campaigns').n;report.deliveries=scalar('SELECT count(*) n FROM crm_interno.deliveries').n;report.ready=true;"""
elif mode=='filters_smoke':
 body="""audience=new services.crm.CrmAudienceService().init();report.capabilities=audience.capabilities();report.queries=[];
 for(rule in [{type='profile_state',state='SC'},{type='profile_city',city='Florianópolis',state='SC'},{type='profile_age',minimum=30,maximum=49},{type='profile_gender',gender='feminino'},{type='birthday_month',month=9},{type='account_created',days=30},{type='email_verified',value='yes'},{type='marketing_optin',value='yes'},{type='brasil_gigante',days=0},{type='challenge_enrollment',code='todosantodia',days=30},{type='profile_location',state='SC',city=''}]){began=getTickCount();r=audience.evaluate({operator='all',criteria=[rule]},now(),1,1);arrayAppend(report.queries,{signal=rule.type,total=r.total,elapsed_ms=getTickCount()-began});}
 report.combined=audience.evaluate({operator='all',criteria=[{type='profile_state',state='SC'},{type='profile_age',minimum=30,maximum=49}]},now(),1,1).total;
 report.campaigns=scalar('SELECT count(*) n FROM crm_interno.campaigns').n;report.deliveries=scalar('SELECT count(*) n FROM crm_interno.deliveries').n;report.enabled=audience.enabled();report.ready=true;
 """
elif mode=='smoke':
 body="""
+settings={secret=APPLICATION.handoff.secret};audience=new services.crm.CrmAudienceService().init();caps=audience.capabilities();report.capabilities=caps;report.queries=[];
+for(rule in [{type='profile_location',state='SC',city=''},{type='recent_result',days=30,distance='half'},{type='event_agenda',days=90,event_id=0},{type='event_registration',days=90,event_id=0},{type='event_offers_distance',days=90,event_id=0,distance='half'},{type='challenge_enrollment',code='todosantodia'},{type='site_access',days=30,minimum=3},{type='contact_history',days=7,contacted='yes'}]){began=getTickCount();r=audience.evaluate({operator='all',criteria=[rule]},now(),1,1);arrayAppend(report.queries,{signal=rule.type,total=r.total,elapsed_ms=getTickCount()-began});}
+adminRow=scalar("SELECT u.id FROM tb_usuarios u WHERE (u.is_admin OR u.is_dev) AND NOT EXISTS(SELECT 1 FROM tb_usuarios_gestao g WHERE g.id_usuario=u.id AND (NOT g.ativo OR g.excluido)) ORDER BY u.id LIMIT 1");
+operator=adminRow.id;report.operator_authorized=new services.crm.CrmSecurity().init().requireActor(operator,false).id==operator;
+report.impersonation_denied=false;try{new services.crm.CrmSecurity().init().requireActor(operator,true);}catch(any denied){report.impersonation_denied=denied.message=='forbidden';}
+unsigned={};report.signature_denied=false;try{new services.crm.CrmSecurity().init('runner_dba',settings).verifyRequest('{}',unsigned,'prod');}catch(any denied){report.signature_denied=denied.message=='invalid_signature';}
+report.campaigns=scalar('SELECT count(*) n FROM crm_interno.campaigns').n;report.deliveries=scalar('SELECT count(*) n FROM crm_interno.deliveries').n;
+report.empty_notification_claim=arrayLen(new services.crm.CrmDeliveryService().init().claim('notification',1))==0;
+report.ready=true;
""".replace('\n+','\n')
else:
 enabled=mode=='enable'
 body="""transaction {scalar("UPDATE crm_interno.settings SET value='FLAG' WHERE key='enabled'");scalar("UPDATE public.tb_cron_jobs SET ativo=FLAG,next_run_at=now()+interval '2 minutes' WHERE endpoint_url IN ('https://business.roadrunners.run/api/crm-interno-notifications.cfm','https://business.roadrunners.run/api/crm-interno-email.cfm')");}report.enabled=FLAG;report.jobs=scalar("SELECT count(*) n FROM tb_cron_jobs WHERE endpoint_url IN ('https://business.roadrunners.run/api/crm-interno-notifications.cfm','https://business.roadrunners.run/api/crm-interno-email.cfm') AND ativo=FLAG").n;""".replace('FLAG',str(enabled).lower())
diagnostic=",detail=left(e.detail & '',500)" if mode=='program_job_install' else ''
source=header+body+"""cfcontent(type='application/json',reset=true);writeOutput(serializeJSON(report));}catch(any e){cfcontent(type='application/json',reset=true);writeOutput(serializeJSON({error=e.type,message=e.message,context=structKeyExists(e,'tagContext')?e.tagContext:[],progress=report"""+diagnostic+"""}));}</cfscript>"""
script=f'''from pathlib import Path
import json,os,subprocess
p=Path({'/var/www/business.roadrunners.run' if mode in ('client_smoke','worker_smoke','program_smoke','program_worker_smoke','program_job_install','program_job_enable','program_job_pause','program_job_verify','program_history_baseline','program_history_diagnostic') else '/var/www/roadrunners.com.br'!r})/{name!r};assert not p.exists()
try:
 p.write_text({source!r});os.chmod(p,0o644)
 r=subprocess.run(['curl','--silent','--show-error','--max-time','110','--resolve',{'business.roadrunners.run:443:127.0.0.1' if mode in ('client_smoke','worker_smoke','program_smoke','program_worker_smoke','program_job_install','program_job_enable','program_job_pause','program_job_verify','program_history_baseline','program_history_diagnostic') else 'roadrunners.run:443:127.0.0.1'!r},'-H',{'X-CRM-Probe: '+nonce!r},{'https://'+('business.roadrunners.run' if mode in ('client_smoke','worker_smoke','program_smoke','program_worker_smoke','program_job_install','program_job_enable','program_job_pause','program_job_verify','program_history_baseline','program_history_diagnostic') else 'roadrunners.run')+'/'+name!r}],capture_output=True,text=True,timeout=115)
 assert r.returncode==0,r.stderr
 data=json.loads(r.stdout);print(json.dumps(data))
finally:p.unlink(missing_ok=True)
'''
result=subprocess.run(SSH+['python3 -c '+shlex.quote(script)],capture_output=True,text=True,timeout=125)
if result.returncode:print(result.stderr[-2000:]);raise SystemExit(result.returncode)
data=json.loads(result.stdout);(LEDGER/('production-'+mode+'.json')).write_text(json.dumps(data,indent=2)+'\n');print(json.dumps(data));failed=any(k.lower()=='error' for k in data)
if mode=='worker_smoke':
    workers=data.get('WORKERS',data.get('workers',[]))
    failed=failed or len(workers)!=2 or any(not str(w.get('STATUS',w.get('status',''))).startswith('200') for w in workers)
if mode=='program_worker_smoke':
    report={str(k).lower():v for k,v in data.items()}
    failed=failed or report.get('unsigned_status')!=403 or report.get('signed_status')!=200 or report.get('success') is not True or report.get('failed')!=0 or report.get('historical_status')=='retry' or report.get('deliveries_before')!=report.get('deliveries_after')
if mode=='program_smoke':
    report={str(k).lower():v for k,v in data.items()}
    failed=failed or any(report.get(key) is not True for key in ('report_success','users_success','buyers_success','july_success','july_purchases_success','historical_entitlement_safe')) or report.get('deliveries_before')!=report.get('deliveries_after')
raise SystemExit(1 if failed else 0)
