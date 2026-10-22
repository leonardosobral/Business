"""Publish only the four verified pending Radar files, never the shared menu.

Default: read-only preflight. --publish requires fresh isolated native checks.
No SQL migration, credentials, permissions, Git write, or restart is performed.
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
FILES = [
    'services/geocoding/LocationStore.cfc',
    'administracao/geolocalizacao/includes/radar_view.cfm',
    'administracao/geolocalizacao/includes/backend.cfm',
    'administracao/geolocalizacao/includes/view.cfm',
]
PRESERVED = {'includes/estrutura/sidenav.cfm':
             '0189d264f87aa8efc949dbb5e8402fb64f998a0152090b1164247891c0682135'}
baseline = {}
for receipt in ['geocoding-enrichment-20261019.json', 'geocoding-quota-3000-20261019.json']:
    baseline.update(json.loads((ROOT / '_codex/deploy' / receipt).read_text())['manifest'])
before = {name: baseline.get(name, {}).get('after') for name in FILES}
candidate_hashes = {name: hashlib.sha256((ROOT / name).read_bytes()).hexdigest() for name in FILES}
publish = '--publish' in sys.argv
tests = {}
if publish:
    for suite in ['radar_view', 'radar_priority', 'radar_coverage', 'radar_contract', 'access']:
        run = subprocess.run([sys.executable, '-B', str(ROOT / '_codex/scripts/test_geocoding_native.py'), suite],
                             capture_output=True, text=True, timeout=85)
        try:
            evidence = json.loads(run.stdout)
        except ValueError:
            raise SystemExit('Native test output unavailable: ' + suite)
        tests[suite] = evidence
        print(json.dumps({'suite': suite, 'ok': evidence.get('ok', False)}), flush=True)
        if run.returncode or not evidence.get('ok') or not evidence.get('stage_archived'):
            print(json.dumps(evidence, ensure_ascii=False))
            raise SystemExit('Publication stopped by failed native verification: ' + suite)
    if candidate_hashes != {name: hashlib.sha256((ROOT / name).read_bytes()).hexdigest() for name in FILES}:
        raise SystemExit('Candidate changed during native verification')

# Reuse the existing atomic replacement, backup, guarded rollback, and HTTP checks.
transport_path = ROOT / '_codex/scripts/deploy_geocoding_sources.py'
tree = ast.parse(transport_path.read_text())
remote = next(ast.literal_eval(node.value) for node in tree.body if isinstance(node, ast.Assign)
              and any(isinstance(target, ast.Name) and target.id == 'REMOTE' for target in node.targets))
anchor = "files=[];manifest={}"
guard = """allowed=set(p.pop('allowed'));preserved=p.pop('preserved')
if {item['path'] for item in p['files']}!=allowed:raise SystemExit('Unexpected publication scope')
for rel,expected in preserved.items():
 if sha(target(rel).read_bytes())!=expected:raise SystemExit('Preserved production file changed: '+rel)
files=[];manifest={}"""
if remote.count(anchor) != 1:
    raise SystemExit('Publication transport anchor changed')
remote = remote.replace(anchor, guard, 1)
anchor = "if not all(check['ok'] for check in checks):raise RuntimeError('Final hash mismatch')"
guard = anchor + """
 for rel,expected in preserved.items():
  if sha(target(rel).read_bytes())!=expected:raise RuntimeError('Concurrent change in preserved file: '+rel)"""
if remote.count(anchor) != 1:
    raise SystemExit('Publication verification anchor changed')
remote = remote.replace(anchor, guard, 1)
payload = {'publish': publish, 'allowed': FILES, 'preserved': PRESERVED, 'files': [
    {'path': name, 'before': before[name], 'data': base64.b64encode((ROOT / name).read_bytes()).decode()}
    for name in FILES]}
run = subprocess.run(['ssh', '-o', 'BatchMode=yes', '-o', 'StrictHostKeyChecking=yes',
                      '-o', 'ConnectTimeout=12', 'rr-prod', 'python3 -c ' + shlex.quote(remote)],
                     input=json.dumps(payload).encode(), capture_output=True, timeout=150)
try:
    result = json.loads(run.stdout)
except ValueError:
    print(json.dumps({'ok': False, 'error': 'Publication transport returned no valid receipt',
                      'diagnostic': run.stderr.decode(errors='replace')[-500:]}))
    raise SystemExit(1)
if result.get('ok') and result.get('mode') == 'published':
    result.update({'checked_at': datetime.datetime.now(datetime.timezone.utc).isoformat(),
                   'source_commit': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT).decode().strip(),
                   'candidate_hashes': candidate_hashes, 'preserved_files': PRESERVED,
                   'native_tests': tests, 'schema_changed': False, 'credentials_changed': False,
                   'transport_sha256': hashlib.sha256(transport_path.read_bytes()).hexdigest()})
    receipt = ROOT / '_codex/deploy/pending-radar-20261022.json'
    receipt.write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n')
print(json.dumps(result, ensure_ascii=False))
raise SystemExit(0 if run.returncode == 0 and result.get('ok') else 1)
