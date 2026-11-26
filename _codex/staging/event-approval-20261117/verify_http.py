from pathlib import Path
import base64, json, subprocess

root = Path.cwd()
stage = root / '_codex/staging/event-approval-20261117'
payload = {v: {n: (stage / 'baseline' / n if v == 'before' else root / n).read_text()
               for n in ['eventos/index.cfm', 'eventos/home.cfm']} for v in ['before', 'after']}
remote = r'''
from pathlib import Path
import os,json,base64,tempfile,shutil,subprocess,secrets,signal,hashlib
payload=json.loads(base64.b64decode(PAYLOAD))
def interrupted(s,f):raise RuntimeError('Interrupted')
signal.signal(signal.SIGTERM,interrupted);signal.signal(signal.SIGHUP,interrupted)
work=Path(tempfile.mkdtemp(prefix='event-redirect-test-20261117-',dir='/var/www/business.roadrunners.run/_codex'));os.chmod(work,0o755)
token=secrets.token_hex(24)
results=[]
try:
 (work/'.htaccess').write_text('Require local\n')
 (work/'Application.cfc').write_text('component output=true {this.datasource="runner_dba";this.sessionManagement=true;this.mappings["/services"]="/var/www/business.roadrunners.run/services";this.name="'+work.name+'";boolean function onRequestStart(string target){if(!listFind("127.0.0.1,::1",cgi.remote_addr)||compare(cgi.http_x_codex_test_key ?: "","'+token+'")!=0){cfheader(statuscode=404);abort;}cfsetting(showdebugoutput=false,enablecfoutputonly=false);return true;}void function onRequest(required string target) output=true {include arguments.target;}}')
 handler='<cfif structKeyExists(FORM,"evento_solicitacao_action")><cfif FORM.evento_solicitacao_action EQ "forbidden"><cfthrow type="BusinessDelegation.Forbidden" message="Fixture"/><cfelseif FORM.evento_solicitacao_action EQ "invalid"><cfthrow type="BusinessDelegation.Validation" message="Fixture"/><cfelse><cfset targetState=FORM.evento_solicitacao_action EQ "aprovar" ? "aprovada" : (FORM.evento_solicitacao_action EQ "negar" ? "negada" : "pedido")/><cflocation addtoken="false" url="/eventos/?solicitacao=#targetState#"/></cfif></cfif>'
 for version,files in payload.items():
  for name,source in files.items():
   if name.endswith('/home.cfm'):source=source.split('<!--- FILTROS --->')[0]+'<p>EVENTS_RENDER_COMPLETE</p>'
   target=work/version/name;target.parent.mkdir(parents=True,exist_ok=True);target.write_text(source)
  stubs={'includes/backend/backend_login.cfm':'<cfset REQUEST.businessIdentity={id=139}/><cfset SESSION.businessSimulatedAccountId=25/><cfinclude template="/includes/backend/backend_login.cfm"/>','eventos/includes/variaveis.cfm':'<cfinclude template="/eventos/includes/variaveis.cfm"/>','eventos/includes/backend/backend_evento_edicao.cfm':'','eventos/includes/backend/backend_evento_solicitacoes.cfm':handler,'eventos/includes/backend/backend.cfm':'','includes/estrutura/head.cfm':'<head><title>Redirect regression</title></head>','includes/estrutura/header.cfm':'<cfinclude template="/includes/estrutura/header.cfm"/>','includes/estrutura/pending_workspace_return.cfm':'','includes/estrutura/footer.cfm':'<footer>PAGE_COMPLETE</footer>'}
  for name,source in stubs.items():
   target=work/version/name;target.parent.mkdir(parents=True,exist_ok=True);target.write_text(source)
  for action in ['', 'aprovar','negar','solicitar','forbidden','invalid']:
   url='https://business.roadrunners.run/_codex/'+work.name+'/'+version+'/eventos/index.cfm'
   cmd=['curl','--compressed','-sS','--max-time','30','--resolve','business.roadrunners.run:443:127.0.0.1','-H','X-Codex-Test-Key: '+token,'-w','\nHTTP:%{http_code}\nREDIRECT:%{redirect_url}',url]
   if action:cmd+=['--data-urlencode','evento_solicitacao_action='+action]
   r=subprocess.run(cmd,capture_output=True,text=True,timeout=35);assert r.returncode==0,r.stderr
   body,meta=r.stdout.rsplit('\nHTTP:',1);code,redirect=meta.split('\nREDIRECT:',1)
   row={'version':version,'action':action or 'GET','status':int(code),'redirect':redirect,'body_bytes':len(body.encode()),'complete':'PAGE_COMPLETE' in body,'access_error':'Reabra o evento' in body,'tail':body[-400:] if int(code)>=500 else ''};results.append(row)
 for r in results:
  if r['action']=='GET':assert r['status']==200 and r['complete'],r
  elif r['version']=='after':
   if r['action'] in ['aprovar','negar','solicitar']:assert r['status']==302 and '/eventos/?solicitacao=' in r['redirect'] and not r['complete'],r
   else:assert r['status']==(403 if r['action']=='forbidden' else 400) and r['access_error'],r
  elif r['action'] in ['aprovar','negar','solicitar']:assert r['status']==200 and not r['redirect'] and not r['complete'],r
finally:
 shutil.rmtree(work);assert not work.exists()
print(json.dumps({'cases':results,'temporary_fixture_removed':True}))
'''
remote = remote.replace('PAYLOAD', repr(base64.b64encode(json.dumps(payload).encode()).decode()))
r = subprocess.run(['ssh', '-o', 'BatchMode=yes', '-o', 'ConnectTimeout=10', '-o', 'StrictHostKeyChecking=yes', '-i', '/Users/leonardosobral/.ssh/webs', 'root@ssh.runnerhub.run', 'python3 -'], input=remote, capture_output=True, text=True, timeout=120)
if r.returncode:
    raise RuntimeError(r.stderr)
result = json.loads(r.stdout)
(stage / 'http-regression.json').write_text(json.dumps(result, ensure_ascii=False, indent=2))
print(json.dumps(result, ensure_ascii=False))
