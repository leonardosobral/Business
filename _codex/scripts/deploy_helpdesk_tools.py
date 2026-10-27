"""Scoped CAS runtime publication; private library data is never replaced by deploy."""
import ast,base64,datetime,hashlib,json,pathlib,shlex,subprocess,sys
ROOT=pathlib.Path(__file__).resolve().parents[2];RR=ROOT.parent/'RoadRunners'
sha=lambda data:hashlib.sha256(data).hexdigest()
receipt=ROOT/'_codex/deploy/helpdesk-tools-20261026.json';proof_path=ROOT/'_codex/deploy/helpdesk-tools-tests-20261026.json'
previous=json.loads(receipt.read_text()) if receipt.exists() else {}
# RR privacy guard must land before notes can be created in Business.
files=[(RR,'roadrunners.com.br/','atendimento/index.cfm')]+[(ROOT,'business.roadrunners.run/',rel) for rel in [
 'helpdesk/includes/HelpdeskNotes.cfc','helpdesk/includes/HelpdeskReplies.cfc','helpdesk/includes/workspace-replies-actions.cfm','helpdesk/includes/workspace-replies.cfm',
 'helpdesk/includes/workspace-init.cfm','helpdesk/includes/backend.cfm','helpdesk/includes/workspace-actions.cfm','helpdesk/assets/workspace.css','helpdesk/assets/workspace.js','helpdesk/includes/workspace.cfm']]
items=[]
for root,prefix,rel in files:
 run=subprocess.run(['git','show','HEAD:'+rel],cwd=root,capture_output=True)
 before=sha(run.stdout) if not run.returncode else None
 path=prefix+rel;data=(root/rel).read_bytes()
 items.append({'path':path,'before':previous.get('candidate_hashes',{}).get(path,before),'after':sha(data),'data':base64.b64encode(data).decode()})
candidate={i['path']:i['after'] for i in items}
if '--verify' in sys.argv:
 results=[]
 for mode in ['notes','replies','render','guards']:
  run=subprocess.run([sys.executable,'-B',str(ROOT/'_codex/scripts/test_helpdesk_tools_native.py'),mode],capture_output=True,text=True,timeout=90)
  result=json.loads(run.stdout);results.append({'mode':mode,**result})
  if run.returncode or not result.get('ok') or not result.get('stage_removed'):print(run.stdout[-5000:]);raise SystemExit('Failed '+mode)
 run=subprocess.run(['node','--test',str(ROOT/'_codex/tests/helpdesk-tools.test.cjs')],cwd=ROOT,capture_output=True,text=True)
 if run.returncode:print(run.stdout);raise SystemExit('Failed JS tests')
 proof_path.write_text(json.dumps({'checked_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'candidate_hashes':candidate,'tests':results,'js_tests':4},ensure_ascii=False,indent=2)+'\n')
 print(json.dumps({'ok':True,'native_suites':len(results),'js_tests':4}));raise SystemExit(0)
publish='--publish' in sys.argv
if publish:
 proof=json.loads(proof_path.read_text());age=(datetime.datetime.now(datetime.timezone.utc)-datetime.datetime.fromisoformat(proof['checked_at'])).total_seconds()
 if '--verified' not in sys.argv or not 0<=age<3600 or proof['candidate_hashes']!=candidate:raise SystemExit('Fresh matching verification required')
tree=ast.parse((ROOT/'_codex/scripts/helpdesk_tools_release_harness.py').read_text())
remote=next(ast.literal_eval(n.value) for n in tree.body if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='REMOTE' for t in n.targets))
old=next(line for line in remote.splitlines() if line.startswith('allowed='));remote=remote.replace(old,"allowed=set(p['allowed'])",1)
remote=remote.replace("preserved=p['preserved']","preserved={rel:sha(target(rel).read_bytes()) for rel in p['preserve_paths']}")
remote=remote.replace("prefix='business-vicky-cbg-'","prefix='business-helpdesk-tools-'").replace("prefix='.vicky-cbg-'","prefix='.helpdesk-tools-'")
remote=remote.replace("target('roadrunners.com.br/repositories/VickyProactiveRepository.cfc').stat()","target('business.roadrunners.run/helpdesk/includes/backend.cfm').stat()")
needle="published=[];metadata={};probes=[]"
remote=remote.replace(needle,needle+'''
# This new data directory is private to the runtime, never a public URL.
import pwd
owner=pwd.getpwnam('coldfusion');base=pathlib.Path('/var/lib/runnerhub-business');storage=base/'helpdesk'
if not base.exists():base.mkdir(mode=0o755)
if base.is_symlink() or storage.is_symlink():raise RuntimeError('Unsafe library directory')
if not storage.exists():storage.mkdir(mode=0o700);os.chown(storage,owner.pw_uid,owner.pw_gid)
if storage.stat().st_uid!=owner.pw_uid or stat.S_IMODE(storage.stat().st_mode)!=0o700:raise RuntimeError('Unexpected private directory permissions')
data_file=storage/'quick-replies.json'
if data_file.exists():
 if data_file.is_symlink():raise RuntimeError('Unsafe library file')
 (backup/'quick-replies-before.json').write_bytes(data_file.read_bytes());os.chmod(backup/'quick-replies-before.json',0o600)
''')
old=next(line for line in remote.splitlines() if line.startswith(' for host,path,method,expected in '))
remote=remote.replace(old," for host,path,method,expected in [('business.roadrunners.run','/helpdesk/','GET',302),('business.roadrunners.run','/helpdesk/','POST',302),('roadrunners.run','/atendimento/','GET',302)]:",1)
preserve=['business.roadrunners.run/'+rel for rel in ['Application.cfc','.htaccess','helpdesk/home.cfm','helpdesk/includes/HelpdeskAI.cfc','api/helpdesk/auto-close.cfm','services/HelpdeskAutoClose.cfc','includes/backend/cron_jobs_service.cfm','cron-jobs/runner.cfm','services/geocoding/Store.cfc','administracao/vicky/home.cfm','administracao/vicky/includes/backend.cfm','administracao/usuarios/home.cfm','administracao/usuarios/includes/backend.cfm']]+['roadrunners.com.br/repositories/SupportRepository.cfc']
run=subprocess.run(['ssh','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-o','ConnectTimeout=12','rr-prod','python3 -c '+shlex.quote(remote)],input=json.dumps({'publish':publish,'files':items,'allowed':[i['path'] for i in items],'preserve_paths':preserve}).encode(),capture_output=True,timeout=160)
try:result=json.loads(run.stdout)
except ValueError:print(json.dumps({'ok':False,'error':run.stderr.decode(errors='replace')[-1500:]}));raise SystemExit(1)
if result.get('ok') and result.get('mode')=='published':
 result.update({'checked_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'tests':proof['tests'],'js_tests':4,'private_library':'/var/lib/runnerhub-business/helpdesk/quick-replies.json','ddl':False,'credential_changes':False,'git_mutations':False})
 result['previous_publications']=previous.get('previous_publications',[])+([{'backup':previous['backup'],'candidate_hashes':previous['candidate_hashes']}] if previous else [])
 receipt.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
print(json.dumps({k:v for k,v in result.items() if k not in ['tests','preserved_files']},ensure_ascii=False));raise SystemExit(0 if not run.returncode and result.get('ok') else 1)
