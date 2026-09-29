"""Selective static 404 visual update using baseline/backup/atomic deploy helpers."""
from pathlib import Path
import json,subprocess,shlex,sys
ROOT=Path(__file__).resolve().parents[2];site=sys.argv[1];assert site in ('business','openresults');stage=ROOT/'_codex/staging/sites-probe-block'/site
mode=sys.argv[2];assert mode in ('prepare','publish','verify','rollback')
source=(ROOT/'_codex/scripts/deploy_error_triage.py').read_text().split("if __name__=='__main__':")[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/roadrunners.com.br')")
source+='''
p=json.load(sys.stdin);root=Path('/var/www/roadrunners.com.br');stage=Path('/var/backups/roadrunners-probe-block-20260928')
if p['mode']=='prepare':result=prepare(root,stage,p['files'],p['before'])
elif p['mode']=='publish':result=publish(root,stage)
elif p['mode']=='verify':result=verify(root,stage)
else:result=rollback(root,stage)
print(json.dumps(result))
'''
source=source.replace('/var/www/roadrunners.com.br','/var/www/'+('business.roadrunners.run' if site=='business' else 'openresults.run')).replace('/var/backups/roadrunners-probe-block-20260928','/var/backups/'+site+'-probe-block-20260928')
source=source.replace("reference=(root/next(iter(m['before']))).stat()","reference=(root/next(iter(m['before']), 'index.cfm')).stat()")
payload={'mode':mode}
if mode=='prepare':
 payload['files']={str(p.relative_to(stage/'candidate')):p.read_text() for p in (stage/'candidate').glob('.htaccess')};payload['before']=json.loads((stage/'baselines.json').read_text())
p=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(source)],input=json.dumps(payload),capture_output=True,text=True,timeout=45)
if p.returncode:print(p.stderr[-1800:]);sys.exit(p.returncode)
data=json.loads(p.stdout);(stage/('release-'+mode+'.json')).write_text(json.dumps(data,indent=2));print(json.dumps(data))
