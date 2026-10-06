from pathlib import Path
import json,subprocess,shlex
root=Path(__file__).resolve().parents[2]
remote=r'''
from pathlib import Path
import subprocess,json,hashlib,datetime
report={'at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'files':[],'http':[]}
groups=[('/var/www/business.roadrunners.run','runner-apps-20261004-v2-provider'),('/var/www/business.roadrunners.run','runner-apps-20261004-v2-legacy'),('/var/www/roadrunners.com.br','runner-apps-20261004-v2-rr'),('/var/www/roadrunners.com.br','runner-apps-shared-factory-20261004'),('/var/www/openresults.run','openresults-static404-20261004'),('/var/www/openresults.run','openresults-catalog-scope-20261004')]
expected={}
for directory,backup in groups:
 m=json.loads((Path('/var/backups')/backup/'manifest.json').read_text())
 for f,digest in m['candidate'].items():expected[str(Path(directory)/f)]=digest
for f,digest in expected.items():
 actual=hashlib.sha256(Path(f).read_bytes()).hexdigest();assert actual==digest,f
 report['files'].append(f)
checks=[('roadrunners.run','/',200),('business.roadrunners.run','/',200),('openresults.run','/busca/?termo=maratona',200),('openresults.run','/404/',404),('openresults.run','/404/index.cfm',404),('api.roadrunners.run','/v1/discovery/runner-apps.cfm',200),('api.roadrunners.run','/v1/discovery/runner-apps.cfm?incluir_ocultos=1',400),('business.roadrunners.run','/api/portal/runner-apps/',308)]
for host,path,status in checks:
 p=subprocess.run(['curl','-sS','--max-time','20','-o','/dev/null','-w','%{http_code} %{time_total} %{redirect_url}','https://'+host+path],capture_output=True,text=True,timeout=22)
 fields=p.stdout.split(' ',2);ok=p.returncode==0 and fields[0]==str(status);report['http'].append({'url':'https://'+host+path,'status':fields[0],'seconds':fields[1] if len(fields)>1 else '', 'redirect':fields[2] if len(fields)>2 else '', 'passed':ok})
p=subprocess.run(['curl','-sS','--max-time','5','http://127.0.0.1/server-status?auto'],capture_output=True,text=True)
report['apache']=[line for line in p.stdout.splitlines() if line.startswith(('BusyWorkers:','IdleWorkers:','Load1:','Load5:','Load15:'))]
report['processes']=subprocess.run(['ps','-p','1756,3808619','-o','pid,lstart,comm'],capture_output=True,text=True).stdout.strip()
report['containment_present']='Temporary incident containment' in Path('/var/www/openresults.run/.htaccess').read_text()
report['tls_config']=Path('/etc/apache2/conf-available/runnerhub-tls-timeout.conf').read_text()
print(json.dumps(report));assert all(c['passed'] for c in report['http']) and not report['containment_present']
'''
p=subprocess.run(['ssh','-o','BatchMode=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],capture_output=True,text=True,timeout=180)
print(p.stdout);print(p.stderr[-2000:]);(root/'_codex/staging/runner-apps-20261004/final-recovery.json').write_text(p.stdout);raise SystemExit(p.returncode)
