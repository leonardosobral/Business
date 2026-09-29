"""Read-only schema probe through the existing CF datasource. No user rows or secrets."""
from pathlib import Path
import json, secrets, shlex, subprocess

root = Path(__file__).resolve().parents[2]
ssh = ['ssh', '-o', 'BatchMode=yes', '-o', 'ConnectTimeout=10', '-o', 'StrictHostKeyChecking=yes', '-i', '/Users/leonardosobral/.ssh/webs', 'root@ssh.runnerhub.run']
nonce = secrets.token_hex(32)
name = '__crm_probe_' + secrets.token_hex(12) + '.cfm'
source = '''<cfsetting showdebugoutput="false"><cfscript>
req=getHttpRequestData(false);
if(!listFind('127.0.0.1,::1',CGI.REMOTE_ADDR)||!structKeyExists(req.headers,'X-CRM-Probe')||req.headers['X-CRM-Probe']!='NONCE'){cfheader(statuscode=404);abort;}
function records(q){var a=[];for(var i=1;i<=q.recordcount;i++){var r={};for(var k in listToArray(q.columnlist))r[lCase(k)]=q[k][i];arrayAppend(a,r);}return a;}
try{
 report={columns=records(queryExecute("SELECT table_name,column_name,data_type FROM information_schema.columns WHERE table_schema='public' AND table_name IN ('tb_usuarios','tb_usuarios_gestao','tb_evento_corridas','tb_evento_corridas_checkin','tb_evento_corridas_percursos','tb_resultados','desafios','tb_notifica_template','tb_notifica','tb_mailing','tb_cron_jobs') ORDER BY table_name,ordinal_position",{},{datasource='runner_dba',timeout=15})),permissions=records(queryExecute("SELECT has_database_privilege(current_user,current_database(),'CREATE') AS can_create_schema,to_regnamespace('crm_interno') IS NOT NULL AS crm_exists",{},{datasource='runner_dba',timeout=5})),secure_handoff=structKeyExists(APPLICATION,'handoff')&&len(APPLICATION.handoff.secret)&&compareNoCase(APPLICATION.handoff.secret,hash('RoadRunners::handoff::roadrunners.run::v1','SHA-256'))!=0,environment=REQUEST.currentEnvironment};
 cfcontent(type='application/json',reset=true);writeOutput(serializeJSON(report));
}catch(any e){cfcontent(type='application/json',reset=true);writeOutput(serializeJSON({error=e.type,message=e.message}));}
</cfscript>'''.replace('NONCE', nonce)
script = f'''from pathlib import Path
import subprocess,json,os
p=Path('/var/www/roadrunners.com.br')/{name!r}
assert not p.exists()
try:
 p.write_text({source!r});os.chmod(p,0o644)
 r=subprocess.run(['curl','--silent','--show-error','--max-time','40','--resolve','roadrunners.run:443:127.0.0.1','-H',{'X-CRM-Probe: '+nonce!r},'https://roadrunners.run/{name}'],capture_output=True,text=True,timeout=45)
 assert r.returncode==0,r.stderr
 value=json.loads(r.stdout)
 print(json.dumps(value))
finally:
 p.unlink(missing_ok=True)
'''
result = subprocess.run(ssh + ['python3 -c ' + shlex.quote(script)],capture_output=True,text=True,timeout=60)
if result.returncode:
    print(result.stderr[-1500:]);raise SystemExit(result.returncode)
data=json.loads(result.stdout)
target=root/'.superpowers/sdd/2026-09-24-crm-interno/production-schema.json'
target.write_text(json.dumps(data,indent=2)+'\n')
print(json.dumps({k:v for k,v in data.items() if k.lower()!='columns'}))
print('Schema metadata saved; temporary probe removed.')
