"""Scoped CRM release: hash baseline, recoverable backup, native compilation, no sends."""
from pathlib import Path
import hashlib, io, json, os, re, shlex, subprocess, sys, tarfile
ROOT=Path(__file__).resolve().parents[2]
HELPER_SOURCE=(Path(__file__).with_name('crm_deploy_state.py')).read_text()
LEDGER=ROOT/'.superpowers/sdd/2026-09-24-crm-interno'
scope=sys.argv[2] if len(sys.argv)>2 else 'all'
assert scope in ('all','business','business-history','r6','program-panel','program-finance-road','program-finance-business','program-history-road','program-history-business','program-history-ui','program-analysis-road','program-analysis-business','program-purchases-road','program-purchases-business','campaign-modal','program-modal','planning-gantt','planning-compact')
receipt_prefix={'all':'release','business':'release-business','business-history':'release-business-history','r6':'release-r6','program-panel':'release-program-panel','program-finance-road':'release-program-finance-road','program-finance-business':'release-program-finance-business','program-history-road':'release-program-history-road','program-history-business':'release-program-history-business','program-history-ui':'release-program-history-ui','program-analysis-road':'release-program-analysis-road','program-analysis-business':'release-program-analysis-business','program-purchases-road':'release-program-purchases-road','program-purchases-business':'release-program-purchases-business','campaign-modal':'release-campaign-modal','program-modal':'release-program-modal','planning-gantt':'release-planning-gantt','planning-compact':'release-planning-compact'}[scope]
RECEIPT=LEDGER/(receipt_prefix+'.json')
SSH=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
SITES={'Business':'/var/www/business.roadrunners.run','RoadRunners':'/var/www/roadrunners.com.br'}
SHARED={'Business':[],'RoadRunners':[]}
BASELINE_FALLBACK={('RoadRunners','api/crm-interno/_common.cfm'):'8f1744c1998ea85206aa1ca58f11659cc9c2a6b21f5e09e23125c6736cbe617c',('RoadRunners','api/crm-interno/worker.cfm'):'b43a5660a15fdbae373aaa8d85425ce3d5aa2769862f9dc28cb5f2cdd459d70f',('RoadRunners','carteira/parts/transacao_cc.cfm'):'c4fb3f4fb73b037727ee960f8a00f5493c7a10f67a26f79efab70e199029a571',('RoadRunners','carteira/parts/transacao_pix.cfm'):'c6e465d9352a0f24757ae7a70612fcf06e22dabd38da95317f128a02a0384a21',('RoadRunners','services/crm/CrmCampaignService.cfc'):'e7f66efd024584c5f2618bb3573a14e5ce55ab8e3ee8c496016644aff5f64c71',('RoadRunners','services/crm/CrmTrackingService.cfc'):'34e4fae11a7b6cc5b32987fef688d24ce925b399a46135240cd6a4ccaa225245',('RoadRunners','includes/backend/backend_perfil_edicao.cfm'):'622f6f169eeac3359bd4a137f69d5e4c6a4b5e3b6d436fdd037c52ffc2ff4cd7',('Business','crm-interno/index.cfm'):'2c6e3d1edca2078e2151c79363ac0f433f9ad9561365a3f895d8669e9cdea964',('Business','crm-interno/crm.js'):'37018b4c3a88b90dfd042116125eee5c45cf3eed1a65251f5ea629e5d72772ee'}
FILES={
 'Business':['crm-interno/index.cfm','crm-interno/crm.css','crm-interno/crm.js','crm-interno/crm-profile.js','crm-interno/crm-opportunities.js','crm-interno/crm-recommendations.js','crm-interno/crm-audience-history.js','crm-interno/crm-calendar.js','api/crm-interno-history.cfm'],
 'RoadRunners':['services/crm/CrmEligibilityService.cfc','services/crm/CrmPreferenceService.cfc','services/crm/CrmCampaignService.cfc','services/crm/CrmDeliveryService.cfc','services/crm/CrmAdminService.cfc','services/crm/CrmDataQualityService.cfc','services/crm/CrmProfileService.cfc','services/crm/CrmOpportunityService.cfc','services/crm/CrmRecommendationService.cfc','services/crm/CrmAudienceHistoryService.cfc','services/crm/CrmPlanningService.cfc','api/crm-interno/_common.cfm','api/crm-interno/worker.cfm'],
}
GUARDS={'Business':['Application.cfc','includes/backend/backend_login.cfm','includes/backend/require_admin_dev.cfm','includes/backend/require_real_platform_context.cfm','emailmkt/EmailSenderService.cfc'], 'RoadRunners':['Application.cfc','includes/backend/backend_notifications.cfm','api/notifications/integrations/dispatch.cfm','includes/analytics/bootstrap.cfm']}
if scope=='business':
 FILES={'Business':['crm-interno/index.cfm','crm-interno/crm.css','crm-interno/crm.js','crm-interno/crm-opportunities.js']}
 GUARDS={'Business':GUARDS['Business']}
 SITES={'Business':SITES['Business']}
if scope=='business-history':
 FILES={'Business':['crm-interno/index.cfm','crm-interno/crm.js','crm-interno/crm-audience-history.js']}
 GUARDS={'Business':GUARDS['Business']}
 SITES={'Business':SITES['Business']}
if scope=='r6':
 FILES={'RoadRunners':['services/crm/CrmChallengeSignupService.cfc','services/crm/CrmCampaignService.cfc','services/crm/CrmTrackingService.cfc','includes/backend/backend_perfil_edicao.cfm'],
        'Business':['crm-interno/index.cfm','crm-interno/crm.js']}
if scope=='program-panel':
 FILES={'RoadRunners':['services/crm/CrmProgramService.cfc','services/crm/CrmAdminService.cfc'],
        'Business':['crm-interno/index.cfm','crm-interno/crm.js','crm-interno/crm.css','crm-interno/crm-program.js']}
if scope=='program-finance-road':
 FILES={'RoadRunners':['services/crm/CrmCheckoutIdentityService.cfc','services/crm/CrmPagarmeSnapshotService.cfc','services/crm/CrmPagarmeReconciliationService.cfc','services/crm/CrmConversionService.cfc','services/crm/CrmProgramFinanceService.cfc','services/crm/CrmProgramService.cfc','services/crm/CrmAdminService.cfc','api/crm-interno/worker.cfm','carteira/parts/transacao_cc.cfm','carteira/parts/transacao_pix.cfm']}
 GUARDS={'RoadRunners':GUARDS['RoadRunners']}
 SITES={'RoadRunners':SITES['RoadRunners']}
if scope=='program-finance-business':
 FILES={'Business':['services/CrmCommerceService.cfc','api/crm-interno-commerce.cfm','crm-interno/index.cfm','crm-interno/crm.js','crm-interno/crm.css','crm-interno/crm-program.js']}
 GUARDS={'Business':GUARDS['Business']}
 SITES={'Business':SITES['Business']}
if scope=='program-history-road':
 FILES={'RoadRunners':['services/crm/CrmPagarmeBackfillService.cfc','services/crm/CrmPagarmeSnapshotService.cfc','services/crm/CrmProgramFinanceService.cfc','api/crm-interno/worker.cfm']}
 GUARDS={'RoadRunners':GUARDS['RoadRunners']}
 SITES={'RoadRunners':SITES['RoadRunners']}
if scope=='program-history-business':
 FILES={'Business':['services/CrmCommerceService.cfc','api/crm-interno-commerce.cfm','crm-interno/index.cfm','crm-interno/crm.js','crm-interno/crm-program.js']}
 GUARDS={'Business':GUARDS['Business']}
 SITES={'Business':SITES['Business']}
if scope=='program-history-ui':
 FILES={'Business':['crm-interno/index.cfm','crm-interno/crm.js','crm-interno/crm-program.js']}
 GUARDS={'Business':GUARDS['Business']}
 SITES={'Business':SITES['Business']}
if scope=='program-analysis-road':
 FILES={'RoadRunners':['services/crm/CrmProgramService.cfc','services/crm/CrmProgramFinanceService.cfc']}
 GUARDS={'RoadRunners':GUARDS['RoadRunners']}
 SITES={'RoadRunners':SITES['RoadRunners']}
if scope=='program-analysis-business':
 FILES={'Business':['crm-interno/index.cfm','crm-interno/crm.js','crm-interno/crm.css','crm-interno/crm-program.js']}
 GUARDS={'Business':GUARDS['Business']}
 SITES={'Business':SITES['Business']}
if scope=='program-purchases-road':
 FILES={'RoadRunners':['services/crm/CrmProgramFinanceService.cfc','services/crm/CrmProgramService.cfc','services/crm/CrmAdminService.cfc']}
 GUARDS={'RoadRunners':GUARDS['RoadRunners']}
 SITES={'RoadRunners':SITES['RoadRunners']}
if scope=='program-purchases-business':
 FILES={'Business':['crm-interno/index.cfm','crm-interno/crm.js','crm-interno/crm.css','crm-interno/crm-program.js']}
 GUARDS={'Business':GUARDS['Business']}
 SITES={'Business':SITES['Business']}
if scope=='campaign-modal':
 FILES={'Business':['crm-interno/index.cfm','crm-interno/crm.js','crm-interno/crm.css']}
 GUARDS={'Business':GUARDS['Business']}
 SITES={'Business':SITES['Business']}
if scope=='program-modal':
 FILES={'Business':['crm-interno/index.cfm','crm-interno/crm.js','crm-interno/crm.css','crm-interno/crm-program.js']}
 GUARDS={'Business':GUARDS['Business']}
 SITES={'Business':SITES['Business']}
if scope=='planning-gantt':
 FILES={'Business':['crm-interno/index.cfm','crm-interno/crm.js','crm-interno/crm.css','crm-interno/crm-calendar.js','crm-interno/crm-gantt.js','crm-interno/timeline.cfm']}
 GUARDS={'Business':GUARDS['Business']}
 SITES={'Business':SITES['Business']}
if scope=='planning-compact':
 FILES={'Business':['crm-interno/index.cfm','crm-interno/crm.js','crm-interno/crm.css','crm-interno/crm-calendar.js','crm-interno/crm-gantt.js']}
 GUARDS={'Business':GUARDS['Business']}
 SITES={'Business':SITES['Business']}
sha=lambda b:hashlib.sha256(b).hexdigest()
mode=sys.argv[1];assert mode in ['prepare','publish','verify','rollback']
if scope=='r6' and mode=='publish':
 migration=ROOT.parent/'RoadRunners/_codex/sql/migrations/2026-09-25_crm_challenge_signup.sql'
 receipt=ROOT/'.superpowers/sdd/2026-09-24-crm-interno-evolucao/r6-database-verify.json'
 if not receipt.exists():raise SystemExit('R6 database verification receipt is required before publishing runtime')
 checked=json.loads(receipt.read_text())
 if checked.get('checksum')!=sha(migration.read_bytes()) or not all(checked.get(key) for key in ('applied','source','events','index','started')):
  raise SystemExit('R6 database migration is not verified for this candidate')
if scope in ('program-finance-road','program-finance-business','program-history-road','program-history-business','program-history-ui','program-analysis-road','program-analysis-business','program-purchases-road','program-purchases-business') and mode=='publish':
 receipt=ROOT/'.superpowers/sdd/2026-09-25-crm-todo-santo-dia-continuo/program-database-verify.json'
 migrations=[ROOT.parent/'RoadRunners/_codex/sql/migrations'/f'{name}.sql' for name in ('2026-09-25_crm_checkout_identity','2026-09-25_crm_conversion_ledger','2026-09-25_crm_tsd_program')]
 if not receipt.exists():raise SystemExit('Program database verification receipt is required before publishing finance runtime')
 checked=json.loads(receipt.read_text())
 if checked.get('hashes')!=[sha(path.read_bytes()) for path in migrations] or not all(checked.get('tables',{}).values()) or not all(item.get('matches') for item in checked.get('markers',[])) or len(checked.get('markers',[]))!=3:
  raise SystemExit('Program database migration is not verified for this candidate')
files={};manifest=[];previous_files={}
if mode=='prepare':
 for report_path in sorted(LEDGER.glob('release*-publish.json'),key=lambda path:path.stat().st_mtime_ns):
  published=json.loads(report_path.read_text())
  prior_dir=published['directory'];assert re.fullmatch(r'/var/backups/crm-interno\.[a-f0-9]+',prior_dir)
  prior=json.loads(subprocess.check_output(SSH+['cat '+shlex.quote(prior_dir+'/state.json')]))
  assert prior['phase']=='published'
  previous_files.update({(row['site'],row['path']):row['after'] for row in prior['files']})
  (LEDGER/('previous-'+Path(prior_dir).name+'.json')).write_text(json.dumps(prior,indent=2)+'\n')
if mode=='prepare':
 for site,names in FILES.items():
  repo=ROOT if site=='Business' else ROOT.parent/site
  for name in names:
   content=(repo/name).read_bytes();before=None
   if name in SHARED[site]: before=sha(subprocess.check_output(['git','-C',str(repo),'show','HEAD:'+name]))
   if (site,name) in previous_files:before=previous_files[(site,name)]
   if before is None and (site,name) in BASELINE_FALLBACK:before=BASELINE_FALLBACK[(site,name)]
   files['candidate/'+site+'/'+name]=content
   manifest.append({'site':site,'path':name,'before':before,'after':sha(content)})
 files['manifest.json']=json.dumps(manifest).encode()
 buffer=io.BytesIO()
 with tarfile.open(fileobj=buffer,mode='w') as archive:
  for name,content in files.items():
   item=tarfile.TarInfo(name);item.size=len(content);item.mode=0o600;archive.addfile(item,io.BytesIO(content))
 payload=buffer.getvalue()
 init=f'''
release=Path('/var/backups')/('crm-interno.'+secrets.token_hex(8));release.mkdir(mode=0o700)
allowed=set({list(files)!r})
with tarfile.open(fileobj=io.BytesIO(sys.stdin.buffer.read()),mode='r:') as archive:
 members=archive.getmembers();assert len(members)==len(allowed) and set(m.name for m in members)==allowed
 for m in members:
  assert m.isfile() and '..' not in Path(m.name).parts and not m.name.startswith('/')
  p=release/m.name;p.parent.mkdir(parents=True,exist_ok=True,mode=0o700);p.write_bytes(archive.extractfile(m).read());os.chmod(p,0o600)
'''
else:
 previous=json.loads(RECEIPT.read_text());remote=previous['directory'];assert re.fullmatch(r'/var/backups/crm-interno\.[a-f0-9]+',remote)
 init=f'release=Path({remote!r})\n';payload=b''
script='''from pathlib import Path
import hashlib,io,json,os,re,secrets,shutil,subprocess,sys,tarfile,tempfile
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest() if p.is_file() else None
'''+HELPER_SOURCE+'\n'+init+f'''
roots={{k:Path(v) for k,v in {SITES!r}.items()}}
mode={mode!r}
manifest=json.loads((release/'manifest.json').read_text())
statepath=release/'state.json'
if mode=='prepare':
 guards=[]
 for site,names in {GUARDS!r}.items():
  for name in names: guards.append({{'site':site,'path':name,'hash':sha(roots[site]/name)}})
 for row in manifest:
  target=roots[row['site']]/row['path'];assert not target.is_symlink()
  assert sha(target)==row['before'],'PRODUCTION BASELINE CONFLICT: '+row['site']+'/'+row['path']
  if row['before']:
   st=target.stat();row['metadata']={{'uid':st.st_uid,'gid':st.st_gid,'mode':st.st_mode & 0o777,'mtime':st.st_mtime_ns}}
   backup=release/'before'/row['site']/row['path'];backup.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(target,backup);assert sha(backup)==row['before']
  else:
   st=roots[row['site']].stat();row['metadata']={{'uid':st.st_uid,'gid':st.st_gid,'mode':0o644}}
 state={{'phase':'prepared','files':manifest,'guards':guards,'compiled':False}}
 statepath.write_text(json.dumps(state,indent=2))
 stage=Path(tempfile.mkdtemp(prefix='crm-compile-',dir='/tmp'));source=stage/'source';compiled=stage/'compiled';compiled.mkdir();expected=0
 for p in (release/'candidate').rglob('*'):
  if p.suffix.lower() not in ('.cfm','.cfc'):continue
  dst=source/p.relative_to(release/'candidate');dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,dst);expected+=1
 for p in [stage,*stage.rglob('*')]:os.chown(p,65534,65534);os.chmod(p,0o755 if p.is_dir() else 0o644)
 run=subprocess.run(['/opt/ColdFusion/cfusion/bin/cfcompile.sh','-deploy','-cfruntimeuser','nobody','-webroot',str(source),'-dir',str(source),'-deploydir',str(compiled)],capture_output=True,text=True,timeout=180)
 log=run.stdout+run.stderr;(release/'compile.log').write_text(log);shutil.move(str(stage),str(release/'compile-artifacts'))
 state['compile_expected']=expected
 state['compiled']=run.returncode==0 and bool(re.search(r'successful\\s+'+str(expected)+r'\\b',log)) and bool(re.search(r'total\\s+'+str(expected)+r'\\b',log))
 statepath.write_text(json.dumps(state,indent=2))
 print(json.dumps({{'directory':str(release),'phase':state['phase'],'compiled':state['compiled'],'count':expected,'compile_log':str(release/'compile.log'),'errors':log[-8000:] if not state['compiled'] else ''}}))
else:
 state=json.loads(statepath.read_text());assert state['compiled'],'Native compilation failed'
 for row in state['guards']:assert sha(roots[row['site']]/row['path'])==row['hash'],'DEPENDENCY CHANGED: '+row['path']
 if mode in ('publish','rollback'):apply_transition(mode,state,statepath,release,roots,sha)
 else:
  assert state['phase']=='published','RELEASE NOT PUBLISHED'
  for row in state['files']:
   target=roots[row['site']]/row['path']
   assert not target.is_symlink() and sha(target)==row['after'],'TARGET CHANGED: '+row['path']
 print(json.dumps({{'directory':str(release),'phase':state['phase'],'compiled':state['compiled'],'count':len(state['files']),'hashes_verified':True}}))
'''
result=subprocess.run(SSH+['python3 -c '+shlex.quote(script)],input=payload,capture_output=True,timeout=210)
if result.stdout:
 info=json.loads(result.stdout);destination=RECEIPT if mode=='prepare' else LEDGER/(receipt_prefix+'-'+mode+'.json');destination.write_text(json.dumps(info,indent=2)+'\n');print(json.dumps(info))
if result.stderr:print(result.stderr.decode()[-2500:],file=sys.stderr)
raise SystemExit(result.returncode)
