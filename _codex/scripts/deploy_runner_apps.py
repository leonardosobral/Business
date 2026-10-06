"""Scoped catalogue release: provider -> API/menu -> legacy redirect, with backups."""
from pathlib import Path
import json,subprocess,shlex,sys
ROOT=Path(__file__).resolve().parents[2];STAGE=ROOT/'_codex/staging/runner-apps-20261004'
phase,mode=sys.argv[1:];assert phase in ('provider','rr','legacy');assert mode in ('prepare','compile','publish','verify','rollback')
project='rr' if phase=='rr' else 'business'
root='/var/www/roadrunners.com.br' if project=='rr' else '/var/www/business.roadrunners.run'
backup='/var/backups/runner-apps-20261004-v2-'+phase
if phase=='provider':names=['api/portal/runner-apps/Catalog.cfc']
elif phase=='legacy':names=['api/portal/runner-apps/index.cfm','api/portal/runner-apps/Application.cfc']
else:names=['services/RunnerAppsMenuCache.cfc','services/RunnerAppsHttpSource.cfc','public-api/v1/discovery/runner-apps.cfm','public-api/openapi.json','public-api/Application.cfc','includes/estrutura/menu_apps_data.cfm']
baselines=json.loads((STAGE/(project+'-baselines.json')).read_text());before={n:baselines[n] for n in names if n in baselines}
source=(ROOT/'_codex/scripts/deploy_error_triage.py').read_text().split("if __name__=='__main__':")[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path("+repr(root)+")").replace('/var/www/business.roadrunners.run',root).replace('/var/backups/business-error-triage-20260926',backup).replace("next(iter(m['before']))","next(iter(m['before']), 'api/portal/runner-apps/index.cfm')")
source+="\npayload=json.load(sys.stdin);root=Path("+repr(root)+");stage=Path("+repr(backup)+")\n"
source+='''if payload['mode']=='prepare':result=prepare(root,stage,payload['files'],payload['before'])
elif payload['mode']=='publish':
 c=json.loads((stage/'compile.json').read_text());assert c['returncode']==0 and c['compiled_files']==payload['count']
 result=publish(root,stage);(stage/'published.json').write_text(json.dumps(result))
else:result=remote(payload['mode'],{})
print(json.dumps(result))
'''
payload={'mode':mode,'count':len(names)}
if mode=='prepare':payload.update(files={n:(STAGE/'candidate'/project/n).read_text() for n in names},before=before)
p=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(source)],input=json.dumps(payload),capture_output=True,text=True,timeout=200)
print(p.stdout);print(p.stderr[-2000:]);(STAGE/(phase+'-release-'+mode+'.json')).write_text(p.stdout);sys.exit(p.returncode)
