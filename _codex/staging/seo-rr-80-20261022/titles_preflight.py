from pathlib import Path
import hashlib,json,shlex,subprocess
S=Path(__file__).resolve().parent/'titles';S.mkdir(exist_ok=True)
names=['includes/estrutura/event_title_date.cfm','evento/index.cfm']
watch=['services/EventRedirectService.cfc','includes/estrutura/event_redirect.cfm','includes/backend/backend_evento.cfm','sitemaps/index.cfm','includes/estrutura/head.cfm']
remote="""from pathlib import Path
import hashlib,json,sys
p=json.load(sys.stdin);root=Path('/var/www/roadrunners.com.br')
print(json.dumps({'files':{n:(root/n).read_text() for n in p['names']},'watch':{n:hashlib.sha256((root/n).read_bytes()).hexdigest() for n in p['watch']}}))
"""
ssh=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
cp=subprocess.run(ssh+['python3 -c '+shlex.quote(remote)],input=json.dumps(dict(names=names,watch=watch)),capture_output=True,text=True,timeout=30)
assert cp.returncode==0,cp.stderr[-1500:]
r=json.loads(cp.stdout)
for n,v in r['files'].items():
 p=S/'baseline'/n;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(v)
 if n.startswith('includes/estrutura/event_title'):
  assert (S.parents[3].parent/'RoadRunners'/n).read_text()==v,'Local/production drift'
  c=S/'candidate'/n;c.parent.mkdir(parents=True,exist_ok=True);c.write_text(v)
b={'before':{n:hashlib.sha256(r['files'][n].encode()).hexdigest() for n in names if 'event_title' in n},'watch':r['watch']}
b['watch']['evento/index.cfm']=hashlib.sha256(r['files']['evento/index.cfm'].encode()).hexdigest()
(S/'baseline.json').write_text(json.dumps(b,indent=2));print(json.dumps({'baseline_files':len(b['before']),'dependencies':len(b['watch'])}))
