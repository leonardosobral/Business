from pathlib import Path
import hashlib,json,shlex,subprocess
S=Path(__file__).resolve().parent/'heads';S.mkdir(exist_ok=True)
spec={'rr':{'root':'/var/www/roadrunners.com.br','files':['includes/estrutura/head.cfm'],'watch':['evento/index.cfm','includes/estrutura/event_title_date.cfm','services/EventRedirectService.cfc']},'business':{'root':'/var/www/business.roadrunners.run','files':['includes/estrutura/head.cfm'],'watch':['cadastro/index.cfm','cadastro/home.cfm','Application.cfc']}}
remote="""from pathlib import Path
import hashlib,json,sys
p=json.load(sys.stdin);out={}
for key,item in p.items():
 root=Path(item['root']);out[key]={'files':{n:(root/n).read_text() for n in item['files']},'watch':{n:hashlib.sha256((root/n).read_bytes()).hexdigest() for n in item['watch']}}
print(json.dumps(out))
"""
ssh=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
cp=subprocess.run(ssh+['python3 -c '+shlex.quote(remote)],input=json.dumps(spec),capture_output=True,text=True,timeout=30);assert cp.returncode==0,cp.stderr[-1500:]
r=json.loads(cp.stdout);b={}
for key,item in r.items():
 for n,v in item['files'].items():
  for branch in ['baseline','candidate']:
   p=S/branch/key/n;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(v)
  local=S.parents[3]/n if key=='business' else S.parents[3].parent/'RoadRunners'/n
  local_text=local.read_text()
  if key=='business':
   assert local_text.replace('pesquisas.css?v=20260824-8','pesquisas.css?v=20260824-7')==v,'Unreviewed Business production drift'
  else:assert local_text==v,'Local/production drift: '+key+'/'+n
  p=S/'local-before'/key/n;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(local_text)
 b[key]=dict(root=spec[key]['root'],before={n:hashlib.sha256(v.encode()).hexdigest() for n,v in item['files'].items()},watch=item['watch'])
(S/'baseline.json').write_text(json.dumps(b,indent=2));print(json.dumps({'projects':len(b),'templates':sum(len(x['before']) for x in b.values())}))
