"""Run isolated native fixtures. Provider calls: explicit 'smoke'/'research_geocode' only."""
import json, pathlib, shlex, subprocess, sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
MODE = sys.argv[1] if len(sys.argv) > 1 else 'policy'
if MODE == 'all':
    for suite in ['economy_policy','economy_contract','economy_budget','economy_periods','economy_concurrent','economy_batch','economy_batch_pause','economy_flow','economy_pause','economy_legacy','economy_view']:
        subprocess.run([sys.executable,__file__,suite],check=True)
    for suite in ['optimization_retry','review_edit','review_edit_resume','review_guide','review_guide_view','review_http']:
        subprocess.run([sys.executable,__file__,suite],check=True)
    for suite in ['policy','provider','sources','source_conflicts','worker','endpoint','view','access','integration','workflow','acceleration','quota_3000','schedule','ai_schema','ai_contract','ai_astra','ai_locations','ai_integration','ai_workflow','ai_resume','ai_view','ai_full_view','ai_seed','ai_provider_failure','enrichment_policy','enrichment_contract','enrichment_integration','enrichment_view','enrichment_workflow','enrichment_review_regressions','enrichment_repeated_state','optimization_cache','optimization_store','optimization_worker']:
        subprocess.run([sys.executable,__file__,suite],check=True)
    raise SystemExit(0)
REMOTE = r'''
import json,os,pathlib,secrets,subprocess,sys,tempfile
p=json.load(sys.stdin);nonce=secrets.token_hex(24);mode=p.pop('_mode')
name='geocoding_test_'+secrets.token_hex(8)
stage=pathlib.Path('/var/www/business.roadrunners.run/_codex')/name
archive=pathlib.Path(tempfile.mkdtemp(prefix='geocoding-tests-',dir='/var/backups'));os.chmod(archive,0o700)
result={'ok':False}
try:
 stage.mkdir(mode=0o755);(stage/'.htaccess').write_text('Require local\n');os.chmod(stage/'.htaccess',0o644)
 for path,content in p.items():
  content=content.replace('services.geocoding.','_codex.'+name+'.services.geocoding.')
  content=content.replace('__GEO_TEST_PACKAGE__','_codex.'+name)
  dest=stage/path;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_text(content,encoding='utf-8-sig');os.chmod(dest,0o644)
 wrapper='<cfsetting showdebugoutput="false" requesttimeout="50"><cfscript>if(!listFind("127.0.0.1,::1",CGI.remote_addr) OR !structKeyExists(CGI,"http_x_geo_test") OR CGI.http_x_geo_test NEQ "'+nonce+'") {cfheader(statuscode=404);abort;} cfheader(name="Cache-Control",value="no-store");cfcontent(type="text/plain; charset=utf-8",reset=true); try {include "tests/'+mode+'.cfm";} catch(any failure) {writeOutput("GEO_TEST_FAILED " & encodeForHTML(failure.type & ": " & failure.message & " " & left(failure.detail ?: "",1000)));if(structKeyExists(failure,"tagContext"))for(frame in failure.tagContext)writeOutput(chr(10) & encodeForHTML(frame.template & ":" & frame.line));}</cfscript>'
 (stage/'run.cfm').write_text(wrapper,encoding='utf-8-sig');os.chmod(stage/'run.cfm',0o644)
 r=subprocess.run(['curl','--silent','--show-error','--max-time','55','--resolve','business.roadrunners.run:443:127.0.0.1','--header','X-Geo-Test: '+nonce,'https://business.roadrunners.run/_codex/'+name+'/run.cfm'],capture_output=True,timeout=60)
 output=r.stdout.decode(errors='replace');(archive/'output.txt').write_text(output);os.chmod(archive/'output.txt',0o600)
 result={'ok':r.returncode==0 and ('GEO_'+mode.upper()+'_PASSED') in output and 'GEO_TEST_FAILED' not in output,'output':output[-(60000 if mode=='optimization_diagnostic' else 6500):] if '<!doctype' not in output.lower() else 'Unexpected HTML; inspect private archive'}
 if mode=='access':
  result={'ok':True,'cases':[]}
  for case,expected,method in [('denied',403,'GET'),('delegated',403,'GET'),('filters',400,'GET'),('csrf',403,'POST'),('default',200,'GET')]:
   r=subprocess.run(['curl','--silent','--show-error','--max-time','30','--request',method,'--resolve','business.roadrunners.run:443:127.0.0.1','--header','X-Geo-Test: '+nonce,'--write-out','\n%{http_code}','https://business.roadrunners.run/_codex/'+name+'/run.cfm?testcase='+case],capture_output=True,timeout=35)
   body,_,status=r.stdout.rpartition(b'\n');passed=r.returncode==0 and status==str(expected).encode()
   if case=='default':passed=passed and b'GEO_ACCESS_PASSED' in body and b'GEO_TEST_FAILED' not in body
   result['cases'].append({'case':case,'status':status.decode(),'ok':passed})
   result['ok']=result['ok'] and passed
   (archive/(case+'.txt')).write_bytes(body)
 if mode=='review_http':
  result={'ok':True,'cases':[]}
  for case,expected in [('first',303),('last',303),('correct',303),('correct_last',303),('invalid_edit',200),('obsolete_edit',200),('skip',303),('resume',303),('stale',200),('csrf',403),('delegated',403)]:
   r=subprocess.run(['curl','--silent','--show-error','--max-time','30','--request','POST','--dump-header','-','--resolve','business.roadrunners.run:443:127.0.0.1','--header','X-Geo-Test: '+nonce,'--write-out','\n%{http_code}','https://business.roadrunners.run/_codex/'+name+'/run.cfm?testcase='+case],capture_output=True,timeout=35)
   body,_,status=r.stdout.rpartition(b'\n');passed=r.returncode==0 and status==str(expected).encode() and b'GEO_TEST_FAILED' not in body
   location=next((line.strip().split(':',1)[1].strip() for line in body.decode(errors='replace').splitlines() if line.lower().startswith('location:')),'')
   if expected==303:
    passed=passed and 'aba=revisao' in location and ('id=2147001701' in location if case in ['first','correct'] else 'id=2147001701' not in location)
    if case in ['first','correct']:passed=passed and 'etapa=field-2' in location
   if expected==200:passed=passed and b'GEO_REVIEW_HTTP_PASSED' in body
   result['cases'].append({'case':case,'status':status.decode(),'location':location,'ok':passed})
   result['ok']=result['ok'] and passed
   (archive/(case+'.txt')).write_bytes(body)
finally:
 if stage.exists():stage.rename(archive/'tests')
 result['archive']=str(archive);result['stage_archived']=not stage.exists()
print(json.dumps(result))
'''
payload = {'_mode': MODE}
payload['includes/backend/cron_jobs_service.cfm'] = (ROOT / 'includes/backend/cron_jobs_service.cfm').read_text()
payload['tests/geocoding_job.sql'] = (ROOT / 'administracao/geolocalizacao/geocoding_job.sql').read_text()
view = ROOT / 'administracao/geolocalizacao/includes/view.cfm'
payload['tests/view-runtime.cfm'] = view.read_text() if view.exists() else '<cfthrow type="Test.Failed" message="A interface de geolocalização ainda não existe">'
for directory in ['services/geocoding', '_codex/tests/geocoding','administracao/geolocalizacao']:
    base = ROOT / directory
    if base.exists():
        for source in base.rglob('*'):
            if source.is_file() and source.suffix in ['.cfc', '.cfm', '.py']:
                name = 'tests/' + str(source.relative_to(base)) if directory.startswith('_codex') else str(source.relative_to(ROOT))
                payload[name] = source.read_text()
negative = next((arg.split('=',1)[1] for arg in sys.argv[2:] if arg.startswith('--negative-control=')), '')
if '--allow-provider' not in sys.argv:
    # Fail closed at the actual HTTP boundary even if fixture injection regresses.
    path='services/geocoding/AIClient.cfc'
    payload[path]=payload[path].replace('            cfhttp(url="https://api.openai.com/v1/responses"',
        '            throw(type="Test.ProviderBlocked",message="Provider disabled in native fixtures");cfhttp(url="https://api.openai.com/v1/responses"')
    path='services/geocoding/BatchTransport.cfc'
    if path in payload:
        payload[path]=payload[path].replace('        cfhttp(', '        throw(type="Test.ProviderBlocked",message="Batch provider disabled in native fixtures");cfhttp(')
if MODE=='review_http':
    # Substitute only the mutating store boundary in an isolated copy. Real writes
    # and continuation are covered separately by transaction/rollback fixtures.
    path='administracao/geolocalizacao/includes/backend.cfm'
    payload[path]=payload[path].replace('new services.geocoding.LocationStore()','new __GEO_TEST_PACKAGE__.tests.FixtureGuidedStore()')
if MODE=='optimization_store':
    # Production is intentionally paused with 20 real ready rows. Scope only the
    # fixture's capacity count; never modify or hide real queue rows in the DB.
    path='services/geocoding/LocationStore.cfc'
    anchor="SELECT count(*) AS n FROM public.tb_evento_geocoding WHERE source_snapshot->>'version'='3' AND ((status"
    if payload[path].count(anchor)!=1:raise SystemExit('Fixture capacity anchor changed')
    payload[path]=payload[path].replace(anchor,"SELECT count(*) AS n FROM public.tb_evento_geocoding WHERE id_evento BETWEEN 2147001301 AND 2147001321 AND source_snapshot->>'version'='3' AND ((status",1)
if '--trace-fixture' in sys.argv and MODE == 'workflow':
    # Only the synthetic workflow: no real keys, provider calls or event data.
    payload['services/geocoding/Worker.cfc']=payload['services/geocoding/Worker.cfc'].replace(
        '// Avoid exception text, provider content, or connection strings in cron history.',
        'throw(object=workFailure);')
if '--trace-ai-replay' in sys.argv and MODE == 'ai_replay':
    payload['services/geocoding/LocationWorker.cfc']=payload['services/geocoding/LocationWorker.cfc'].replace(
        '}catch(any failed){var diagnostic', '}catch(any failed){throw(object=failed);var diagnostic')
if '--trace-ai-failure' in sys.argv and MODE == 'ai_provider_failure':
    payload['services/geocoding/LocationWorker.cfc']=payload['services/geocoding/LocationWorker.cfc'].replace(
        '}catch(any failed){try{variables.store.finish', '}catch(any failed){throw(object=failed);try{variables.store.finish')
if negative:
    # Negative controls mutate only the isolated fixture copy, never product files.
    controls = {
        'guide-no-destination-cas': ('services/geocoding/ReviewGuide.cfc','return same.recordCount NEQ 1;','return false;'),
        'no-enrichment-publish': ('services/geocoding/LocationStore.cfc','    public struct function publishEnrichment(required struct work,required struct progress,required string actor){return new services.geocoding.EnrichmentStore().publish(this,work,progress,actor);}','    public struct function publishEnrichment(required struct work,required struct progress,required string actor){return {work=work,progress=progress};}'),
        'null-text': ('services/geocoding/Policy.cfc',next(line for line in payload['services/geocoding/Policy.cfc'].splitlines() if 'function readableText(' in line),'    public string function readableText(required string value){return value;}'),
        'stale-review': ('services/geocoding/Store.cfc','            variables.policy.requireRevision(work,revision);',''),
        'provider-lease': ('services/geocoding/Store.cfc','            if(row.in_flight)return {allowed=false,reason="provider_busy",retryAfter=30};',''),
        'expired-lease': ('services/geocoding/Store.cfc','FOR UPDATE SKIP LOCKED LIMIT 20) RETURNING *','FOR UPDATE SKIP LOCKED LIMIT 0) RETURNING *'),
        'foreign-region': ('services/geocoding/Policy.cfc','return len(trim(source.estado)) AND (normalize(text(candidate,"state_code")) EQ normalize(source.estado) OR normalize(text(candidate,"state")) EQ normalize(source.estado));','return !len(trim(source.estado)) OR normalize(text(candidate,"state_code")) EQ normalize(source.estado);')}
    path,before,after=controls[negative]
    if payload[path].count(before)!=1:raise SystemExit('Negative-control anchor mismatch')
    payload[path]=payload[path].replace(before,after,1)
proc = subprocess.run(['ssh', '-o', 'BatchMode=yes', '-o', 'StrictHostKeyChecking=yes', '-o', 'ConnectTimeout=12', 'rr-prod', 'python3 -c ' + shlex.quote(REMOTE)], input=json.dumps(payload).encode(), capture_output=True, timeout=75)
try:
    result = json.loads(proc.stdout)
except Exception:
    result = {'ok': False, 'error': 'Native test transport failed; output suppressed'}
print(json.dumps(result, ensure_ascii=False))
if proc.returncode or not result.get('ok'):
    sys.exit(1)
