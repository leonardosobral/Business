from pathlib import Path
import base64,hashlib,json,shlex,subprocess
S=Path(__file__).resolve().parent
names=['includes/estrutura/footer.cfm']
watch=['Application.cfc','includes/backend/backend_require_login.cfm','includes/modal/modal_login.cfm','includes/estrutura/header.cfm','includes/estrutura/head.cfm','includes/estrutura/menu_apps.cfm','includes/estrutura/event_title_date.cfm','includes/estrutura/footer_assets.cfm']
remote='''from pathlib import Path
import base64,hashlib,json,sys
p=json.load(sys.stdin);root=Path('/var/www/roadrunners.com.br')
print(json.dumps({'files':{n:base64.b64encode((root/n).read_bytes()).decode() for n in p['names']},'watch':{n:hashlib.sha256((root/n).read_bytes()).hexdigest() for n in p['watch']}}))'''
ssh=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
cp=subprocess.run(ssh+['python3 -c '+shlex.quote(remote)],input=json.dumps({'names':names,'watch':watch}),capture_output=True,text=True,timeout=40)
assert cp.returncode==0,cp.stderr[-2000:]
r=json.loads(cp.stdout);summary={}
for n,b in r.pop('files').items():
 data=base64.b64decode(b);local=Path('/Users/Shared/Projects/RunnerHub/RoadRunners')/n
 local_copy=S/'local-before'/n;local_copy.parent.mkdir(parents=True,exist_ok=True);local_copy.write_bytes(local.read_bytes())
 p=S/'baseline'/n;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(data);summary[n]=hashlib.sha256(data).hexdigest()
r['before']=summary;(S/'nav-baseline.json').write_text(json.dumps(r,indent=2));print(json.dumps({'local_matches_production':{n:(S/'baseline'/n).read_bytes()==(S/'local-before'/n).read_bytes() for n in names},'watched_dependencies':len(watch)}))
