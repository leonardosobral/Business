"""Scoped reversible release of the international event editor.

Default is read-only preflight. --verify runs native and frontend checks.
--publish --verified requires matching fresh evidence; never mutates Git,
credentials, schema, permission policy or unrelated runtime files.
"""
import ast,base64,datetime,hashlib,json,pathlib,shlex,subprocess,sys
ROOT=pathlib.Path(__file__).resolve().parents[2]
FILES=['services/EventLocationPolicy.cfc','eventos/includes/event_location_fields.cfm',
       'eventos/assets/event-location.js','eventos/includes/event_location_error.cfm',
       'eventos/form_edicao.cfm','eventos/includes/backend/event_mutations.cfm',
       'eventos/includes/localizacoes_confirmadas.cfm','eventos/home.cfm']
NEW=set(FILES[:4]);sha=lambda data:hashlib.sha256(data).hexdigest()
before={name:None if name in NEW else sha(subprocess.check_output(['git','show','HEAD:'+name],cwd=ROOT)) for name in FILES}
previous=json.loads((ROOT/'_codex/deploy/geocoding-review-edit-20261022.json').read_text())
preserved={**previous['preserved_files'],**previous['candidate_hashes']}
for name in ['eventos/includes/backend/event_delegation.cfm','eventos/includes/backend/backend_evento_edicao.cfm']:
    preserved[name]=sha(subprocess.check_output(['git','show','HEAD:'+name],cwd=ROOT))
candidate={name:sha((ROOT/name).read_bytes()) for name in FILES}
publish='--publish' in sys.argv;tests=[]
verification=ROOT/'_codex/deploy/event-location-tests-20261022.json'
node='/Users/geraldoprotta/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node'
if publish and '--verified' in sys.argv:
    proof=json.loads(verification.read_text());age=(datetime.datetime.now(datetime.timezone.utc)-datetime.datetime.fromisoformat(proof['checked_at'])).total_seconds()
    if not 0<=age<1800 or proof['candidate_hashes']!=candidate or len(proof['tests'])!=49 or not all(t.get('ok') and t.get('stage_archived') for t in proof['tests']) or not proof.get('frontend_ok') or not proof.get('reader_ok'):raise SystemExit('Fresh matching tests required')
    tests=proof['tests']
elif publish or '--verify' in sys.argv:
    suites=[('event_location',name) for name in ['event_location','event_location_mutation','event_location_view','event_location_new_form','event_location_error']]
    suites += [('geocoding',name) for name in ['all','radar_view','radar_priority','radar_coverage','radar_contract']]
    for family,name in suites:
        runner=ROOT/('_codex/scripts/test_event_location_native.py' if family=='event_location' else '_codex/scripts/test_geocoding_native.py')
        run=subprocess.run([sys.executable,'-B',str(runner),name],capture_output=True,text=True,timeout=900)
        try:results=[json.loads(line) for line in run.stdout.splitlines() if line.strip()]
        except ValueError:raise SystemExit('Invalid test output '+name)
        ok=not run.returncode and results and all(t.get('ok') and t.get('stage_archived') for t in results);tests.extend(results)
        print(json.dumps({'suite':name,'ok':bool(ok),'checks':len(results)}),flush=True)
        if not ok:print(run.stdout[-10000:]);print(run.stderr[-1000:]);raise SystemExit('Verification failed')
    if len(tests)!=49:raise SystemExit('Unexpected test coverage')
    subprocess.run([node,'--test','_codex/tests/event_location_frontend.test.mjs'],cwd=ROOT,check=True)
    subprocess.run([node,'--check','eventos/assets/event-location.js'],cwd=ROOT,check=True)
    subprocess.run([sys.executable,'-B','-m','unittest','discover','-s','_codex/tests/geocoding','-p','test_source_fetcher.py'],cwd=ROOT,check=True)
    if candidate!={name:sha((ROOT/name).read_bytes()) for name in FILES}:raise SystemExit('Candidate changed while testing')
transport=ROOT/'_codex/scripts/deploy_geocoding_sources.py';tree=ast.parse(transport.read_text())
remote=next(ast.literal_eval(n.value) for n in tree.body if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='REMOTE' for t in n.targets))
anchor='files=[];manifest={}'
guard="""allowed=set(p.pop('allowed'));preserved=p.pop('preserved')
if {f['path'] for f in p['files']}!=allowed:raise SystemExit('Unexpected publication scope')
for rel,expected in preserved.items():
 if sha(target(rel).read_bytes())!=expected:raise SystemExit('Preserved production file changed: '+rel)
files=[];manifest={}"""
if remote.count(anchor)!=1:raise SystemExit('Transport guard changed')
remote=remote.replace(anchor,guard,1)
anchor="fd,tmp=tempfile.mkstemp(prefix='.geo-sources-',dir=path.parent)"
if remote.count(anchor)!=1:raise SystemExit('Directory guard changed')
remote=remote.replace(anchor,"path.parent.mkdir(mode=0o755,parents=True,exist_ok=True)\n "+anchor,1)
anchor="if not all(check['ok'] for check in checks):raise RuntimeError('Final hash mismatch')"
remote=remote.replace(anchor,anchor+"\n for rel,expected in preserved.items():\n  if sha(target(rel).read_bytes())!=expected:raise RuntimeError('Concurrent preserved-file change: '+rel)",1)
anchor="('/services/geocoding/Sources.cfc','GET',403)"
# Root services follow the existing application login redirect (302); only
# services/geocoding has the separate directory-level 403 rule. Keep both.
extra="('/services/EventLocationPolicy.cfc','GET',302),('/eventos/includes/event_location_fields.cfm','GET',403),('/eventos/includes/event_location_error.cfm','GET',403),('/eventos/assets/event-location.js','GET',200),('/eventos/?id_evento=38202','GET',302),"+anchor
remote=remote.replace(anchor,extra,1)
payload={'publish':publish,'allowed':FILES,'preserved':preserved,'files':[{'path':name,'before':before[name],'data':base64.b64encode((ROOT/name).read_bytes()).decode()} for name in FILES]}
run=subprocess.run(['ssh','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-o','ConnectTimeout=12','rr-prod','python3 -c '+shlex.quote(remote)],input=json.dumps(payload).encode(),capture_output=True,timeout=180)
try:result=json.loads(run.stdout)
except ValueError:print(json.dumps({'ok':False,'diagnostic':run.stderr.decode(errors='replace')[-1000:]}));raise SystemExit(1)
if result.get('ok') and result.get('mode')=='published':
    result.update({'checked_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'candidate_hashes':candidate,'preserved_files':preserved,'native_tests':tests,'frontend_ok':True,'reader_ok':True,'git_mutations':False,'schema_changed':False,'credentials_changed':False,'verification_limitations':['Local account-delegation suite unavailable: PostgreSQL initdb runtime missing; native event-scope checks passed.']})
    (ROOT/'_codex/deploy/event-location-20261022.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
elif result.get('ok') and tests:
    verification.write_text(json.dumps({'checked_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'candidate_hashes':candidate,'tests':tests,'frontend_ok':True,'reader_ok':True,'preflight':result},ensure_ascii=False,indent=2)+'\n')
print(json.dumps({k:v for k,v in result.items() if k not in ['native_tests']},ensure_ascii=False))
raise SystemExit(0 if not run.returncode and result.get('ok') else 1)
