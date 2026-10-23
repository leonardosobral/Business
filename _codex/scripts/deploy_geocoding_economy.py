"""Scoped CAS release: default preflight, --verify, --publish --verified.

Never enables automation, changes keys, calls paid APIs, alters schema or Git.
Uses existing reversible transport and checks other fronts before/after release.
"""
import ast,base64,datetime,hashlib,json,pathlib,shlex,subprocess,sys
ROOT=pathlib.Path(__file__).resolve().parents[2]
NEW=['services/geocoding/'+name+'.cfc' for name in ['EconomyPolicy','EconomyAIClient','AIBudget','BatchTransport','BatchClient','Economy']]
FILES=NEW+['services/geocoding/AIClient.cfc','services/geocoding/LocationWorker.cfc','services/geocoding/config.cfm','administracao/geolocalizacao/includes/backend.cfm','administracao/geolocalizacao/includes/view.cfm']
sha=lambda data:hashlib.sha256(data).hexdigest()
before={path:None if path in NEW else sha(subprocess.check_output(['git','show','HEAD:'+path],cwd=ROOT)) for path in FILES}
candidate={path:sha((ROOT/path).read_bytes()) for path in FILES}
tracked=subprocess.check_output(['git','ls-files','services/geocoding','administracao/geolocalizacao','services/openaiUsage','eventos'],cwd=ROOT,text=True).splitlines()
protected=[path for path in tracked if path not in FILES and (path.endswith(('.cfm','.cfc','.js','.css','.py')) or path.endswith('/.htaccess'))]
protected += ['Application.cfc','includes/estrutura/sidenav.cfm','services/EventDescriptionRewriteService.cfc','helpdesk/includes/HelpdeskAI.cfc','administracao/ai-mails/includes/ai.cfm','includes/backend/cron_jobs_service.cfm','cron-jobs/runner.cfm','api/eventos/geolocalizar.cfm']
preserved={path:sha(subprocess.check_output(['git','show','HEAD:'+path],cwd=ROOT)) for path in protected}
# The last verified usage release intentionally has a different menu candidate
# from HEAD. Preserve that deployed front; never publish the local menu here.
usage_receipt=json.loads((ROOT/'_codex/deploy/openai-usage-20261023.json').read_text())
preserved['includes/estrutura/sidenav.cfm']=usage_receipt['candidate_hashes']['business:includes/estrutura/sidenav.cfm']
proof_path=ROOT/'_codex/deploy/geocoding-economy-tests-20261023.json'
if '--verify' in sys.argv:
    run=subprocess.run([sys.executable,'-B',str(ROOT/'_codex/scripts/test_geocoding_native.py'),'all'],capture_output=True,text=True,timeout=900)
    try:tests=[json.loads(line) for line in run.stdout.splitlines() if line.startswith('{')]
    except ValueError:raise SystemExit('Invalid native test receipt')
    if run.returncode or len(tests)<50 or not all(t.get('ok') and t.get('stage_archived') for t in tests):
        print(run.stdout[-8000:]);print(run.stderr[-1000:]);raise SystemExit('Native regression failed')
    fetcher=subprocess.run([sys.executable,'-B','-m','unittest','discover','-s',str(ROOT/'_codex/tests/geocoding'),'-p','test_source_fetcher.py'],capture_output=True,text=True,timeout=90)
    if fetcher.returncode:print(fetcher.stderr[-4000:]);raise SystemExit('Source reader regression failed')
    if candidate!={path:sha((ROOT/path).read_bytes()) for path in FILES}:raise SystemExit('Candidate changed during verification')
    proof_path.write_text(json.dumps({'checked_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'candidate_hashes':candidate,'tests':tests,'reader_ok':True,'provider_calls_allowed':False},ensure_ascii=False,indent=2)+'\n')
    print(json.dumps({'ok':True,'mode':'verified','native_suites':len(tests),'reader_ok':True}));raise SystemExit(0)
publish='--publish' in sys.argv
if publish:
    if '--verified' not in sys.argv:raise SystemExit('Use --verify before publishing')
    proof=json.loads(proof_path.read_text());age=(datetime.datetime.now(datetime.timezone.utc)-datetime.datetime.fromisoformat(proof['checked_at'])).total_seconds()
    if not 0<=age<3600 or proof['candidate_hashes']!=candidate or not proof['reader_ok'] or not all(t.get('ok') and t.get('stage_archived') for t in proof['tests']):raise SystemExit('Fresh matching verification required')
tree=ast.parse((ROOT/'_codex/scripts/deploy_geocoding_sources.py').read_text())
remote=next(ast.literal_eval(node.value) for node in tree.body if isinstance(node,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='REMOTE' for t in node.targets))
anchor='files=[];manifest={}'
guard="""allowed=set(p.pop('allowed'));preserved=p.pop('preserved')
if {f['path'] for f in p['files']}!=allowed:raise SystemExit('Unexpected publication scope')
for rel,expected in preserved.items():
 if sha(target(rel).read_bytes())!=expected:raise SystemExit('Preserved production file changed: '+rel)
files=[];manifest={}"""
if remote.count(anchor)!=1:raise SystemExit('Transport guard changed')
remote=remote.replace(anchor,guard,1)
anchor='try:\n for item in files:'
setup=r'''def pause_probe():
 import secrets
 nonce=secrets.token_hex(24);stage=root/'_codex'/('geo_economy_'+secrets.token_hex(8));stage.mkdir(mode=0o755)
 try:
  (stage/'.htaccess').write_text('Require local\n');os.chmod(stage/'.htaccess',0o644)
  source='<cfsetting showdebugoutput="false" requesttimeout="40"><cfscript>if(!listFind("127.0.0.1,::1",CGI.remote_addr) OR (CGI.http_x_geo_test ?: "") NEQ "'+nonce+'") {cfheader(statuscode=404);abort;}cfcontent(type="text/plain",reset=true); if(createObject("component","services.geocoding.Store").settings().enabled)throw(message="Geolocation must remain paused");writeOutput("GEO_PAUSED");</cfscript>'
  (stage/'run.cfm').write_text(source,encoding='utf-8-sig');os.chmod(stage/'run.cfm',0o644)
  run=subprocess.run(['curl','--silent','--show-error','--max-time','45','--resolve','business.roadrunners.run:443:127.0.0.1','--header','X-Geo-Test: '+nonce,'https://business.roadrunners.run/_codex/'+stage.name+'/run.cfm'],capture_output=True,timeout=50)
  if run.returncode or run.stdout.strip()!=b'GEO_PAUSED':raise RuntimeError('Paused-state guard failed')
 finally:stage.rename(backup/('pause-probe-'+stage.name))
try:
 pause_probe()
 private=pathlib.Path('/var/lib/runnerhub/geocoding-batch')
 if private.is_symlink() or private.parent.resolve()!=pathlib.Path('/var/lib/runnerhub'):raise RuntimeError('Unsafe Batch directory')
 if private.exists():
  info=private.stat()
  if not private.is_dir() or info.st_uid!=999 or info.st_gid!=988 or stat.S_IMODE(info.st_mode)!=0o750:raise RuntimeError('Existing Batch directory metadata differs')
 else:
  private.mkdir(mode=0o750);os.chown(private,999,988);os.chmod(private,0o750)
 for item in files:'''
if remote.count(anchor)!=1:raise SystemExit('Release setup anchor changed')
remote=remote.replace(anchor,setup,1)
# Resolve literal Python strings inside remote without double escaping .htaccess.
remote=remote.replace("write_text('Require local\\\\n')","write_text('Require local\\n')")
anchor="if not all(check['ok'] for check in checks):raise RuntimeError('Final hash mismatch')"
remote=remote.replace(anchor,anchor+"\n pause_probe()\n for rel,expected in preserved.items():\n  if sha(target(rel).read_bytes())!=expected:raise RuntimeError('Concurrent preserved-file change: '+rel)",1)
for name in NEW:
    needle="('/services/geocoding/Sources.cfc','GET',403)"
    remote=remote.replace(needle,"('/"+name+"','GET',403),"+needle,1)
payload={'publish':publish,'allowed':FILES,'preserved':preserved,'files':[{'path':path,'before':before[path],'data':base64.b64encode((ROOT/path).read_bytes()).decode()} for path in FILES]}
run=subprocess.run(['ssh','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-o','ConnectTimeout=12','rr-prod','python3 -c '+shlex.quote(remote)],input=json.dumps(payload).encode(),capture_output=True,timeout=220)
try:result=json.loads(run.stdout)
except ValueError:print(json.dumps({'ok':False,'error':run.stderr.decode(errors='replace')[-1200:]}));raise SystemExit(1)
if result.get('ok') and result.get('mode')=='published':
    result.update({'checked_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'candidate_hashes':candidate,'preserved_files':preserved,'native_suites':len(proof['tests']),'reader_ok':True,'paused_before_and_after':True,'new_private_batch_directory':'/var/lib/runnerhub/geocoding-batch','schema_changed':False,'git_mutations':False})
    (ROOT/'_codex/deploy/geocoding-economy-20261023.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
print(json.dumps({k:v for k,v in result.items() if k not in ['preserved_files']},ensure_ascii=False));raise SystemExit(0 if not run.returncode and result.get('ok') else 1)
