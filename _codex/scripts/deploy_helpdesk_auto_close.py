"""Publish only automatic helpdesk close runtime; default read-only preflight."""
import ast,base64,datetime,hashlib,json,pathlib,shlex,subprocess,sys
ROOT=pathlib.Path(__file__).resolve().parents[2]
paths={'services/HelpdeskAutoClose.cfc':None,'api/helpdesk/auto-close.cfm':None,'includes/backend/cron_jobs_service.cfm':'068f57f87e214ca9d34ec186c9af227649462068158b039861229cdf86fd203a'}
sha=lambda b:hashlib.sha256(b).hexdigest()
receipt=ROOT/'_codex/deploy/helpdesk-auto-close-20261026.json';proof_path=ROOT/'_codex/deploy/helpdesk-auto-close-tests-20261026.json'
previous=json.loads(receipt.read_text()) if receipt.exists() else {}
items=[]
for rel,before in paths.items():
 path='business.roadrunners.run/'+rel;body=(ROOT/rel).read_bytes()
 items.append({'path':path,'before':previous.get('candidate_hashes',{}).get(path,before),'after':sha(body),'data':base64.b64encode(body).decode()})
candidate={i['path']:i['after'] for i in items}
if '--verify' in sys.argv:
 results=[]
 for mode in ['native','transaction','security','cron','http']:
  run=subprocess.run([sys.executable,'-B',str(ROOT/'_codex/scripts/test_helpdesk_auto_close_native.py'),mode],capture_output=True,text=True,timeout=90)
  result=json.loads(run.stdout);results.append({'mode':mode,**result})
  if run.returncode or not result.get('ok') or not result.get('stage_removed'):print(run.stdout[-5000:]);raise SystemExit('Failed '+mode)
 proof_path.write_text(json.dumps({'checked_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'candidate_hashes':candidate,'tests':results},ensure_ascii=False,indent=2)+'\n')
 print(json.dumps({'ok':True,'native_suites':len(results)}));raise SystemExit(0)
publish='--publish' in sys.argv
if publish:
 proof=json.loads(proof_path.read_text());age=(datetime.datetime.now(datetime.timezone.utc)-datetime.datetime.fromisoformat(proof['checked_at'])).total_seconds()
 if '--verified' not in sys.argv or not 0<=age<3600 or proof['candidate_hashes']!=candidate:raise SystemExit('Fresh matching verification required')
tree=ast.parse((ROOT/'_codex/scripts/helpdesk_tools_release_harness.py').read_text())
remote=next(ast.literal_eval(n.value) for n in tree.body if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='REMOTE' for t in n.targets))
old=next(line for line in remote.splitlines() if line.startswith('allowed='));remote=remote.replace(old,"allowed=set(p['allowed'])",1)
remote=remote.replace("prefix='business-vicky-cbg-'","prefix='business-helpdesk-close-'")
remote=remote.replace("preserved=p['preserved']","preserved={rel:sha(target(rel).read_bytes()) for rel in p['preserve_paths']}")
remote=remote.replace("fd,tmp=tempfile.mkstemp(prefix='.vicky-cbg-',dir=path.parent)","path.parent.mkdir(mode=0o755,parents=True,exist_ok=True)\n fd,tmp=tempfile.mkstemp(prefix='.helpdesk-close-',dir=path.parent)")
old=next(line for line in remote.splitlines() if line.startswith(' for host,path,method,expected in '))
remote=remote.replace(old," for host,path,method,expected in [('business.roadrunners.run','/api/helpdesk/auto-close.cfm','GET',405),('business.roadrunners.run','/api/helpdesk/auto-close.cfm','POST',401),('business.roadrunners.run','/helpdesk/','GET',302),('business.roadrunners.run','/cron-jobs/runner.cfm','GET',401)]:",1)
preserve=['business.roadrunners.run/'+p for p in ['Application.cfc','.htaccess','cron-jobs/runner.cfm','helpdesk/index.cfm','helpdesk/home.cfm','helpdesk/includes/backend.cfm','helpdesk/includes/workspace-actions.cfm','helpdesk/includes/workspace.cfm','includes/backend/require_admin.cfm','services/geocoding/Store.cfc','services/geocoding/LocationWorker.cfc','administracao/vicky/home.cfm','administracao/vicky/includes/backend.cfm','services/UserAcquisitionMetrics.cfc','administracao/usuarios/home.cfm','administracao/usuarios/includes/backend.cfm']]
run=subprocess.run(['ssh','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-o','ConnectTimeout=12','rr-prod','python3 -c '+shlex.quote(remote)],input=json.dumps({'publish':publish,'files':items,'allowed':[i['path'] for i in items],'preserve_paths':preserve}).encode(),capture_output=True,timeout=160)
try:result=json.loads(run.stdout)
except ValueError:print(json.dumps({'ok':False,'error':run.stderr.decode(errors='replace')[-1000:]}));raise SystemExit(1)
if result.get('ok') and result.get('mode')=='published':
 result.update({'checked_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'tests':proof['tests'],'ddl':False,'credential_changes':False,'git_mutations':False})
 result['previous_publications']=previous.get('previous_publications',[])+([{'backup':previous['backup'],'candidate_hashes':previous['candidate_hashes']}] if previous else [])
 receipt.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
print(json.dumps({k:v for k,v in result.items() if k not in ['tests','preserved_files']},ensure_ascii=False));raise SystemExit(0 if not run.returncode and result.get('ok') else 1)
