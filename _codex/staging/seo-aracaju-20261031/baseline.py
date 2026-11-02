from pathlib import Path
import hashlib,json,shlex,subprocess
S=Path(__file__).resolve().parent
projects={
 'rr':{'local':'RoadRunners','root':'/var/www/roadrunners.com.br','files':['estado/index.cfm','evento/index.cfm','includes/permanent_race_editorial.cfm'],'watch':['Application.cfc','.htaccess','includes/estrutura/head.cfm','includes/backend/backend_permanent_race.cfm','includes/permanent_race_overview.cfm','evento/parts/post_race_data.cfm']},
 'or':{'local':'OpenResults','root':'/var/www/openresults.run','files':['estado/index.cfm','evento/index.cfm'],'watch':['Application.cfc','.htaccess','includes/head.cfm','includes/backend.cfm','includes/backend_evento.cfm','includes/backend_estado_cidades.cfm','robots.txt','sitemap.cfm']}}
code='''from pathlib import Path
import json,hashlib,sys
p=json.load(sys.stdin);out={}
for k,v in p.items():
 root=Path(v['root']);out[k]={'files':{},'watch':{}}
 for n in v['files']:
  f=root/n;out[k]['files'][n]={'sha':hashlib.sha256(f.read_bytes()).hexdigest(),'text':f.read_text()} if f.exists() else None
 for n in v['watch']:
  f=root/n;out[k]['watch'][n]=hashlib.sha256(f.read_bytes()).hexdigest() if f.exists() else None
print(json.dumps(out))
'''
assert not (S/'baseline.json').exists()
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(code)],input=json.dumps(projects),text=True,capture_output=True,timeout=60)
assert cp.returncode==0,cp.stderr[-1500:]
data=json.loads(cp.stdout);differences=[]
for k,v in projects.items():
 data[k]['root']=v['root'];data[k]['local']=v['local'];data[k]['localHashes']={}
 for n,f in data[k]['files'].items():
  local=Path('/Users/Shared/Projects/RunnerHub')/v['local']/n
  h=hashlib.sha256(local.read_bytes()).hexdigest() if local.exists() else None
  data[k]['localHashes'][n]=h
  if f:
   for d in ['baseline','candidate']:
    target=S/d/k/n;target.parent.mkdir(parents=True,exist_ok=True);target.write_text(f['text'])
   if h!=f['sha']:differences.append(k+'/'+n)
(S/'baseline.json').write_text(json.dumps(data,indent=2)+'\n')
print(json.dumps({'projects':len(data),'files':sum(len(p['files']) for p in data.values()),'localProductionDifferences':differences}))
