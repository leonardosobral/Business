from pathlib import Path
import json,subprocess,shlex,base64
P=Path(__file__).resolve().parent
names=['desafiosupra/2024/index.cfm','desafiosupra/2025/index.cfm','includes/estrutura/variaveis.cfm','circuito/live_highlight.cfm']
remote='''from pathlib import Path
import sys,json,base64
r=Path('/var/www/roadrunners.com.br');print(json.dumps({n:base64.b64encode((r/n).read_bytes()).decode() for n in json.load(sys.stdin)}))'''
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps(names),capture_output=True,text=True,timeout=30)
if cp.returncode:raise RuntimeError(cp.stderr)
for n,v in json.loads(cp.stdout).items():
 b=base64.b64decode(v);f=P/'baseline/rr'/n;f.parent.mkdir(parents=True,exist_ok=True);f.write_bytes(b)
 local=P.parents[3]/'RoadRunners'/n
 if local.read_bytes()!=b:print('Preserved production/local difference: '+n)
print(json.dumps({'saved':len(names)}))
