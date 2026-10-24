from pathlib import Path
import hashlib,json,shlex,subprocess
S=Path(__file__).resolve().parent/'runtime';S.mkdir(exist_ok=True)
names=['includes/backend/backend_evento.cfm','includes/estrutura/menu_apps_data.cfm']
watch=['evento/index.cfm','evento/parts/edicoes_evento.cfm','includes/estrutura/head.cfm','includes/estrutura/event_title_date.cfm','includes/estrutura/menu_apps.cfm','includes/estrutura/header_slim.cfm','services/EventRedirectService.cfc','public-api/v1/discovery/runner-apps.cfm']
remote='''from pathlib import Path
import hashlib,json,sys
p=json.load(sys.stdin);r=Path('/var/www/roadrunners.com.br');print(json.dumps({'files':{n:(r/n).read_text() for n in p['names']},'watch':{n:hashlib.sha256((r/n).read_bytes()).hexdigest() for n in p['watch']}}))'''
ssh=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
cp=subprocess.run(ssh+['python3 -c '+shlex.quote(remote)],input=json.dumps(dict(names=names,watch=watch)),capture_output=True,text=True,timeout=30);assert cp.returncode==0,cp.stderr[-1500:]
r=json.loads(cp.stdout)
for n,v in r['files'].items():
 assert (S.parents[3].parent/'RoadRunners'/n).read_text()==v,'Unreviewed local drift '+n
 for branch in ['baseline','candidate']:
  p=S/branch/n;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(v)
(S/'baseline.json').write_text(json.dumps(dict(before={n:hashlib.sha256(v.encode()).hexdigest() for n,v in r['files'].items()},watch=r['watch']),indent=2))
print(json.dumps(dict(baseline_templates=len(names),watched_dependencies=len(watch))))
