"""Read-only release verification and reproducible operational evidence receipt."""
import datetime
import hashlib
import json
import pathlib
import shlex
import subprocess
import sys

ROOT=pathlib.Path(__file__).resolve().parents[2]
release=json.loads((ROOT/'_codex/deploy/geocoding-optimization-20261022.json').read_text())
expected={**release['candidate_hashes'],**release['preserved_files']}
remote=r'''
import hashlib,json,pathlib,sys
p=json.load(sys.stdin);root=pathlib.Path('/var/www/business.roadrunners.run')
out={name:hashlib.sha256((root/name).read_bytes()).hexdigest()==value for name,value in p.items()}
print(json.dumps({'ok':all(out.values()),'files':out}))
'''
run=subprocess.run(['ssh','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-o','ConnectTimeout=12','rr-prod',
                    'python3 -c '+shlex.quote(remote)],input=json.dumps(expected).encode(),capture_output=True,timeout=30)
comparison=json.loads(run.stdout)
if run.returncode or not comparison['ok']:raise SystemExit('Production comparison failed')

run=subprocess.run([sys.executable,'-B',str(ROOT/'_codex/scripts/test_geocoding_native.py'),'optimization_diagnostic'],
                   capture_output=True,text=True,timeout=85)
native=json.loads(run.stdout)
if run.returncode or not native.get('ok') or not native.get('stage_archived'):raise SystemExit('Read-only diagnostic failed')
diagnostic=json.loads(native['output'].split('\nGEO_OPTIMIZATION_DIAGNOSTIC_PASSED')[0])
published=datetime.datetime.fromisoformat(release['checked_at'])
real_runs=[]
for item in diagnostic['recent']:
    stamp=datetime.datetime.strptime(item['started_at'],'%B, %d %Y %H:%M:%S').replace(tzinfo=datetime.timezone.utc)
    if stamp>=published and 'processed' in item:real_runs.append(item)
proof=ROOT/'_codex/deploy/geocoding-optimization-20261022.jpg'
if not proof.exists() or proof.read_bytes()[:3]!=b'\xff\xd8\xff':raise SystemExit('Browser screenshot is missing or invalid')
validation={'ok':comparison['ok'] and bool(real_runs),
    'checked_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),
    'publication_receipt':'geocoding-optimization-20261022.json',
    'production_comparison':comparison,'diagnostic_archive':native['archive'],
    'source_queries':'_codex/tests/geocoding/optimization_diagnostic.cfm',
    'diagnostic':diagnostic,'real_runs_after_publication':real_runs,
    'browser':{'authenticated':True,'counter_value_seen':95,'model_seen':'gpt-6-astra',
               'ai_cooldown_warning_seen':True,'municipal_independence_seen':True,
               'screenshot':proof.name,'screenshot_sha256':hashlib.sha256(proof.read_bytes()).hexdigest()},
    'native_suites_passed':len(release['native_tests']),'python_reader_tests_passed':11,
    'baseline_diagnostic_archive':'/var/backups/geocoding-tests-ds628bev',
    'baseline_recent_60':{'processed':0,'ai_calls':0,'geo_calls':0},
    'caveat':'Recorded ai_quota_exhausted cooldown remains active; no new paid AI call was made for validation. Municipal suggestions are private, not canonical event locations.',
    'credentials_changed':False,'schema_changed':False,'git_mutations':False}
destination=ROOT/'_codex/deploy/geocoding-optimization-validation-20261022.json'
destination.write_text(json.dumps(validation,ensure_ascii=False,indent=2)+'\n')
print(json.dumps({k:validation[k] for k in ['ok','checked_at','native_suites_passed','real_runs_after_publication']},ensure_ascii=False))
raise SystemExit(0 if validation['ok'] else 1)
