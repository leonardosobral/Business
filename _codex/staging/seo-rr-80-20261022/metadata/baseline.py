from pathlib import Path
import base64,hashlib,json,shlex,subprocess
S=Path(__file__).resolve().parent
names=['noticias/index.cfm','org/index.cfm','timer/index.cfm']
remote='''from pathlib import Path
import base64,hashlib,json,sys
r=Path('/var/www/roadrunners.com.br');names=json.load(sys.stdin)
print(json.dumps({'files':{n:base64.b64encode((r/n).read_bytes()).decode() for n in names},'watch':{n:hashlib.sha256((r/n).read_bytes()).hexdigest() for n in ['Application.cfc','includes/estrutura/head.cfm','includes/estrutura/footer.cfm','includes/estrutura/event_title_date.cfm']}}))'''
ssh=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
cp=subprocess.run(ssh+['python3 -c '+shlex.quote(remote)],input=json.dumps(names),capture_output=True,text=True,timeout=45);assert cp.returncode==0,cp.stderr[-1800:]
r=json.loads(cp.stdout);before={};same={}
for n,b in r.pop('files').items():
 d=base64.b64decode(b);t=S/'baseline'/n;t.parent.mkdir(parents=True,exist_ok=True);t.write_bytes(d)
 local=Path('/Users/Shared/Projects/RunnerHub/RoadRunners')/n;t=S/'local-before'/n;t.parent.mkdir(parents=True,exist_ok=True);t.write_bytes(local.read_bytes())
 before[n]=hashlib.sha256(d).hexdigest();same[n]=d==local.read_bytes()
r['before']=before;(S/'baseline.json').write_text(json.dumps(r,indent=2));print(json.dumps({'production_equals_local':same}))
