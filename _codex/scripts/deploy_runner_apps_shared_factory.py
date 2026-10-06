from pathlib import Path
import subprocess,shlex,json,sys
root=Path(__file__).resolve().parents[2];stage=root/'_codex/staging/runner-apps-20261004/shared-factory'
s=(root/'_codex/scripts/deploy_error_triage.py').read_text().split("if __name__=='__main__':")[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/roadrunners.com.br')").replace('/var/www/business.roadrunners.run','/var/www/roadrunners.com.br').replace('/var/backups/business-error-triage-20260926','/var/backups/runner-apps-shared-factory-20261004')
s+='''
payload=json.load(sys.stdin);stage=Path('/var/backups/runner-apps-shared-factory-20261004');mode=payload['mode']
if mode=='prepare':result=prepare(ROOT,stage,payload['files'],payload['before'])
elif mode=='publish':
 c=json.loads((stage/'compile.json').read_text());assert c['returncode']==0 and c['compiled_files']==2
 result=publish(ROOT,stage)
else:result=remote(mode,{})
print(json.dumps(result))
'''
payload=json.loads((stage/'payload.json').read_text());payload['mode']=sys.argv[1]
p=subprocess.run(['ssh','-o','BatchMode=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(s)],input=json.dumps(payload),capture_output=True,text=True,timeout=190)
print(p.stdout);print(p.stderr[-2000:]);(stage/(sys.argv[1]+'.json')).write_text(p.stdout);raise SystemExit(p.returncode)
