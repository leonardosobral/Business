"""Publish only inline quick-review corrections against the recorded production baseline.

Default: read-only preflight. --verify: all native tests, reader tests and JS syntax.
--publish --verified: require matching successful checks less than 30 minutes old.
No Git, schema, credentials, configuration or unrelated runtime changes.
"""
import ast
import base64
import datetime
import hashlib
import json
import pathlib
import shlex
import subprocess
import sys

ROOT=pathlib.Path(__file__).resolve().parents[2]
FILES=['services/geocoding/ReviewInput.cfc','services/geocoding/EnrichmentStore.cfc',
       'services/geocoding/LocationStore.cfc','services/geocoding/LocationWorker.cfc',
       'services/geocoding/ReviewGuide.cfc','administracao/geolocalizacao/includes/review_guide_view.cfm',
       'administracao/geolocalizacao/assets/review-guide.css','administracao/geolocalizacao/includes/backend.cfm',
       'administracao/geolocalizacao/includes/view.cfm','administracao/geolocalizacao/assets/geocoding.js',
       'administracao/geolocalizacao/index.cfm']
prior=json.loads((ROOT/'_codex/deploy/geocoding-review-20261022.json').read_text())
baseline={**prior['preserved_files'],**prior['candidate_hashes']}
before={name:None if name==FILES[0] else baseline[name] for name in FILES}
PRESERVED={name:value for name,value in baseline.items() if name not in FILES}
candidate={name:hashlib.sha256((ROOT/name).read_bytes()).hexdigest() for name in FILES}
verification=ROOT/'_codex/deploy/geocoding-review-edit-tests-20261022.json'
publish='--publish' in sys.argv;tests=[];reader_ok=False
if publish and '--verified' in sys.argv:
    proof=json.loads(verification.read_text())
    age=(datetime.datetime.now(datetime.timezone.utc)-datetime.datetime.fromisoformat(proof['checked_at'])).total_seconds()
    if age<0 or age>1800 or proof['candidate_hashes']!=candidate or len(proof['tests'])!=44 or not all(r.get('ok') and r.get('stage_archived') for r in proof['tests']) or not proof.get('reader_ok'):raise SystemExit('Fresh matching verification is required')
    tests=proof['tests'];reader_ok=True
elif publish or '--verify' in sys.argv:
    for suite in ['all','radar_view','radar_priority','radar_coverage','radar_contract']:
        run=subprocess.run([sys.executable,'-B',str(ROOT/'_codex/scripts/test_geocoding_native.py'),suite],capture_output=True,text=True,timeout=900)
        try:results=[json.loads(line) for line in run.stdout.splitlines() if line.strip()]
        except ValueError:raise SystemExit('Invalid native output: '+suite)
        tests.extend(results);ok=not run.returncode and results and all(r.get('ok') and r.get('stage_archived') for r in results)
        print(json.dumps({'suite':suite,'ok':bool(ok),'checks':len(results)}),flush=True)
        if not ok:print(run.stdout[-12000:]);print(run.stderr[-1000:]);raise SystemExit('Native verification failed')
    if len(tests)!=44:raise SystemExit('Unexpected verification coverage')
    run=subprocess.run([sys.executable,'-B','-m','unittest','discover','-s','_codex/tests/geocoding','-p','test_source_fetcher.py'],cwd=ROOT,capture_output=True,text=True,timeout=60)
    reader_ok=not run.returncode
    print(json.dumps({'reader_ok':reader_ok,'output':run.stderr[-1000:]}),flush=True)
    if not reader_ok:raise SystemExit('Reader verification failed')
    if candidate!={name:hashlib.sha256((ROOT/name).read_bytes()).hexdigest() for name in FILES}:raise SystemExit('Candidate changed during tests')
    node='/Users/geraldoprotta/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node'
    subprocess.run([node,'--check',str(ROOT/'administracao/geolocalizacao/assets/geocoding.js')],check=True)

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
anchor="if not all(check['ok'] for check in checks):raise RuntimeError('Final hash mismatch')"
guard=anchor+"""
 for rel,expected in preserved.items():
  if sha(target(rel).read_bytes())!=expected:raise RuntimeError('Concurrent preserved-file change: '+rel)"""
if remote.count(anchor)!=1:raise SystemExit('Final guard changed')
remote=remote.replace(anchor,guard,1)
anchor="('/services/geocoding/Sources.cfc','GET',403)"
extra="('/services/geocoding/ReviewInput.cfc','GET',403),('/services/geocoding/ReviewGuide.cfc','GET',403),('/administracao/geolocalizacao/includes/review_guide_view.cfm','GET',403),('/administracao/geolocalizacao/assets/review-guide.css','GET',200),"+anchor
if remote.count(anchor)!=1:raise SystemExit('HTTP probe list changed')
remote=remote.replace(anchor,extra,1)
payload={'publish':publish,'allowed':FILES,'preserved':PRESERVED,'files':[
    {'path':name,'before':before[name],'data':base64.b64encode((ROOT/name).read_bytes()).decode()} for name in FILES]}
run=subprocess.run(['ssh','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-o','ConnectTimeout=12','rr-prod','python3 -c '+shlex.quote(remote)],input=json.dumps(payload).encode(),capture_output=True,timeout=150)
try:result=json.loads(run.stdout)
except ValueError:print(json.dumps({'ok':False,'diagnostic':run.stderr.decode(errors='replace')[-800:]}));raise SystemExit(1)
if result.get('ok') and result.get('mode')=='published':
    result.update({'checked_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'native_tests':tests,'reader_ok':reader_ok,
                   'source_commit':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT).decode().strip(),
                   'candidate_hashes':candidate,'preserved_files':PRESERVED,'schema_changed':False,'credentials_changed':False,
                   'git_mutations':False,'transport_sha256':hashlib.sha256(transport.read_bytes()).hexdigest()})
    (ROOT/'_codex/deploy/geocoding-review-edit-20261022.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
elif result.get('ok') and tests:
    verification.write_text(json.dumps({'checked_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'candidate_hashes':candidate,'tests':tests,'reader_ok':reader_ok,'preflight':result},ensure_ascii=False,indent=2)+'\n')
print(json.dumps({k:v for k,v in result.items() if k!='native_tests'},ensure_ascii=False))
raise SystemExit(0 if not run.returncode and result.get('ok') else 1)
