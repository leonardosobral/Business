"""Publish only numbered mandala delivery runtime, with CAS and recoverable backup."""
import ast,base64,datetime,hashlib,json,pathlib,shlex,subprocess,sys
ROOT=pathlib.Path(__file__).resolve().parents[2]
PATHS=['desafios/includes/MandalaDelivery.cfc','desafios/includes/brasil_gigante_mandala_action.cfm','desafios/includes/backend.cfm','desafios/includes/brasil_gigante_table.cfm','desafios/includes/brasil_gigante_panel.cfm','desafios/includes/exportar_brasil_gigante.cfm']
sha=lambda b:hashlib.sha256(b).hexdigest()
receipt=ROOT/'_codex/deploy/cbg-mandala-number-20261104.json';proof_path=ROOT/'_codex/deploy/cbg-mandala-number-tests-20261104.json'
previous=json.loads(receipt.read_text()) if receipt.exists() else {};items=[]
for rel in PATHS:
 data=(ROOT/rel).read_bytes();old=subprocess.run(['git','show','HEAD:'+rel],cwd=ROOT,capture_output=True);path='business.roadrunners.run/'+rel
 items.append({'path':path,'before':previous.get('candidate_hashes',{}).get(path,sha(old.stdout) if not old.returncode else None),'after':sha(data),'data':base64.b64encode(data).decode()})
candidate={i['path']:i['after'] for i in items}
if '--verify' in sys.argv:
 results=[]
 for mode in ['validation','persistence','render','guards','ranking']:
  run=subprocess.run([sys.executable,'-B',str(ROOT/'_codex/scripts/test_mandala_native.py'),mode],capture_output=True,text=True,timeout=90)
  result=json.loads(run.stdout);results.append({'mode':mode,**result})
  if run.returncode or not result.get('ok') or not result.get('stage_removed'):print(run.stdout[-5000:]);raise SystemExit('Failed '+mode)
 run=subprocess.run(['git','diff','--check','--',*PATHS],cwd=ROOT,capture_output=True,text=True)
 if run.returncode:print(run.stdout);raise SystemExit('Scoped whitespace check failed')
 proof_path.write_text(json.dumps({'checked_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'candidate_hashes':candidate,'tests':results},ensure_ascii=False,indent=2)+'\n')
 print(json.dumps({'ok':True,'native_suites':len(results)}));raise SystemExit(0)
publish='--publish' in sys.argv
if publish:
 proof=json.loads(proof_path.read_text());age=(datetime.datetime.now(datetime.timezone.utc)-datetime.datetime.fromisoformat(proof['checked_at'])).total_seconds()
 if '--verified' not in sys.argv or not 0<=age<3600 or proof['candidate_hashes']!=candidate:raise SystemExit('Fresh matching verification required')
tree=ast.parse((ROOT/'_codex/scripts/deploy_vicky_cbg.py').read_text())
remote=next(ast.literal_eval(n.value) for n in tree.body if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='REMOTE' for t in n.targets))
old=next(line for line in remote.splitlines() if line.startswith('allowed='));remote=remote.replace(old,"allowed=set(p['allowed'])",1)
remote=remote.replace("preserved=p['preserved']","preserved={rel:sha(target(rel).read_bytes()) for rel in p['preserve_paths']}")
remote=remote.replace("prefix='business-vicky-cbg-'","prefix='business-cbg-mandala-'").replace("prefix='.vicky-cbg-'","prefix='.cbg-mandala-'")
remote=remote.replace("target('roadrunners.com.br/repositories/VickyProactiveRepository.cfc').stat()","target('business.roadrunners.run/desafios/includes/backend.cfm').stat()")
old=next(line for line in remote.splitlines() if line.startswith(' for host,path,method,expected in '))
remote=remote.replace(old," for host,path,method,expected in [('business.roadrunners.run','/desafios/circuitobrasilgigante/','GET',302),('business.roadrunners.run','/desafios/includes/exportar_brasil_gigante.cfm','GET',403)]:",1)
preserve=['business.roadrunners.run/'+rel for rel in ['Application.cfc','.htaccess','includes/backend/brasil_gigante_challenge_access.cfm','includes/backend/require_brasil_gigante_challenge_access.cfm','desafios/index.cfm','desafios/home.cfm','desafios/includes/brasil_gigante_validacoes_backend.cfm','desafios/includes/catarinense_panel.cfm','desafios/includes/catarinense_table.cfm','desafios/includes/catarinense_contact_modal.cfm','includes/estrutura/sidenav.cfm','includes/estrutura/head.cfm','assets/css/business-ui.css','services/geocoding/Store.cfc']]
run=subprocess.run(['ssh','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-o','ConnectTimeout=12','rr-prod','python3 -c '+shlex.quote(remote)],input=json.dumps({'publish':publish,'files':items,'allowed':[i['path'] for i in items],'preserve_paths':preserve}).encode(),capture_output=True,timeout=160)
try:result=json.loads(run.stdout)
except ValueError:print(json.dumps({'ok':False,'error':run.stderr.decode(errors='replace')[-1000:]}));raise SystemExit(1)
if result.get('ok') and result.get('mode')=='published':
 result.update({'checked_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'tests':proof['tests'],'ddl':False,'credential_changes':False,'git_mutations':False,'real_deliveries_in_tests':False})
 result['previous_publications']=previous.get('previous_publications',[])+([{'backup':previous['backup'],'candidate_hashes':previous['candidate_hashes']}] if previous else [])
 receipt.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
print(json.dumps({k:v for k,v in result.items() if k not in ['tests','preserved_files','candidate_hashes']},ensure_ascii=False));raise SystemExit(0 if not run.returncode and result.get('ok') else 1)
