from pathlib import Path
import base64, hashlib, json, shlex, subprocess
stage=Path(__file__).resolve().parent
root=Path('/Users/Shared/Projects/RunnerHub/Business')
names=['eventos/form_edicao.cfm','eventos/includes/backend/backend_evento_edicao.cfm','eventos/includes/variaveis.cfm']
new=['services/EventFactReviewService.cfc','eventos/form_edicao_fontes.cfm','eventos/includes/backend/fontes_revisoes.cfm']
watch=['includes/backend/require_admin.cfm','eventos/includes/backend/event_delegation.cfm','eventos/includes/backend/event_mutations.cfm','eventos/home.cfm','includes/backend/backend_login.cfm','services/EventRegistrationAvailability.cfc']
remote='''from pathlib import Path
import base64,hashlib,json,sys
root=Path('/var/www/business.roadrunners.run');p=json.load(sys.stdin)
r={'files':{},'watch':{}}
for n in p['names']:
 b=(root/n).read_bytes();r['files'][n]=base64.b64encode(b).decode()
for n in p['watch']:r['watch'][n]=hashlib.sha256((root/n).read_bytes()).hexdigest()
for n in p['new']:
 if (root/n).exists():raise RuntimeError('New runtime already exists: '+n)
print(json.dumps(r))'''
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps({'names':names,'watch':watch,'new':new}),text=True,capture_output=True,timeout=40)
if cp.returncode:raise RuntimeError(cp.stderr)
r=json.loads(cp.stdout);before={}
for n,v in r['files'].items():
 b=base64.b64decode(v)
 if (root/n).read_bytes()!=b:raise RuntimeError('Local differs from production: '+n)
 for folder in ['baseline','candidate']:
  target=stage/folder/n;target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(b)
 before[n]=hashlib.sha256(b).hexdigest()
(stage/'before.json').write_text(json.dumps(before,indent=2))
(stage/'watch.json').write_text(json.dumps(r['watch'],indent=2))
print(json.dumps({'baselines_matched':len(before),'unrelated_files_watched':len(r['watch']),'new_paths_absent':len(new)}))
