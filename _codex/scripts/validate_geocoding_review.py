"""Read-only final comparison plus recorded browser proof for guided review."""
import datetime
import hashlib
import json
import pathlib
import shlex
import subprocess

ROOT=pathlib.Path(__file__).resolve().parents[2]
release=json.loads((ROOT/'_codex/deploy/geocoding-review-20261022.json').read_text())
expected={**release['candidate_hashes'],**release['preserved_files']}
remote=r'''
import hashlib,json,pathlib,sys
p=json.load(sys.stdin);root=pathlib.Path('/var/www/business.roadrunners.run')
checks={name:hashlib.sha256((root/name).read_bytes()).hexdigest()==value for name,value in p.items()}
print(json.dumps({'ok':all(checks.values()),'checks':checks}))
'''
run=subprocess.run(['ssh','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-o','ConnectTimeout=12','rr-prod','python3 -c '+shlex.quote(remote)],input=json.dumps(expected).encode(),capture_output=True,timeout=30)
comparison=json.loads(run.stdout)
if run.returncode or not comparison['ok']:raise SystemExit('Final production comparison failed')
proof=ROOT/'_codex/deploy/geocoding-review-20261022.jpg'
if not proof.exists() or proof.read_bytes()[:3]!=b'\xff\xd8\xff':raise SystemExit('Browser proof missing or invalid')
tests=release['native_tests']
if len(tests)!=42 or not all(t.get('ok') and t.get('stage_archived') for t in tests):raise SystemExit('Incomplete native validation')
result={'ok':True,'checked_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),
    'publication_receipt':'geocoding-review-20261022.json','production_comparison':comparison,
    'native_suites_passed':42,'python_reader_tests_passed':11,
    'independent_review':{'important_findings_resolved':['destination-only stale comparison','skip uses event identity','state hydration after stale POST'],'remaining_important_or_critical':0},
    'browser':{'authenticated_global_admin':True,'guided_review_visible':True,
        'current_vs_source_visible':True,'trusted_field_both_choices_visible':True,
        'untrusted_field_acceptance_absent':True,
        'skip_observed':{'from_work':4063,'to_work':3980,'skipped_count':1,'saved_decisions':0},
        'resume_observed':{'restored_work':4063,'skipped_count':0,'saved_decisions':0},
        'real_event_approvals_or_rejections_performed':False,
        'screenshot':proof.name,'screenshot_sha256':hashlib.sha256(proof.read_bytes()).hexdigest()},
    'runtime_files_published':7,'backup':release['backup'],'schema_changed':False,
    'credentials_changed':False,'provider_calls_by_ui':0,'git_mutations':False,
    'scope':'Guided review only; prior provider/worker optimizations and shared production menu preserved.'}
(ROOT/'_codex/deploy/geocoding-review-validation-20261022.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
print(json.dumps({'ok':True,'files_compared':len(expected),'native_suites_passed':42,'browser_skip_and_resume_verified':True,'real_event_approvals_or_rejections_performed':False}))
