from pathlib import Path
import hashlib,json,shlex,subprocess
S=Path(__file__).resolve().parent;W=S.parents[3]
groups={'RoadRunners':{'root':'/var/www/roadrunners.com.br','names':['assets/js/runnerhub-pace.js','assets/js/runnerhub-pace.min.js','calculadora-de-pace/index.cfm'],'watch':['includes/estrutura/seo-web-tools-head.cfm','includes/analytics/bootstrap.cfm','includes/estrutura/head.cfm','Application.cfc']},'Business':{'root':'/var/www/business.roadrunners.run','names':['portal/conteudo/seo_ga4.cfm','portal/conteudo/seo_growth_baseline.cfm'],'watch':['portal/conteudo/seo.cfm','portal/seo/ga4_service.cfm','portal/seo/ga4_api.cfm','includes/backend/require_admin.cfm']}}
code='''from pathlib import Path
import json,hashlib,sys
p=json.load(sys.stdin);out={}
for g,c in p.items():
 root=Path(c['root']);r={'files':{},'watch':{}}
 for n in c['names']:
  f=root/n
  if f.exists():r['files'][n]={'text':f.read_text(),'hash':hashlib.sha256(f.read_bytes()).hexdigest()}
 for n in c['watch']:r['watch'][n]=hashlib.sha256((root/n).read_bytes()).hexdigest()
 out[g]=r
print(json.dumps(out))
'''
p=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(code)],input=json.dumps(groups),capture_output=True,text=True,timeout=45);assert p.returncode==0,p.stderr[-1200:];data=json.loads(p.stdout);out={};diff=[]
for g,c in groups.items():
 r={'root':c['root'],'before':{},'local':{},'watch':data[g]['watch'],'names':c['names']}
 for n in c['names']:
  f=W/g/n;r['local'][n]=hashlib.sha256(f.read_bytes()).hexdigest() if f.exists() else None
  if n in data[g]['files']:
   item=data[g]['files'][n];r['before'][n]=item['hash']
   for folder in ['baseline','candidate']:
    t=S/folder/g/n;t.parent.mkdir(parents=True,exist_ok=True);t.write_text(item['text'])
  if r['local'][n]!=r['before'].get(n):diff.append(g+'/'+n)
 out[g]=r
assert not (S/'baseline.json').exists();(S/'baseline.json').write_text(json.dumps(out,indent=2));print(json.dumps({'differences':diff,'runtime_files':5}))
