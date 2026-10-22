"""Publish only the approved guided-review UI and its read-only queue adapter.

Default is read-only preflight. --publish requires fresh full native checks.
Preserve prior geolocation optimizations, provider policies and the shared menu.
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
FILES=['services/geocoding/ReviewGuide.cfc',
       'administracao/geolocalizacao/includes/review_guide_view.cfm',
       'administracao/geolocalizacao/assets/review-guide.css',
       'administracao/geolocalizacao/includes/backend.cfm',
       'administracao/geolocalizacao/includes/view.cfm',
       'administracao/geolocalizacao/assets/geocoding.js',
       'administracao/geolocalizacao/index.cfm']
NEW=set(FILES[:3])
prior=json.loads((ROOT/'_codex/deploy/geocoding-optimization-20261022.json').read_text())
PRESERVED={name:value for name,value in {**prior['preserved_files'],**prior['candidate_hashes']}.items() if name not in FILES}
before={}
for name in FILES:
    before[name]=None if name in NEW else prior['candidate_hashes'].get(name) or hashlib.sha256(subprocess.check_output(['git','show','HEAD:'+name],cwd=ROOT)).hexdigest()
candidate={name:hashlib.sha256((ROOT/name).read_bytes()).hexdigest() for name in FILES}
publish='--publish' in sys.argv;tests=[];verification=ROOT/'_codex/deploy/geocoding-review-tests-20261022.json'
if publish and '--verified' in sys.argv:
    proof=json.loads(verification.read_text())
    age=(datetime.datetime.now(datetime.timezone.utc)-datetime.datetime.fromisoformat(proof['checked_at'])).total_seconds()
    if age<0 or age>1800 or proof['candidate_hashes']!=candidate or len(proof['tests'])!=42 or not all(r.get('ok') and r.get('stage_archived') for r in proof['tests']):raise SystemExit('Fresh matching verification is required')
    tests=proof['tests']
elif publish or '--verify' in sys.argv:
    for suite in ['all','radar_view','radar_priority','radar_coverage','radar_contract']:
        run=subprocess.run([sys.executable,'-B',str(ROOT/'_codex/scripts/test_geocoding_native.py'),suite],capture_output=True,text=True,timeout=900)
        try:results=[json.loads(line) for line in run.stdout.splitlines() if line.strip()]
        except ValueError:raise SystemExit('Invalid native output: '+suite)
        tests.extend(results);ok=not run.returncode and results and all(r.get('ok') and r.get('stage_archived') for r in results)
        print(json.dumps({'suite':suite,'ok':bool(ok),'checks':len(results)}),flush=True)
        if not ok:print(run.stdout[-7000:]);print(run.stderr[-1000:]);raise SystemExit('Native verification failed')
    if len(tests)!=42:raise SystemExit('Unexpected verification coverage')
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
extra="('/services/geocoding/ReviewGuide.cfc','GET',403),('/administracao/geolocalizacao/includes/review_guide_view.cfm','GET',403),('/administracao/geolocalizacao/assets/review-guide.css','GET',200),"+anchor
if remote.count(anchor)!=1:raise SystemExit('HTTP probe list changed')
remote=remote.replace(anchor,extra,1)
payload={'publish':publish,'allowed':FILES,'preserved':PRESERVED,'files':[
    {'path':name,'before':before[name],'data':base64.b64encode((ROOT/name).read_bytes()).decode()} for name in FILES]}
run=subprocess.run(['ssh','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-o','ConnectTimeout=12','rr-prod','python3 -c '+shlex.quote(remote)],input=json.dumps(payload).encode(),capture_output=True,timeout=150)
try:result=json.loads(run.stdout)
except ValueError:print(json.dumps({'ok':False,'diagnostic':run.stderr.decode(errors='replace')[-800:]}));raise SystemExit(1)
if result.get('ok') and result.get('mode')=='published':
    result.update({'checked_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'native_tests':tests,
                   'source_commit':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT).decode().strip(),
                   'candidate_hashes':candidate,'preserved_files':PRESERVED,'schema_changed':False,'credentials_changed':False,
                   'git_mutations':False,'transport_sha256':hashlib.sha256(transport.read_bytes()).hexdigest()})
    (ROOT/'_codex/deploy/geocoding-review-20261022.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
elif result.get('ok') and tests:
    verification.write_text(json.dumps({'checked_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'candidate_hashes':candidate,'tests':tests,'preflight':result},ensure_ascii=False,indent=2)+'\n')
print(json.dumps({k:v for k,v in result.items() if k!='native_tests'},ensure_ascii=False))
raise SystemExit(0 if not run.returncode and result.get('ok') else 1)
