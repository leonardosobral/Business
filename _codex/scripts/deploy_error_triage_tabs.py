"""Publish only the four UI files using the verified triage release helpers."""
from pathlib import Path
import json,shlex,subprocess,sys
ROOT=Path(__file__).resolve().parents[2]
INITIAL=len(sys.argv)>2 and sys.argv[2]=='--initial'
STAGING=ROOT/('_codex/staging/error-triage-tabs' if INITIAL else '_codex/staging/error-triage-tabs-final')
FILES=['portal/erros/assets/triage.css','portal/erros/assets/triage.js','portal/erros/includes/workspace.cfm','portal/erros/home.cfm']
SSH=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
mode=sys.argv[1]
assert mode in ('prepare','compile','publish','verify','rollback')
source=(ROOT/'_codex/scripts/deploy_error_triage.py').read_text().split("if __name__=='__main__':")[0]
source=source.replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')").replace('/var/backups/business-error-triage-20260926','/var/backups/business-error-triage-tabs-final-20260926')
source+='''
payload=json.load(sys.stdin)
root=Path('/var/www/business.roadrunners.run');stage=Path('/var/backups/business-error-triage-tabs-final-20260926')
mode=payload['mode']
if mode=='prepare':result=prepare(root,stage,payload['files'],payload['before'])
elif mode=='publish':
 compiled=json.loads((stage/'compile.json').read_text())
 if compiled['returncode']!=0 or compiled['compiled_files']==0:raise RuntimeError('Compilation not confirmed')
 result=publish(root,stage)
 (stage/'published.json').write_text(json.dumps(result))
else:result=remote(mode,{})
print(json.dumps(result))
'''
if INITIAL:source=source.replace('/var/backups/business-error-triage-tabs-final-20260926','/var/backups/business-error-triage-tabs-20260926')
payload={'mode':mode}
if mode=='prepare':
 payload['before']=json.loads((STAGING/'baselines.json').read_text())
 payload['files']={f:(ROOT/f).read_text() for f in FILES}
p=subprocess.run(SSH+['python3 -c '+shlex.quote(source)],input=json.dumps(payload),capture_output=True,text=True,timeout=180)
if p.returncode:print(p.stderr[-3000:]);sys.exit(p.returncode)
data=json.loads(p.stdout);(STAGING/('release-'+mode+'.json')).write_text(json.dumps(data,indent=2));print(json.dumps(data))
if mode=='compile' and (data['returncode']!=0 or data['compiled_files']==0):sys.exit(1)
