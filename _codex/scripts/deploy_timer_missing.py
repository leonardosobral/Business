"""Publish only the RoadRunners timer guard with baseline and recoverable backup."""
from pathlib import Path
import json,subprocess,shlex,sys
ROOT=Path(__file__).resolve().parents[2];RR=ROOT.parent/'RoadRunners';STAGE=ROOT/'_codex/staging/timer-missing-20261004'
mode=sys.argv[1];assert mode in ('prepare','compile','publish','verify','rollback')
source=(ROOT/'_codex/scripts/deploy_error_triage.py').read_text().split("if __name__=='__main__':")[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/roadrunners.com.br')").replace('/var/www/business.roadrunners.run','/var/www/roadrunners.com.br').replace('/var/backups/business-error-triage-20260926','/var/backups/roadrunners-timer-missing-20261004')
source+='''
payload=json.load(sys.stdin);root=Path('/var/www/roadrunners.com.br');stage=Path('/var/backups/roadrunners-timer-missing-20261004')
if payload['mode']=='prepare':result=prepare(root,stage,payload['files'],payload['before'])
elif payload['mode']=='publish':
 c=json.loads((stage/'compile.json').read_text());assert c['returncode']==0 and c['compiled_files']==1
 result=publish(root,stage);(stage/'published.json').write_text(json.dumps(result))
else:result=remote(payload['mode'],{})
print(json.dumps(result))
'''
payload={'mode':mode}
if mode=='prepare':payload.update(files={'timer/index.cfm':(RR/'timer/index.cfm').read_text()},before=json.loads((STAGE/'baselines.json').read_text()))
p=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(source)],input=json.dumps(payload),capture_output=True,text=True,timeout=180)
print(p.stdout);print(p.stderr[-1500:]);(STAGE/('release-'+mode+'.json')).write_text(p.stdout);sys.exit(p.returncode)
