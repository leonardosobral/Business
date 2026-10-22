"""Exercise the real service on Adobe CF with a fake provider, never production data."""
import datetime,hashlib,json,pathlib,re,shlex,subprocess,sys

ROOT=pathlib.Path(__file__).resolve().parents[2]
REMOTE=r"""
import json,os,pathlib,secrets,subprocess,sys,tempfile
payload=json.load(sys.stdin)
with_observed=payload.pop('_with_observed',False)
name='rewrite_test_'+secrets.token_hex(8)
stage=pathlib.Path('/var/www/business.roadrunners.run/_codex')/name
archive=pathlib.Path(tempfile.mkdtemp(prefix='rewrite-tests-',dir='/var/backups'))
os.chmod(archive,0o700)
nonce=secrets.token_hex(24)
result={'ok':False}
try:
    stage.mkdir(mode=0o755)
    (stage/'services').mkdir(mode=0o755)
    (stage/'.htaccess').write_text('Require local\n')
    if with_observed:
        observed=[]
        for event_id,source_file in [(43854,'rewrite-validation-20261015-p8dkiv9m'),(43916,'rewrite-validation-20261015-s7897ev7'),(44883,'rewrite-validation-20261015-e4ho6ogb')]:
            evidence=json.loads((pathlib.Path('/var/backups')/source_file/'evidence.json').read_text())
            event=evidence['events'][0]
            observed.append({'id':event_id,'source':event['source_text'],'candidate':event.get('candidate','')})
        (stage/'observed.json').write_text(json.dumps(observed));os.chmod(stage/'observed.json',0o644)
    for path,content in payload.items():
        content=content.replace('"services.', '"_codex.'+name+'.services.')
        content=content.replace('new services.', 'new _codex.'+name+'.services.')
        (stage/path).parent.mkdir(parents=True,exist_ok=True)
        (stage/path).write_text(content,encoding='utf-8-sig')
        os.chmod(stage/path,0o644)
    (stage/'run.cfm').write_text('''<cfsetting showdebugoutput="false" requesttimeout="45"><cfscript>
if(!listFind("127.0.0.1,::1",CGI.remote_addr) OR !structKeyExists(CGI,"http_x_rewrite_test") OR CGI.http_x_rewrite_test NEQ "'''+nonce+'''"){cfheader(statuscode=404);abort;}
cfheader(name="Cache-Control",value="no-store");cfcontent(type="text/plain; charset=utf-8",reset=true);
try {include "service.cfm";} catch(any testFailure) {writeOutput("TEST_FAILED: " & encodeForHTML(testFailure.type & ": " & testFailure.message));}
</cfscript>''')
    os.chmod(stage/'run.cfm',0o644)
    url='https://business.roadrunners.run/_codex/'+name+'/run.cfm'
    proc=subprocess.run(['curl','--silent','--show-error','--max-time','55','--resolve','business.roadrunners.run:443:127.0.0.1','--header','X-Rewrite-Test: '+nonce,url],capture_output=True,timeout=60)
    output=proc.stdout.decode(errors='replace')
    result={'ok':proc.returncode==0 and 'EVENT_REWRITE_TESTS_PASSED:' in output,'output':output[-5000:] if '<!doctype' not in output.lower() else 'Unexpected HTML response; private artifact retained'}
    (archive/'output.txt').write_text(output);os.chmod(archive/'output.txt',0o600)
    guard=(stage/'run.cfm').read_text().replace('include "service.cfm";','REQUEST.guardsOnly=true;include "guard-test.cfm";')
    (stage/'run-guards.cfm').write_text(guard);os.chmod(stage/'run-guards.cfm',0o644)
    guards=subprocess.run(['curl','--silent','--show-error','--max-time','30','--resolve','business.roadrunners.run:443:127.0.0.1','--header','X-Rewrite-Test: '+nonce,url.replace('run.cfm','run-guards.cfm')],capture_output=True,timeout=35)
    guard_output=guards.stdout.decode(errors='replace')
    (archive/'guards.txt').write_text(guard_output);os.chmod(archive/'guards.txt',0o600)
    result['guards_ok']=guards.returncode==0 and 'Endpoint guards passed: 29' in guard_output
    result['guards_output']=guard_output[-1800:] if '<!doctype' not in guard_output.lower() else 'Unexpected guard HTML response'
    result['ok']=result['ok'] and result['guards_ok']
    db_guard=(stage/'run.cfm').read_text().replace('include "service.cfm";','include "service.cfm";include "audit-database.cfm";')
    db_guard=db_guard.replace('testFailure.type & ": " & testFailure.message','testFailure.type & ": " & testFailure.message & " [" & (testFailure.sqlState ?: "") & "] " & left(testFailure.detail ?: "",600)')
    (stage/'run-db.cfm').write_text(db_guard);os.chmod(stage/'run-db.cfm',0o644)
    db_run=subprocess.run(['curl','--silent','--show-error','--max-time','40','--resolve','business.roadrunners.run:443:127.0.0.1','--header','X-Rewrite-Test: '+nonce,url.replace('run.cfm','run-db.cfm')],capture_output=True,timeout=45)
    db_output=db_run.stdout.decode(errors='replace');(archive/'database.txt').write_text(db_output);os.chmod(archive/'database.txt',0o600)
    result['database_ok']=db_run.returncode==0 and 'AUDIT_DATABASE_PASSED' in db_output
    result['database_output']=db_output[-1400:] if '<!doctype' not in db_output.lower() else 'Unexpected database fixture HTML response'
    result['ok']=result['ok'] and result['database_ok']
    privacy_cases=[
        ('defaults',200,'qPerfil=queryNew("is_admin");queryAddRow(qPerfil);querySetCell(qPerfil,"is_admin",true);include "audit-backend-runtime.cfm";if(len(VARIABLES.auditError)) throw(type="Test.Failed",message="Default audit filters failed");writeOutput("AUDIT_DEFAULTS_PASSED");','GET'),
        ('denied',403,'qPerfil=queryNew("is_admin");queryAddRow(qPerfil);querySetCell(qPerfil,"is_admin",false);include "audit-backend-runtime.cfm";','GET'),
        ('invalid',400,'qPerfil=queryNew("is_admin");queryAddRow(qPerfil);querySetCell(qPerfil,"is_admin",true);URL.audit_id="not-an-id";include "audit-backend-runtime.cfm";','GET'),
        ('method',405,'qPerfil=queryNew("is_admin");queryAddRow(qPerfil);querySetCell(qPerfil,"is_admin",true);include "audit-backend-runtime.cfm";','POST'),
        ('view',403,'include "audit-view-runtime.cfm";','GET')]
    result['privacy_checks']=[]
    for label,expected,code,method in privacy_cases:
        gate=(stage/'run.cfm').read_text().replace('include "service.cfm";',code)
        gate_path=stage/('run-'+label+'.cfm');gate_path.write_text(gate,encoding='utf-8-sig');os.chmod(gate_path,0o644)
        gate_run=subprocess.run(['curl','--silent','--show-error','--max-time','20','--request',method,'--resolve','business.roadrunners.run:443:127.0.0.1','--header','X-Rewrite-Test: '+nonce,'--write-out','\n%{http_code}',url.replace('run.cfm',gate_path.name)],capture_output=True,timeout=25)
        body,_,status=gate_run.stdout.rpartition(b'\n')
        passed=gate_run.returncode==0 and status==str(expected).encode() and b'PRIVATE_REJECTED' not in body
        if label=='defaults':passed=passed and b'AUDIT_DEFAULTS_PASSED' in body
        result['privacy_checks'].append({'case':label,'status':status.decode(),'ok':passed})
        result['ok']=result['ok'] and passed
finally:
    if stage.exists():stage.rename(archive/'tests')
    result['archive']=str(archive)
    result['stage_removed']=not stage.exists()
print(json.dumps(result))
"""
payload={'services/EventDescriptionRewriteService.cfc':(ROOT/'services/EventDescriptionRewriteService.cfc').read_text()}
for name in ['ProviderFixture.cfc','service.cfm','translation.cfm','format-equivalences.cfm','regressions.cfm','cron-validation.cfm','observed.cfm','audit-evidence.cfm','audit-view.cfm','audit-database.cfm']:
    destination='services/'+name if name.endswith('.cfc') else name
    payload[destination]=(ROOT/'_codex/tests/event-description-rewrite'/name).read_text()
audit_view=ROOT/'administracao/cron-jobs/includes/description_audit_view.cfm'
payload['audit-view-runtime.cfm']=audit_view.read_text() if audit_view.exists() else '<cfthrow type="Test.Failed" message="A comparação privada ainda não é exibida">'
payload['service.cfm']=payload['service.cfm'].replace('include "audit-evidence.cfm";','include "audit-evidence.cfm"; include "audit-view.cfm";')
audit_backend=(ROOT/'administracao/cron-jobs/includes/description_audit_backend.cfm').read_text()
payload['audit-backend-runtime.cfm']=audit_backend
endpoint=(ROOT/'api/eventos/jobs/rewrite-descriptions.cfm').read_text()
for name,table,ending in [('pt','tb_evento_descricao_rewrites','}, VARIABLES.rewriteDbOptions);'),('translation','tb_evento_descricao_translations','}, dbOptions);')]:
    update=endpoint.index('UPDATE public.'+table)
    start=endpoint.rfind('queryExecute(',0,update)
    end=endpoint.index(ending,update)+len(ending)
    payload['audit-'+name+'-write.cfm']='<cfscript>'+endpoint[start:end]+'</cfscript>'
for name,marker in [('rewrite','rejectedDescription'),('translation','rejectedTranslation')]:
    start=endpoint.index('catch (EventDescriptionRewrite.Validation '+marker+') {')
    start=endpoint.index('{',start)+1
    end=endpoint.index('} catch (',start)
    payload[name+'-catch.cfm']='<cfscript>'+endpoint[start:end]+'</cfscript>'
payload['service.cfm']=payload['service.cfm'].replace('include "translation.cfm";','include "translation.cfm"; include "cron-validation.cfm"; include "observed.cfm";')
if '--format-audit' in sys.argv:
    payload['observed-format-audit.cfm']=(ROOT/'_codex/tests/event-description-rewrite/observed-format-audit.cfm').read_text()
    payload['service.cfm']=payload['service.cfm'].replace('include "format-equivalences.cfm";','include "format-equivalences.cfm";include "observed-format-audit.cfm";')
payload['_with_observed']='--observed' in sys.argv
if not payload['_with_observed']:payload['service.cfm']=payload['service.cfm'].replace(' include "observed.cfm";','')
guard_endpoint=endpoint.replace('CGI.request_method','REQUEST.fixtureMethod').replace('getHttpRequestData(','fixtureHttpRequestData(')
guard_endpoint=guard_endpoint.replace('if (fileExists(expandPath("/config/business.local.cfm")))','if (true)')
guard_endpoint=guard_endpoint.replace('createObject("java", "java.lang.System").getenv()','createObject("java", "java.util.HashMap").init()')
guard_endpoint=guard_endpoint.replace('function rewriteJsonResponse(required numeric statusCode, required struct payload) {','function rewriteJsonResponse(required numeric statusCode, required struct payload) { REQUEST.fixtureResponse={code=arguments.statusCode,payload=arguments.payload}; throw(type="FixtureResponse");')
guard_start=guard_endpoint.index('if (uCase(REQUEST.fixtureMethod')
# Adobe CF does not permit declaring a function twice when an endpoint is included
# for multiple fake requests; load its unchanged function definitions once.
payload['guard-functions.cfm']=guard_endpoint[:guard_start]+'</cfscript>'
payload['api/eventos/jobs/rewrite-descriptions.cfm']='<cfscript>'+guard_endpoint[guard_start:]
payload['config/business.local.cfm']='<cfset businessLocalConfig=REQUEST.fixtureConfig>'
payload['guard-test.cfm']='<cfinclude template="guard-functions.cfm">'+(ROOT/'_codex/tests/event-description-endpoint.cfm').read_text()
proc=subprocess.run(['ssh','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-o','ConnectTimeout=12','rr-prod','python3 -c '+shlex.quote(REMOTE)],input=json.dumps(payload).encode(),capture_output=True,timeout=75)
try:result=json.loads(proc.stdout)
except Exception:result={'ok':False,'error':'Native regression transport failed; output suppressed'}
if '--save-format-evidence' in sys.argv:
    evidence={key:result.get(key) for key in ['ok','guards_ok','database_ok','privacy_checks','archive','stage_removed']}
    counts=re.findall(r'EVENT_REWRITE_TESTS_PASSED:([0-9]+)',result.get('output',''))
    evidence.update(service_sha256=hashlib.sha256((ROOT/'services/EventDescriptionRewriteService.cfc').read_bytes()).hexdigest(),
        checked_at=datetime.datetime.now(datetime.timezone.utc).isoformat(),native_checks=int(counts[-1]) if counts else 0,
        observed_formats='--format-audit' in sys.argv and 'OBSERVED_FORMAT_AUDIT_PASSED' in result.get('output',''),
        historical_regressions='--observed' in sys.argv,live_ai_calls=0)
    (ROOT/'_codex/deploy/event-rewrite-format-tests-20261021.json').write_text(json.dumps(evidence,ensure_ascii=False,indent=2)+'\n')
print(json.dumps(result,ensure_ascii=False))
if not result.get('ok'):sys.exit(1)
