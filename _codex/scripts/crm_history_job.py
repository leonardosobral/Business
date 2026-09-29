"""Install and enable only the signed CRM audience-history scheduler row."""
from pathlib import Path
import json
import secrets
import shlex
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
LEDGER = ROOT / '.superpowers/sdd/2026-09-24-crm-interno-evolucao'
SSH = ['ssh', '-o', 'BatchMode=yes', '-o', 'ConnectTimeout=10',
       '-o', 'StrictHostKeyChecking=yes', '-i', '/Users/leonardosobral/.ssh/webs',
       'root@ssh.runnerhub.run']
mode = sys.argv[1] if len(sys.argv) == 2 else ''
if mode not in ('check', 'install', 'enable', 'disable', 'status'):
    raise SystemExit('mode: check | install | enable | disable | status')
if mode == 'enable':
    for receipt in ('history-database-verify.json', 'history-database-smoke.json'):
        if not (LEDGER / receipt).exists():
            raise SystemExit(f'{receipt} is required before enabling the history job')
    release = ROOT / '.superpowers/sdd/2026-09-24-crm-interno/release-verify.json'
    if not release.exists() or not json.loads(release.read_text()).get('hashes_verified'):
        raise SystemExit('Verified runtime release is required before enabling the history job')

nonce = secrets.token_hex(32)
name = '__crm_history_job_' + secrets.token_hex(12) + '.cfm'
source = '''<cfsetting showdebugoutput="false" requesttimeout="30"><cfscript>
req=getHttpRequestData(false);
if(!listFind('127.0.0.1,::1',CGI.REMOTE_ADDR)||!structKeyExists(req.headers,'X-CRM-Probe')||req.headers['X-CRM-Probe']!='NONCE'){cfheader(statuscode=404);abort;}
function q(required string sql,struct params={}){return queryExecute(sql,params,{datasource='runner_dba',timeout=20});}
try{
 mode='MODE';endpoint='https://business.roadrunners.run/api/crm-interno-history.cfm';
 body='{"scope":"crm.history.worker","environment":"prod"}';
 rows=q('SELECT id_cron_job,nome,projeto,ambiente,endpoint_url,http_method,request_body,auth_mode,secret_ref,interval_minutes,ativo,next_run_at FROM public.tb_cron_jobs WHERE endpoint_url=:endpoint',{endpoint={value=endpoint,cfsqltype='cf_sql_varchar'}});
 if(rows.recordCount>1)throw(message='Duplicate history jobs');
 if(mode=='install' && !rows.recordCount){
  q("INSERT INTO public.tb_cron_jobs(nome,descricao,projeto,ambiente,endpoint_url,http_method,content_type,request_body,headers_json,auth_mode,secret_ref,interval_minutes,timeout_seconds,retry_limit,ativo,executar_em_atraso,max_runtime_seconds,next_run_at) VALUES('CRM interno - Histórico de públicos','Fotografias completas dos públicos ativos, em lotes retomáveis.','business','prod',:endpoint,'POST','application/json',:body,CAST('{}' AS jsonb),'hmac_sha256','business_ai_mails',10,110,0,false,true,120,(date_trunc('day',now() AT TIME ZONE 'America/Sao_Paulo')+interval '1 day 3 hours') AT TIME ZONE 'America/Sao_Paulo')",{endpoint={value=endpoint,cfsqltype='cf_sql_varchar'},body={value=body,cfsqltype='cf_sql_varchar'}});
 }
 rows=q('SELECT id_cron_job,nome,projeto,ambiente,endpoint_url,http_method,request_body,auth_mode,secret_ref,interval_minutes,ativo,next_run_at FROM public.tb_cron_jobs WHERE endpoint_url=:endpoint',{endpoint={value=endpoint,cfsqltype='cf_sql_varchar'}});
 if(rows.recordCount==1 && (rows.projeto!='business'||rows.ambiente!='prod'||rows.http_method!='POST'||rows.request_body!=body||rows.auth_mode!='hmac_sha256'||rows.secret_ref!='business_ai_mails'||rows.interval_minutes!=10))throw(message='History job configuration conflict');
 if(mode=='enable'){
  if(rows.recordCount!=1)throw(message='History job missing');
  q("UPDATE public.tb_cron_jobs SET ativo=true,next_run_at=(date_trunc('day',now() AT TIME ZONE 'America/Sao_Paulo')+interval '1 day 3 hours') AT TIME ZONE 'America/Sao_Paulo' WHERE id_cron_job=:id AND ativo=false",{id={value=rows.id_cron_job,cfsqltype='cf_sql_bigint'}});
  rows=q('SELECT id_cron_job,nome,projeto,ambiente,endpoint_url,http_method,request_body,auth_mode,secret_ref,interval_minutes,ativo,next_run_at FROM public.tb_cron_jobs WHERE endpoint_url=:endpoint',{endpoint={value=endpoint,cfsqltype='cf_sql_varchar'}});
 }
 if(mode=='disable'){
  if(rows.recordCount!=1)throw(message='History job missing');
  q('UPDATE public.tb_cron_jobs SET ativo=false WHERE id_cron_job=:id AND ativo=true',{id={value=rows.id_cron_job,cfsqltype='cf_sql_bigint'}});
  rows=q('SELECT id_cron_job,nome,projeto,ambiente,endpoint_url,http_method,request_body,auth_mode,secret_ref,interval_minutes,ativo,next_run_at FROM public.tb_cron_jobs WHERE endpoint_url=:endpoint',{endpoint={value=endpoint,cfsqltype='cf_sql_varchar'}});
 }
 report={mode=mode,found=rows.recordCount==1,active=rows.recordCount==1?rows.ativo:false,next_run_at=rows.recordCount==1?rows.next_run_at:''};
 cfcontent(type='application/json',reset=true);writeOutput(serializeJSON(report));
}catch(any e){cfcontent(type='application/json',reset=true);writeOutput(serializeJSON({error=e.type,message=e.message}));}
</cfscript>'''.replace('NONCE', nonce).replace('MODE', mode)
remote = f'''from pathlib import Path
import json,os,subprocess
p=Path('/var/www/roadrunners.com.br')/{name!r};assert not p.exists()
try:
 p.write_text({source!r});os.chmod(p,0o644)
 r=subprocess.run(['curl','--silent','--show-error','--max-time','30','--resolve','roadrunners.run:443:127.0.0.1','-H',{'X-CRM-Probe: '+nonce!r},'https://roadrunners.run/'+{name!r}],capture_output=True,text=True,timeout=35)
 assert r.returncode==0,r.stderr
 print(json.dumps(json.loads(r.stdout)))
finally:p.unlink(missing_ok=True)
'''
result = subprocess.run(SSH + ['python3 -c ' + shlex.quote(remote)], capture_output=True,
                        text=True, timeout=45)
if result.returncode:
    print(result.stderr[-2500:], file=sys.stderr)
    raise SystemExit(result.returncode)
data = json.loads(result.stdout)
LEDGER.mkdir(parents=True, exist_ok=True)
(LEDGER / ('history-job-' + mode + '.json')).write_text(json.dumps(data, indent=2) + '\n')
print(json.dumps(data))
if 'error' in data or (mode in ('install', 'enable', 'disable') and not data.get('found')) or (mode == 'enable' and not data.get('active')) or (mode == 'disable' and data.get('active')):
    raise SystemExit(1)
