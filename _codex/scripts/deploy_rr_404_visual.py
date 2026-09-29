"""Selective static 404 visual update using baseline/backup/atomic deploy helpers."""
from pathlib import Path
import json,subprocess,shlex,sys
ROOT=Path(__file__).resolve().parents[2];stage=ROOT/'_codex/staging/rr-404-visual'
mode=sys.argv[1];assert mode in ('prepare','publish','verify','rollback')
source=(ROOT/'_codex/scripts/deploy_error_triage.py').read_text().split("if __name__=='__main__':")[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/roadrunners.com.br')")
source+='''
p=json.load(sys.stdin);root=Path('/var/www/roadrunners.com.br');stage=Path('/var/backups/roadrunners-404-visual-20260926')
if p['mode']=='prepare':result=prepare(root,stage,p['files'],p['before'])
elif p['mode']=='publish':result=publish(root,stage)
elif p['mode']=='verify':result=verify(root,stage)
else:result=rollback(root,stage)
print(json.dumps(result))
'''
payload={'mode':mode}
if mode=='prepare':
 payload['files']={str(p.relative_to(stage/'candidate')):p.read_text() for p in (stage/'candidate').rglob('*.html')};payload['before']=json.loads((stage/'baselines.json').read_text())
p=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(source)],input=json.dumps(payload),capture_output=True,text=True,timeout=45)
if p.returncode:print(p.stderr[-1800:]);sys.exit(p.returncode)
data=json.loads(p.stdout);(stage/('release-'+mode+'.json')).write_text(json.dumps(data,indent=2));print(json.dumps(data))
