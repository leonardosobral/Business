"""Selective RoadRunners handler release; baseline conflicts abort before writes."""
from pathlib import Path
import json,shlex,subprocess,sys
ROOT=Path(__file__).resolve().parents[2];STAGE=ROOT/'_codex/staging/error-handler';CANDIDATE=STAGE/'candidate/RoadRunners'
mode=sys.argv[1];assert mode in ('prepare','compile','publish','verify','rollback')
files=sorted(str(p.relative_to(CANDIDATE)) for p in CANDIDATE.rglob('*') if p.is_file())
# Shared helpers have tested hash checks, backups, atomic swaps and conflict-safe restoration.
source=(ROOT/'_codex/scripts/deploy_error_triage.py').read_text().split("if __name__=='__main__':")[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/roadrunners.com.br')").replace('/var/www/business.roadrunners.run','/var/www/roadrunners.com.br').replace('/var/backups/business-error-triage-20260926','/var/backups/roadrunners-error-handler-20260926-v2')
source+='''
payload=json.load(sys.stdin);mode=payload['mode'];root=Path('/var/www/roadrunners.com.br');stage=Path('/var/backups/roadrunners-error-handler-20260926-v2')
if mode=='prepare':result=prepare(root,stage,payload['files'],payload['before'])
elif mode=='publish':
 c=json.loads((stage/'compile.json').read_text())
 if c['returncode']!=0 or c['compiled_files']==0:raise RuntimeError('Compilation not confirmed')
 # New 404 view runs under both applications; install it before isolating its bootstrap.
 m=json.loads((stage/'manifest.json').read_text());order=m['order'];a=order.index('404/Application.cfc');b=order.index('404/index.cfm')
 if a<b:order[a],order[b]=order[b],order[a];(stage/'manifest.json').write_text(json.dumps(m,indent=2))
 result=publish(root,stage);(stage/'published.json').write_text(json.dumps(result))
else:result=remote(mode,{})
print(json.dumps(result))
'''
payload={'mode':mode}
if mode=='prepare':
 order=[f for f in files if f not in ('Application.cfc','maratonadefloripa/Application.cfc','.htaccess','404/index.cfm','404/Application.cfc')]+['404/Application.cfc','404/index.cfm','Application.cfc','maratonadefloripa/Application.cfc','.htaccess']
 payload['files']={f:(CANDIDATE/f).read_text() for f in order};payload['before']=json.loads((STAGE/'baselines.json').read_text())
ssh=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
p=subprocess.run(ssh+['python3 -c '+shlex.quote(source)],input=json.dumps(payload),capture_output=True,text=True,timeout=180)
if p.returncode:print(p.stderr[-1500:]);sys.exit(p.returncode)
data=json.loads(p.stdout);(STAGE/('release-'+mode+'.json')).write_text(json.dumps(data,indent=2));print(json.dumps(data))
if mode=='compile' and (data['returncode']!=0 or data['compiled_files']==0):sys.exit(1)
