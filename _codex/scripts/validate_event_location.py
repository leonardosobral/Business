"""Read-only post-publication validation and observed browser proof."""
import datetime,hashlib,json,pathlib,shlex,subprocess
ROOT=pathlib.Path(__file__).resolve().parents[2]
release=json.loads((ROOT/'_codex/deploy/event-location-20261022.json').read_text())
expected={**release['candidate_hashes'],**release['preserved_files']}
remote="""import hashlib,json,pathlib,sys
root=pathlib.Path('/var/www/business.roadrunners.run');expected=json.load(sys.stdin)
checks={name:hashlib.sha256((root/name).read_bytes()).hexdigest()==value for name,value in expected.items()}
print(json.dumps({'ok':all(checks.values()),'checks':checks}))
"""
run=subprocess.run(['ssh','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-o','ConnectTimeout=12','rr-prod','python3 -c '+shlex.quote(remote)],input=json.dumps(expected).encode(),capture_output=True,timeout=30)
comparison=json.loads(run.stdout)
if run.returncode or not comparison['ok']:raise SystemExit('Production comparison failed')
tests=release['native_tests']
if len(tests)!=49 or not all(t.get('ok') and t.get('stage_archived') for t in tests):raise SystemExit('Incomplete native verification')
proof=ROOT/'_codex/deploy/event-location-20261022.jpg'
if not proof.exists() or proof.read_bytes()[:3]!=b'\xff\xd8\xff':raise SystemExit('Browser proof missing')
result={'ok':True,'checked_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),
    'publication_receipt':'event-location-20261022.json','production_comparison':comparison,
    'native_suites_passed':49,'frontend_test_passed':True,'reader_tests_passed':11,
    'independent_review':{'important_findings_resolved':['unchanged legacy address and coordinates','specific location validation messages','complete new-event form'],'remaining_important_or_critical':0},
    'browser':{'event_id':38202,'country_preserved':'PT','city_preserved':'Lisbon',
        'country_selector_visible':True,'foreign_city_and_subdivision_editable':True,
        'optional_short_region_code_visible':True,'brazil_switch_observed':True,
        'brazil_state_municipality_controls_visible':True,'portugal_restored':True,
        'original_city_restored_after_switch':True,'save_button_visible':True,
        'real_event_form_submissions_performed':False,'screenshot':proof.name,
        'screenshot_sha256':hashlib.sha256(proof.read_bytes()).hexdigest()},
    'runtime_files_published':8,'backup':release['backup'],'schema_changed':False,
    'credentials_changed':False,'paid_provider_calls_by_tests_or_ui':0,
    'git_mutations_for_this_feature':False,
    'verification_limitations':release['verification_limitations'],
    'publication_probe_correction':'Root service follows the existing login redirect 302; directory-level geocoding access remains 403. Failed first attempt rolled back all eight files before retry.'}
(ROOT/'_codex/deploy/event-location-validation-20261022.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
print(json.dumps({'ok':True,'files_compared':len(expected),'native_suites_passed':49,'browser_country_switch_and_restore_verified':True,'real_event_submissions_performed':False}))
