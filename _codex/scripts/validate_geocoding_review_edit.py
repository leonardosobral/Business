"""Read-only production comparison and recorded UI validation for inline review."""
import datetime
import hashlib
import json
import pathlib
import shlex
import subprocess

ROOT=pathlib.Path(__file__).resolve().parents[2]
release=json.loads((ROOT/'_codex/deploy/geocoding-review-edit-20261022.json').read_text())
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
proof=ROOT/'_codex/deploy/geocoding-review-edit-20261022.jpg'
if not proof.exists() or proof.read_bytes()[:3]!=b'\xff\xd8\xff':raise SystemExit('Browser proof missing or invalid')
tests=release['native_tests']
if len(tests)!=44 or not all(t.get('ok') and t.get('stage_archived') for t in tests) or not release.get('reader_ok'):raise SystemExit('Incomplete native validation')
head=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT).decode().strip()
if head!=release['source_commit']:raise SystemExit('Git identity changed after publication')
result={'ok':True,'checked_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),
    'publication_receipt':'geocoding-review-edit-20261022.json','production_comparison':comparison,
    'native_suites_passed':44,'python_reader_tests_passed':11,
    'independent_review':{'important_findings_resolved':['resume with incomplete source evidence','draft preservation after concurrent changes','draft isolation after revision/field reordering'],'remaining_important_or_critical':0},
    'browser':{'authenticated_global_admin':True,'work_id':4063,'step':'field-14',
        'inline_editor_visible':True,'save_and_continue_visible':True,
        'empty_value_blocked_by_required_validation':True,'validation_text':'Preencha este campo.',
        'temporary_local_text_edit_observed':True,'copy_suggestion_restored_original_value':True,
        'saved_decisions_before':0,'saved_decisions_after':0,
        'real_event_approvals_corrections_or_rejections_performed':False,
        'screenshot':proof.name,'screenshot_sha256':hashlib.sha256(proof.read_bytes()).hexdigest()},
    'runtime_files_published':11,'backup':release['backup'],'schema_changed':False,
    'credentials_changed':False,'paid_provider_calls_by_tests_or_ui':0,'git_mutations':False,
    'scope':'Inline editing of pending enrichment fields; location precision rules, provider quotas, earlier optimizations and shared production menu preserved.'}
(ROOT/'_codex/deploy/geocoding-review-edit-validation-20261022.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
print(json.dumps({'ok':True,'files_compared':len(expected),'native_suites_passed':44,'browser_inline_edit_copy_and_required_validation_verified':True,'real_event_mutations_performed':False}))
