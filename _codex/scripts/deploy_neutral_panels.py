"""Palette-only CAS deployment. No backend actions, configuration, credentials or Git."""
import ast,base64,datetime,hashlib,json,pathlib,shlex,subprocess,sys
ROOT=pathlib.Path(__file__).resolve().parents[2]
baseline=json.loads((ROOT/'_codex/deploy/rr-neutral-baseline-20261026.json').read_text())
receipt=ROOT/'_codex/deploy/rr-neutral-20261026.json';proof_path=ROOT/'_codex/deploy/rr-neutral-tests-20261026.json'
previous=json.loads(receipt.read_text()) if receipt.exists() else {}
sha=lambda b:hashlib.sha256(b).hexdigest()
items=[]
for rel,info in baseline.items():
 data=(ROOT/rel).read_bytes();path='business.roadrunners.run/'+rel
 if sha(data)!=info['after'] or not info['structure_preserved']:raise SystemExit('Palette manifest mismatch '+rel)
 items.append({'path':path,'before':previous.get('candidate_hashes',{}).get(path,info['before']),'after':sha(data),'data':base64.b64encode(data).decode()})
candidate={i['path']:i['after'] for i in items}
if '--verify' in sys.argv:
 run=subprocess.run([sys.executable,'-B',str(ROOT/'_codex/scripts/test_helpdesk_tools_native.py'),'render'],capture_output=True,text=True,timeout=90)
 native=json.loads(run.stdout)
 if run.returncode or not native.get('ok'):print(run.stdout);raise SystemExit('Render failed')
 run=subprocess.run(['git','diff','--check'],cwd=ROOT,capture_output=True,text=True)
 if run.returncode:print(run.stdout);raise SystemExit('Whitespace check failed')
 proof={'checked_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'candidate_hashes':candidate,'native_render':native,'structure_preserved_files':len(items),'layout_or_logic_changes':False}
 proof_path.write_text(json.dumps(proof,ensure_ascii=False,indent=2)+'\n');print(json.dumps({'ok':True,'palette_files':len(items),'native_render':True,'layout_or_logic_changes':False}));raise SystemExit(0)
publish='--publish' in sys.argv
if publish:
 proof=json.loads(proof_path.read_text());age=(datetime.datetime.now(datetime.timezone.utc)-datetime.datetime.fromisoformat(proof['checked_at'])).total_seconds()
 if '--verified' not in sys.argv or not 0<=age<3600 or proof['candidate_hashes']!=candidate:raise SystemExit('Fresh matching verification required')
tree=ast.parse((ROOT/'_codex/scripts/deploy_vicky_cbg.py').read_text())
remote=next(ast.literal_eval(n.value) for n in tree.body if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='REMOTE' for t in n.targets))
old=next(line for line in remote.splitlines() if line.startswith('allowed='));remote=remote.replace(old,"allowed=set(p['allowed'])",1)
remote=remote.replace("preserved=p['preserved']","preserved={rel:sha(target(rel).read_bytes()) for rel in p['preserve_paths']}")
remote=remote.replace("prefix='business-vicky-cbg-'","prefix='business-rr-neutral-'").replace("prefix='.vicky-cbg-'","prefix='.rr-neutral-'")
old=next(line for line in remote.splitlines() if line.startswith(' for host,path,method,expected in '))
remote=remote.replace(old," for host,path,method,expected in [('business.roadrunners.run',path,'GET',200) for path in p['css_probes']]+[('business.roadrunners.run','/helpdesk/','GET',302),('business.roadrunners.run','/administracao/drive/','GET',302),('business.roadrunners.run','/saude-eventos/central/','GET',302)]:",1)
preserve=['business.roadrunners.run/'+rel for rel in ['Application.cfc','.htaccess','helpdesk/includes/backend.cfm','helpdesk/includes/workspace-actions.cfm','helpdesk/includes/workspace-init.cfm','helpdesk/includes/HelpdeskNotes.cfc','helpdesk/includes/HelpdeskReplies.cfc','api/helpdesk/auto-close.cfm','services/HelpdeskAutoClose.cfc','includes/backend/cron_jobs_service.cfm','services/geocoding/Store.cfc','services/geocoding/LocationWorker.cfc','administracao/usuarios/includes/backend.cfm','administracao/vicky/includes/backend.cfm']]
run=subprocess.run(['ssh','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-o','ConnectTimeout=12','rr-prod','python3 -c '+shlex.quote(remote)],input=json.dumps({'publish':publish,'files':items,'allowed':[i['path'] for i in items],'preserve_paths':preserve,'css_probes':['/'+rel+'?v=rr-neutral-20261026' for rel in baseline if rel.endswith('.css')]}).encode(),capture_output=True,timeout=180)
try:result=json.loads(run.stdout)
except ValueError:print(json.dumps({'ok':False,'error':run.stderr.decode(errors='replace')[-1200:]}));raise SystemExit(1)
if result.get('ok') and result.get('mode')=='published':
 result.update({'checked_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'verification':proof,'ddl':False,'credential_changes':False,'git_mutations':False,'palette_only':True})
 result['previous_publications']=previous.get('previous_publications',[])+([{'backup':previous['backup'],'candidate_hashes':previous['candidate_hashes']}] if previous else [])
 receipt.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
print(json.dumps({k:v for k,v in result.items() if k not in ['candidate_hashes','preserved_files','verification']},ensure_ascii=False));raise SystemExit(0 if not run.returncode and result.get('ok') else 1)
