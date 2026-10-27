"""Localhost-only, private CF fixtures. No public replies, notifications or DDL."""
import ast,json,pathlib,shlex,subprocess,sys
ROOT=pathlib.Path(__file__).resolve().parents[2];mode=sys.argv[1] if len(sys.argv)>1 else 'notes'
tree=ast.parse((ROOT/'_codex/scripts/test_user_acquisition_native.py').read_text())
remote=next(ast.literal_eval(n.value) for n in tree.body if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='REMOTE' for t in n.targets))
remote=remote.replace('user_acquisition_','helpdesk_tools_').replace('business-user-acquisition-test-','business-helpdesk-tools-test-').replace('USER_ACQUISITION_','HELPDESK_TOOLS_')
remote=remote.replace("body=body.replace('new services.UserAcquisitionMetrics','new _codex.'+name+'.services.UserAcquisitionMetrics')", "body=body.replace('helpdesk.includes.','_codex.'+name+'.helpdesk.includes.').replace('__NOTES__','_codex.'+name+'.helpdesk.includes.HelpdeskNotes').replace('__REPLIES__','_codex.'+name+'.helpdesk.includes.HelpdeskReplies')")
remote=remote.replace("wrapper='<cfsetting", "os.chown(stage/'tests', __import__('pwd').getpwnam('coldfusion').pw_uid, -1)\n wrapper='<cfsetting")
if mode=='guards':
 original=next(line for line in remote.splitlines() if line.startswith(" run=subprocess.run(['curl'"))
 replacement=''' from types import SimpleNamespace
 checks=[]
 cases=[('POST','1','helpdesk_action=nota_ticket',403),('POST','1','helpdesk_action=nota_ticket&helpdesk_csrf=wrong',403),('GET','1','helpdesk_action=nota_ticket&helpdesk_csrf=fixture-only-csrf',403),('POST','0','helpdesk_action=nota_ticket&helpdesk_csrf=fixture-only-csrf',403),('POST','1','helpdesk_action=nota_ticket&helpdesk_csrf=fixture-only-csrf&ticket_id=invalid',200),('POST','1','helpdesk_action=remover_resposta_rapida&helpdesk_csrf=fixture-only-csrf&resposta_id=contexto&respostas_revision=initial',200)]
 for method,admin,body,expected in cases:
  url='https://business.roadrunners.run/_codex/'+name+'/run.cfm?admin='+admin
  if method=='GET':url+='&'+body
  command=['curl','-sS','--max-time','30','--resolve','business.roadrunners.run:443:127.0.0.1','--request',method,'--header','X-Acquisition-Test: '+nonce,'--write-out','\\n%{http_code}',url]
  if method=='POST':command+=['--data',body]
  response=subprocess.run(command,capture_output=True,timeout=35);content,_,status=response.stdout.rpartition(b'\\n');valid=not response.returncode and status==str(expected).encode()
  if expected==200:valid=valid and b'HELPDESK_TOOLS_GUARDS_PASSED' in content
  checks.append({'method':method,'admin':admin,'expected':expected,'status':status.decode(),'ok':valid})
 raw=('HELPDESK_TOOLS_GUARDS_PASSED ' if all(c['ok'] for c in checks) else 'TEST_FAILED ')+json.dumps(checks)
 run=SimpleNamespace(returncode=0,stdout=raw.encode())'''
 remote=remote.replace(original,replacement,1)
payload={'mode':mode}
for p in (ROOT/'helpdesk/includes').glob('*'):
 if p.is_file():payload[str(p.relative_to(ROOT))]=p.read_text()
rr=(ROOT.parent/'RoadRunners/atendimento/index.cfm').read_text()
start=rr.index('<cfquery datasource="runner_dba" name="qChamadoMensagens">')
payload['tests/legacy-messages.cfm']=rr[start:rr.index('</cfquery>',start)+len('</cfquery>')]
for p in (ROOT/'_codex/tests/helpdesk-tools').glob('*.cfm'):payload['tests/'+p.name]=p.read_text()
run=subprocess.run(['ssh','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-o','ConnectTimeout=12','rr-prod','python3 -c '+shlex.quote(remote)],input=json.dumps(payload).encode(),capture_output=True,timeout=65)
try:result=json.loads(run.stdout)
except ValueError:result={'ok':False,'error':run.stderr.decode(errors='replace')[-1000:]}
print(json.dumps(result,ensure_ascii=False));raise SystemExit(0 if not run.returncode and result.get('ok') else 1)
