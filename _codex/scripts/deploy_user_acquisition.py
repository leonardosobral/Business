"""Publish only the user-acquisition widget. Default preflight; --verify first.

No migrations, user writes, provider calls, credential changes or Git mutations.
"""
import ast,base64,datetime,hashlib,json,pathlib,shlex,subprocess,sys
ROOT=pathlib.Path(__file__).resolve().parents[2]
NEW=['services/UserAcquisitionMetrics.cfc','administracao/usuarios/includes/acquisition.cfm','administracao/usuarios/assets/acquisition.js','administracao/usuarios/assets/acquisition.css']
FILES=NEW+['administracao/usuarios/includes/backend.cfm','administracao/usuarios/home.cfm']
sha=lambda data:hashlib.sha256(data).hexdigest()
receipt_path=ROOT/'_codex/deploy/user-acquisition-20261023.json'
previous=json.loads(receipt_path.read_text()) if receipt_path.exists() else {}
before={p:previous.get('candidate_hashes',{}).get(p,None if p in NEW else sha(subprocess.check_output(['git','show','HEAD:'+p],cwd=ROOT))) for p in FILES}
candidate={p:sha((ROOT/p).read_bytes()) for p in FILES}
geo=json.loads((ROOT/'_codex/deploy/geocoding-economy-20261023.json').read_text())
preserved={**geo['preserved_files'],**geo['candidate_hashes']}
for p in ['administracao/usuarios/index.cfm','services/BusinessDevLogin.cfc','includes/backend/require_admin_dev.cfm','includes/backend/require_real_platform_context.cfm']:
    preserved[p]=sha(subprocess.check_output(['git','show','HEAD:'+p],cwd=ROOT))
for p in FILES:preserved.pop(p,None)
proof_path=ROOT/'_codex/deploy/user-acquisition-tests-20261023.json'
node='/Users/geraldoprotta/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node'
if '--verify' in sys.argv:
    tests=[]
    for mode in ['source','native','render']:
        run=subprocess.run([sys.executable,'-B',str(ROOT/'_codex/scripts/test_user_acquisition_native.py'),mode],capture_output=True,text=True,timeout=90)
        result=json.loads(run.stdout);tests.append(result)
        if run.returncode or not result.get('ok') or not result.get('stage_removed'):print(run.stdout[-6000:]);raise SystemExit('Native test failed: '+mode)
    commands=[[node,'--test','_codex/tests/user-acquisition.test.cjs'],[node,'--check','administracao/usuarios/assets/acquisition.js'],[sys.executable,'-B','-m','unittest','discover','-s','_codex/tests','-p','test_user_manager_merge_contract.py']]
    for command in commands:
        check=subprocess.run(command,cwd=ROOT,capture_output=True,text=True,timeout=60)
        if check.returncode:print(check.stdout[-3000:]);print(check.stderr[-3000:]);raise SystemExit('Local regression failed')
    if not previous:
        run=subprocess.run([sys.executable,'-B',str(ROOT/'_codex/scripts/test_dev_login_native.py'),'--published'],capture_output=True,text=True,timeout=180)
        dev=json.loads(run.stdout)
        if run.returncode or not dev.get('ok') or not dev.get('stage_removed'):print(run.stdout[-5000:]);raise SystemExit('DEV login regression failed')
    else:dev=previous.get('dev_login_regression',{})
    if candidate!={p:sha((ROOT/p).read_bytes()) for p in FILES}:raise SystemExit('Candidate changed while testing')
    proof_path.write_text(json.dumps({'checked_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'candidate_hashes':candidate,'native_tests':tests,'frontend_tests':4,'merge_contract_tests':3,'dev_login_regression':dev},ensure_ascii=False,indent=2)+'\n')
    print(json.dumps({'ok':True,'native_suites':len(tests),'frontend_tests':4,'merge_tests':3,'dev_login_checks':dev.get('checks')}));raise SystemExit(0)
publish='--publish' in sys.argv
if publish:
    if '--verified' not in sys.argv:raise SystemExit('Run --verify first')
    proof=json.loads(proof_path.read_text());age=(datetime.datetime.now(datetime.timezone.utc)-datetime.datetime.fromisoformat(proof['checked_at'])).total_seconds()
    if not 0<=age<3600 or proof['candidate_hashes']!=candidate or not all(t.get('ok') and t.get('stage_removed') for t in proof['native_tests']) or not proof['dev_login_regression'].get('ok'):raise SystemExit('Fresh matching tests required')
tree=ast.parse((ROOT/'_codex/scripts/deploy_geocoding_sources.py').read_text())
remote=next(ast.literal_eval(n.value) for n in tree.body if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='REMOTE' for t in n.targets))
remote=remote.replace("prefix='business-geocoding-sources-'","prefix='business-user-acquisition-'")
anchor='files=[];manifest={}'
guard="""allowed=set(p.pop('allowed'));preserved=p.pop('preserved')
if {f['path'] for f in p['files']}!=allowed:raise SystemExit('Unexpected publication scope')
for rel,expected in preserved.items():
 if sha(target(rel).read_bytes())!=expected:raise SystemExit('Preserved production file changed: '+rel)
files=[];manifest={}"""
if remote.count(anchor)!=1:raise SystemExit('Transport scope guard changed')
remote=remote.replace(anchor,guard,1)
anchor="fd,tmp=tempfile.mkstemp(prefix='.geo-sources-',dir=path.parent)"
if remote.count(anchor)!=1:raise SystemExit('Transport atomic guard changed')
remote=remote.replace(anchor,"path.parent.mkdir(mode=0o755,parents=True,exist_ok=True)\n "+anchor,1)
anchor="if not all(check['ok'] for check in checks):raise RuntimeError('Final hash mismatch')"
remote=remote.replace(anchor,anchor+"\n for rel,expected in preserved.items():\n  if sha(target(rel).read_bytes())!=expected:raise RuntimeError('Concurrent preserved-file change: '+rel)",1)
anchor="('/services/geocoding/Sources.cfc','GET',403)"
extra="('/administracao/usuarios/','GET',302),('/administracao/usuarios/includes/acquisition.cfm','GET',403),('/administracao/usuarios/assets/acquisition.js','GET',200),('/administracao/usuarios/assets/acquisition.css','GET',200),('/services/UserAcquisitionMetrics.cfc','GET',302),"+anchor
if remote.count(anchor)!=1:raise SystemExit('Transport access guard changed')
remote=remote.replace(anchor,extra,1)
payload={'publish':publish,'allowed':FILES,'preserved':preserved,'files':[{'path':p,'before':before[p],'data':base64.b64encode((ROOT/p).read_bytes()).decode()} for p in FILES]}
run=subprocess.run(['ssh','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-o','ConnectTimeout=12','rr-prod','python3 -c '+shlex.quote(remote)],input=json.dumps(payload).encode(),capture_output=True,timeout=180)
try:result=json.loads(run.stdout)
except ValueError:print(json.dumps({'ok':False,'diagnostic':run.stderr.decode(errors='replace')[-1000:]}));raise SystemExit(1)
if result.get('ok') and result.get('mode')=='published':
    result.update({'checked_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'candidate_hashes':candidate,'preserved_files':preserved,'native_tests':proof['native_tests'],'dev_login_regression':proof['dev_login_regression'],'frontend_tests':4,'merge_contract_tests':3,'git_mutations':False,'schema_changed':False})
    receipt_path.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
print(json.dumps({k:v for k,v in result.items() if k not in ['native_tests','preserved_files','dev_login_regression']},ensure_ascii=False));raise SystemExit(0 if not run.returncode and result.get('ok') else 1)
