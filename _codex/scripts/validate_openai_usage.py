"""Check installed classes, safe metadata writes and denial paths. No paid calls.

Temporary loopback-only nonce probes are archived privately after verification.
Synthetic events use a separate private directory, never the production ledger.
"""
import datetime, json, pathlib, shlex, subprocess
ROOT=pathlib.Path(__file__).resolve().parents[2]
receipt=json.loads((ROOT/'_codex/deploy/openai-usage-20261023.json').read_text())
REMOTE=r"""
import hashlib,json,os,pathlib,pwd,secrets,subprocess,sys,tempfile
p=json.load(sys.stdin);roots={'business':pathlib.Path('/var/www/business.roadrunners.run'),'news':pathlib.Path('/var/www/conteudo.roadrunners.run'),'rr':pathlib.Path('/var/www/roadrunners.com.br')}
hosts={'business':'business.roadrunners.run','news':'conteudo.roadrunners.run','rr':'roadrunners.run'}
sha=lambda b:hashlib.sha256(b).hexdigest()
for key,expected in p['candidate_hashes'].items():
 app,rel=key.split(':',1)
 if sha((roots[app]/rel).read_bytes())!=expected:raise SystemExit('Published runtime changed: '+key)
for rel,expected in p['preserved_files'].items():
 if sha((roots['business']/rel).read_bytes())!=expected:raise SystemExit('Preserved runtime changed: '+rel)
archive=pathlib.Path(tempfile.mkdtemp(prefix='openai-usage-validation-',dir='/var/backups'));os.chmod(archive,0o700)
account=pwd.getpwnam('coldfusion');stages=[];checks=[];directories=[]
try:
 for app,root in roots.items():
  nonce=secrets.token_hex(24);stage=root/'_codex'/('usage_validation_'+secrets.token_hex(8));stage.mkdir(parents=True,mode=0o755);stages.append((app,stage))
  (stage/'.htaccess').write_text('Require local\n')
  private=pathlib.Path(tempfile.mkdtemp(prefix='openai-usage-probe-',dir='/var/lib/runnerhub'));os.chmod(private,0o750);os.chown(private,account.pw_uid,account.pw_gid);directories.append((app,private))
  guard='<cfsetting showdebugoutput="false" requesttimeout="45"><cfscript>if(!listFind("127.0.0.1,::1",CGI.remote_addr) OR (CGI.http_x_usage_probe ?: "") NEQ "'+nonce+'"){cfheader(statuscode=404);abort;}cfheader(name="Cache-Control",value="no-store");cfcontent(type="text/plain; charset=utf-8",reset=true);'
  observer='''o=new services.openaiUsage.Observer("PRIVATE_DIR");
if(!o.observe("helpdesk","validation","gpt-6.1-sol",{statusCode="200",fileContent='{"usage":{"input_tokens":100,"output_tokens":10}}'},1))throw(message="Observer write failed");
if(!o.observe("helpdesk","validation","gpt-6.1-sol",{statusCode="429",fileContent='{"error":{"code":"insufficient_quota"}}'},1))throw(message="Observer failure metadata failed");
files=directoryList("PRIVATE_DIR",false,"path","*.jsonl");if(arrayLen(files) NEQ 1 OR arrayLen(listToArray(trim(fileRead(files[1],"utf-8")),chr(10))) NEQ 2)throw(message="Synthetic ledger invalid");
if(!createObject("java","java.io.File").init("/var/lib/runnerhub/openai-usage").canWrite())throw(message="Runtime cannot write private production storage");
'''.replace('PRIVATE_DIR',str(private))
  wrappers={'business':['services.geocoding.AIClient','services.EventDescriptionRewriteService','helpdesk.includes.HelpdeskAI'],'news':['inc.article_summary_provider','inc.openai_client','inc.news_audio_provider'],'rr':['services.VickyAgentService']}[app]
  observer+='for(componentName in '+json.dumps(wrappers)+'){getComponentMetadata(componentName);}\n'
  if app=='business':
   observer+='''store=new services.openaiUsage.Store();report=store.report(store.filters({period="7"}));if(!report.collectorAvailable OR report.trackedSince LTE 0 OR arrayLen(report.warnings))throw(message="Installed report unavailable or partial read failed");dailyTokens=0;dailyUsd=0;for(dailyRow in report.days){dailyTokens+=dailyRow.tokens;dailyUsd+=dailyRow.usd;}if(dailyTokens NEQ report.summary.tokens OR abs(dailyUsd-report.summary.usd) GT 0.000001)throw(message="Daily chart does not reconcile");writeOutput(serializeJSON({records=report.summary.records,tokens=report.summary.tokens,detailed=report.summary.requests,unknown=report.summary.unknown,daily_reconciles=true}));'''
  cases=[('observer',200,observer+'writeOutput("USAGE_RUNTIME_PASSED");','GET')]
  if app=='business':
   for name,admin,effective,delegated in [('non-admin',False,False,False),('account-context',True,False,False),('delegated',True,True,True)]:
    code='qPerfil=queryNew("is_admin","bit");queryAddRow(qPerfil);querySetCell(qPerfil,"is_admin",'+str(admin).lower()+');VARIABLES.businessEffectiveIsAdmin='+str(effective).lower()+';REQUEST.businessAccessContext={accessMode="'+('DELEGATED' if delegated else 'DIRECT')+'"};include "/administracao/consumo-openai/includes/backend.cfm";'
    cases.append((name,403,code,'GET'))
   code='qPerfil=queryNew("is_admin","bit");queryAddRow(qPerfil);querySetCell(qPerfil,"is_admin",true);VARIABLES.businessEffectiveIsAdmin=true;include "/administracao/consumo-openai/includes/backend.cfm";'
   cases.append(('method',405,code,'POST'))
  for name,expected,code,method in cases:
   source=guard+'try{'+code+'}catch(any failure){writeOutput("USAGE_PROBE_FAILED " & encodeForHTML(failure.type & ": " & failure.message));}</cfscript>'
   (stage/(name+'.cfm')).write_text(source);os.chmod(stage/(name+'.cfm'),0o644)
   url='https://'+hosts[app]+'/_codex/'+stage.name+'/'+name+'.cfm'
   run=subprocess.run(['curl','--silent','--show-error','--max-time','50','--resolve',hosts[app]+':443:127.0.0.1','--header','X-Usage-Probe: '+nonce,'--request',method,'--write-out','\n%{http_code}',url],capture_output=True,timeout=55)
   body,_,status=run.stdout.rpartition(b'\n');ok=run.returncode==0 and status==str(expected).encode() and (expected!=200 or b'USAGE_RUNTIME_PASSED' in body)
   checks.append({'app':app,'case':name,'status':status.decode(),'ok':ok,'output':body.decode()[-600:] if b'<html' not in body.lower() else 'Unexpected HTML; private evidence retained'})
   (archive/(app+'-'+name+'.txt')).write_bytes(body);os.chmod(archive/(app+'-'+name+'.txt'),0o600)
 # Recover the exact task-owned malformed-fixture artifact, if still present.
 artifact=pathlib.Path('/opt/coldfusion2025/cfusion/runtime/work/Catalina/localhost/tmp/{}')
 if artifact.exists() and artifact.stat().st_size<4096:
  try:
   lines=[json.loads(line) for line in artifact.read_text().splitlines() if line.strip()]
   if lines and all(set(line)=={'schema_version','module','at_ms'} and line['schema_version']==1 and line['module']=='geolocation' for line in lines):artifact.rename(archive/'synthetic-fixture-artifact.jsonl')
  except (ValueError,TypeError):pass
finally:
 for app,stage in stages:
  if stage.exists():stage.rename(archive/(app+'-stage'))
 for app,private in directories:
  if private.exists():private.rename(archive/(app+'-synthetic-journal'))
result={'ok':bool(checks) and all(c['ok'] for c in checks),'checks':checks,'archive':str(archive),'stages_archived':True,'paid_calls':0,'production_journal_modified_by_test':False}
(archive/'receipt.json').write_text(json.dumps(result,indent=2));os.chmod(archive/'receipt.json',0o600)
print(json.dumps(result));sys.exit(0 if result['ok'] else 1)
"""
run=subprocess.run(['ssh','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-o','ConnectTimeout=12','rr-prod','python3 -c '+shlex.quote(REMOTE)],input=json.dumps(receipt).encode(),capture_output=True,timeout=240)
try:result=json.loads(run.stdout)
except ValueError:result={'ok':False,'diagnostic':run.stderr.decode(errors='replace')[-1000:]}
result['checked_at']=datetime.datetime.now(datetime.timezone.utc).isoformat()
(ROOT/'_codex/deploy/openai-usage-validation-20261023.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
print(json.dumps(result,ensure_ascii=False));raise SystemExit(0 if not run.returncode and result.get('ok') else 1)
