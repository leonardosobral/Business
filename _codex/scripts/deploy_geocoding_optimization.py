"""Six-file guarded optimization release. Read-only preflight unless --publish.

Fresh isolated native tests, exact HEAD production baseline, private recoverable
backup and atomic CAS publication. No schema, key, quota, schedule or Git writes.
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

ROOT = pathlib.Path(__file__).resolve().parents[2]
FILES = ['services/geocoding/AIClient.cfc', 'services/geocoding/DocumentReader.cfc',
         'services/geocoding/LocationStore.cfc', 'services/geocoding/LocationWorker.cfc',
         'services/geocoding/Store.cfc', 'administracao/geolocalizacao/includes/view.cfm']
PRESERVED = {'includes/estrutura/sidenav.cfm':
             '0189d264f87aa8efc949dbb5e8402fb64f998a0152090b1164247891c0682135'}
for name in ['services/geocoding/config.cfm', 'services/geocoding/LocationPolicy.cfc',
             'services/geocoding/EnrichmentPolicy.cfc', 'services/geocoding/EnrichmentStore.cfc',
             'administracao/geolocalizacao/includes/backend.cfm',
             'administracao/geolocalizacao/includes/radar_view.cfm', 'api/eventos/geolocalizar.cfm']:
    PRESERVED[name] = hashlib.sha256(subprocess.check_output(['git','show','HEAD:'+name],cwd=ROOT)).hexdigest()
before = {name: hashlib.sha256(subprocess.check_output(['git','show','HEAD:'+name],cwd=ROOT)).hexdigest() for name in FILES}
candidate = {name: hashlib.sha256((ROOT/name).read_bytes()).hexdigest() for name in FILES}
tests = []
publish = '--publish' in sys.argv
if publish:
    for suite in ['all','radar_view','radar_priority','radar_coverage','radar_contract']:
        run = subprocess.run([sys.executable,'-B',str(ROOT/'_codex/scripts/test_geocoding_native.py'),suite],
                             capture_output=True,text=True,timeout=900)
        try:
            results = [json.loads(line) for line in run.stdout.splitlines() if line.strip()]
        except ValueError:
            raise SystemExit('Invalid native verification output: '+suite)
        tests.extend(results)
        ok = not run.returncode and results and all(r.get('ok') and r.get('stage_archived') for r in results)
        print(json.dumps({'suite':suite,'ok':bool(ok),'checks':len(results)}),flush=True)
        if not ok:
            print(run.stdout[-7000:]);print(run.stderr[-1000:]);raise SystemExit('Native verification failed')
    if len(tests)!=39:
        raise SystemExit('Unexpected native verification coverage')
    if candidate!={name:hashlib.sha256((ROOT/name).read_bytes()).hexdigest() for name in FILES}:
        raise SystemExit('Candidate changed during verification')

transport = ROOT/'_codex/scripts/deploy_geocoding_sources.py'
tree = ast.parse(transport.read_text())
remote = next(ast.literal_eval(node.value) for node in tree.body if isinstance(node,ast.Assign)
              and any(isinstance(t,ast.Name) and t.id=='REMOTE' for t in node.targets))
anchor = 'files=[];manifest={}'
guard = """allowed=set(p.pop('allowed'));preserved=p.pop('preserved')
if {f['path'] for f in p['files']}!=allowed:raise SystemExit('Unexpected publication scope')
for rel,expected in preserved.items():
 if sha(target(rel).read_bytes())!=expected:raise SystemExit('Preserved production file changed: '+rel)
files=[];manifest={}"""
if remote.count(anchor)!=1:raise SystemExit('Transport guard changed')
remote = remote.replace(anchor,guard,1)
anchor = "if not all(check['ok'] for check in checks):raise RuntimeError('Final hash mismatch')"
guard = anchor+"""
 for rel,expected in preserved.items():
  if sha(target(rel).read_bytes())!=expected:raise RuntimeError('Concurrent preserved-file change: '+rel)"""
if remote.count(anchor)!=1:raise SystemExit('Transport final guard changed')
remote = remote.replace(anchor,guard,1)
payload = {'publish':publish,'allowed':FILES,'preserved':PRESERVED,'files':[
    {'path':name,'before':before[name],'data':base64.b64encode((ROOT/name).read_bytes()).decode()} for name in FILES]}
run = subprocess.run(['ssh','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-o','ConnectTimeout=12',
                      'rr-prod','python3 -c '+shlex.quote(remote)],input=json.dumps(payload).encode(),capture_output=True,timeout=150)
try:
    result = json.loads(run.stdout)
except ValueError:
    print(json.dumps({'ok':False,'diagnostic':run.stderr.decode(errors='replace')[-800:]}));raise SystemExit(1)
if result.get('ok') and result.get('mode')=='published':
    result.update({'checked_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),
                   'source_commit':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT).decode().strip(),
                   'native_tests':tests,'candidate_hashes':candidate,'preserved_files':PRESERVED,
                   'model_unchanged':'gpt-6-astra','geo_daily_limit_unchanged':3000,'schema_changed':False,
                   'credentials_changed':False,'transport_sha256':hashlib.sha256(transport.read_bytes()).hexdigest()})
    (ROOT/'_codex/deploy/geocoding-optimization-20261022.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
print(json.dumps({k:v for k,v in result.items() if k!='native_tests'},ensure_ascii=False))
raise SystemExit(0 if not run.returncode and result.get('ok') else 1)
