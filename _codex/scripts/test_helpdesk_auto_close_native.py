"""Private localhost-only helpdesk tests; no external notifications."""
import ast,json,pathlib,shlex,subprocess,sys
ROOT=pathlib.Path(__file__).resolve().parents[2]
mode=sys.argv[1] if len(sys.argv)>1 else 'source'
tree=ast.parse((ROOT/'_codex/scripts/test_user_acquisition_native.py').read_text())
remote=next(ast.literal_eval(n.value) for n in tree.body if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='REMOTE' for t in n.targets))
remote=remote.replace('user_acquisition_','helpdesk_close_').replace('business-user-acquisition-test-','business-helpdesk-close-test-').replace('USER_ACQUISITION_','HELPDESK_CLOSE_')
remote=remote.replace("body=body.replace('new services.UserAcquisitionMetrics','new _codex.'+name+'.services.UserAcquisitionMetrics')", "body=body.replace('new services.HelpdeskAutoClose','new _codex.'+name+'.services.HelpdeskAutoClose').replace('__CLOSE_COMPONENT__','_codex.'+name+'.services.HelpdeskAutoClose')")
if mode=='http':
 remote=remote.replace('this.setClientCookies=false;}', 'this.setClientCookies=false;function onApplicationStart(){application.cronJobs={runnerToken="fixture-only-secret"};return true;}}')
 original=next(line for line in remote.splitlines() if line.startswith(" run=subprocess.run(['curl'"))
 replacement=''' if mode=='http':
  from types import SimpleNamespace
  checks=[]
  for method,body,auth,expected in [('GET','',False,405),('POST','{}',False,401),('POST','{"dryRun":true}',True,200),('POST','{"limit":101}',True,400),('POST','[]',True,400)]:
   command=['curl','-sS','--max-time','30','--resolve','business.roadrunners.run:443:127.0.0.1','--request',method,'--header','Content-Type: application/json','--write-out','\\n%{http_code}','https://business.roadrunners.run/_codex/'+name+'/api/helpdesk/auto-close.cfm']
   if auth:command+=['--header','Authorization: Bearer fixture-only-secret']
   if body:command+=['--data',body]
   response=subprocess.run(command,capture_output=True,timeout=35);content,_,status=response.stdout.rpartition(b'\\n')
   valid=not response.returncode and status==str(expected).encode()
   if expected==200:
    try:parsed=json.loads(content);valid=valid and parsed.get('STATUS',parsed.get('status'))=='dry_run' and parsed.get('CLOSED',parsed.get('closed'))==0
    except ValueError:valid=False
   checks.append({'method':method,'expected':expected,'status':status.decode(),'ok':valid})
  raw=('HELPDESK_CLOSE_HTTP_PASSED ' if all(c['ok'] for c in checks) else 'TEST_FAILED ')+json.dumps(checks)
  run=SimpleNamespace(returncode=0,stdout=raw.encode())
 else:
  '''+original.strip()
 remote=remote.replace(original,replacement,1)
payload={'mode':mode}
for rel in ['services/HelpdeskAutoClose.cfc']:
 p=ROOT/rel
 if p.exists():payload[rel]=p.read_text()
payload['includes/backend/cron_jobs_service.cfm']=(ROOT/'includes/backend/cron_jobs_service.cfm').read_text()
payload['config/business.local.cfm']='<cfset businessLocalConfig={}/>'
if (ROOT/'api/helpdesk/auto-close.cfm').exists():payload['api/helpdesk/auto-close.cfm']=(ROOT/'api/helpdesk/auto-close.cfm').read_text()
payload['tests/install.sql']=(ROOT/'_codex/sql/2026-10-26_helpdesk_auto_close_job.sql').read_text()
for p in (ROOT/'_codex/tests/helpdesk-auto-close').glob('*'):
 if p.is_file():payload['tests/'+p.name]=p.read_text()
run=subprocess.run(['ssh','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-o','ConnectTimeout=12','rr-prod','python3 -c '+shlex.quote(remote)],input=json.dumps(payload).encode(),capture_output=True,timeout=65)
try:result=json.loads(run.stdout)
except ValueError:result={'ok':False,'error':run.stderr.decode(errors='replace')[-1000:]}
print(json.dumps(result,ensure_ascii=False));raise SystemExit(0 if not run.returncode and result.get('ok') else 1)
