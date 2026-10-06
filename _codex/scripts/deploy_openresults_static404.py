from pathlib import Path
import subprocess,shlex,json,sys
ROOT=Path(__file__).resolve().parents[2];STAGE=ROOT/'_codex/staging/openresults-404-recovery-20261004'
mode=sys.argv[1];assert mode in ('prepare','publish','verify','rollback')
source=(ROOT/'_codex/scripts/deploy_error_triage.py').read_text().split("if __name__=='__main__':")[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/openresults.run')").replace('/var/www/business.roadrunners.run','/var/www/openresults.run').replace('/var/backups/business-error-triage-20260926','/var/backups/openresults-static404-20261004')
source+='''
payload=json.load(sys.stdin);root=Path('/var/www/openresults.run');stage=Path('/var/backups/openresults-static404-20261004')
if payload['mode']=='prepare':result=prepare(root,stage,payload['files'],payload['before'])
elif payload['mode']=='publish':
 p=subprocess.run(['apache2ctl','configtest'],capture_output=True,text=True);assert p.returncode==0,p.stderr
 result=publish(root,stage)
else:result=remote(payload['mode'],{})
print(json.dumps(result))
'''
payload={'mode':mode}
if mode=='prepare':payload.update(files={n:(STAGE/'candidate'/n).read_text() for n in ['404/index.html','.htaccess']},before={'.htaccess':json.loads((STAGE/'baselines.json').read_text())['.htaccess']})
p=subprocess.run(['ssh','-o','BatchMode=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(source)],input=json.dumps(payload),capture_output=True,text=True,timeout=30)
print(p.stdout);print(p.stderr[-1500:]);(STAGE/('release-'+mode+'.json')).write_text(p.stdout);sys.exit(p.returncode)
