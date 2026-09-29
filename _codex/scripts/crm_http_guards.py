"""Check origin HTTP guards without a session or signature; no credential output."""
import json, shlex, subprocess
from pathlib import Path
root=Path(__file__).resolve().parents[2]
remote='''import subprocess,json
checks=[('business.roadrunners.run','/crm-interno/','GET'),('roadrunners.run','/api/crm-interno/admin.cfm','GET'),('roadrunners.run','/api/crm-interno/admin.cfm','POST'),('roadrunners.run','/api/crm-interno/card.cfm','POST'),('business.roadrunners.run','/api/crm-interno-email.cfm','POST'),('business.roadrunners.run','/api/crm-interno-notifications.cfm','POST'),('business.roadrunners.run','/api/crm-interno-history.cfm','POST')]
results=[]
for host,path,method in checks:
 cmd=['curl','-sS','--max-time','15','--resolve',host+':443:127.0.0.1','-X',method,'-H','Content-Type: application/json','-w','\\n%{http_code}','https://'+host+path]
 if method=='POST':cmd+=['--data','{}']
 run=subprocess.run(cmd,capture_output=True,text=True,timeout=20);assert run.returncode==0
 body,status=run.stdout.rsplit('\\n',1);entry={'route':path,'method':method,'status':int(status)}
 try:entry['body']=json.loads(body)
 except ValueError:pass
 results.append(entry)
assert results[0]['status'] in [302,403]
assert [r['status'] for r in results[1:]]==[405,403,403,403,403,403],results
from pathlib import Path
assert not list(Path('/var/www/roadrunners.com.br').glob('__crm_*.cfm'))
assert not list(Path('/var/www/business.roadrunners.run').glob('__crm_*.cfm'))
print(json.dumps({'checks':results,'temporary_probes_removed':True}))
'''
r=subprocess.run(['ssh','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],capture_output=True,text=True,timeout=120)
if r.returncode:print(r.stderr[-2000:]);raise SystemExit(r.returncode)
data=json.loads(r.stdout);(root/'.superpowers/sdd/2026-09-24-crm-interno/http-guards.json').write_text(json.dumps(data,indent=2)+'\n');print(json.dumps(data))
