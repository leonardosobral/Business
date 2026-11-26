from pathlib import Path
import base64,json,subprocess,sys
root=Path.cwd();stage=root/'_codex/staging/business-support-20261117'
names=[str(p.relative_to(stage/'baseline')) for p in (stage/'baseline').rglob('*') if p.is_file()]+['services/BusinessSupportSession.cfc','includes/backend/business_support_request.cfm','includes/estrutura/business_support_banner.cfm','suporte/acesso/index.cfm']
payload={p:(root/p).read_text() for p in names};payload['unit.cfm']=(stage/'unit.cfm').read_text()
remote=r'''
from pathlib import Path
import base64,json,os,tempfile,shutil,subprocess,secrets,signal,re,html
root=Path('/var/www/business.roadrunners.run');payload=json.loads(base64.b64decode(PAYLOAD));published=PUBLISHED
work=Path(tempfile.mkdtemp(prefix='business-support-check-20261117-',dir=root/'_codex'));os.chmod(work,0o755);key=secrets.token_hex(24)
def interrupted(s,f):raise RuntimeError('Interrupted')
signal.signal(signal.SIGTERM,interrupted);signal.signal(signal.SIGHUP,interrupted)
def put(name,content):
 p=work/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(content)
def request(path,form=None):
 cmd=['curl','-sS','--max-time','30','--resolve','business.roadrunners.run:443:127.0.0.1','-H','X-Codex-Test-Key: '+key,'-c',str(work/'cookies'),'-b',str(work/'cookies'),'-w','\nHTTP:%{http_code}', 'https://business.roadrunners.run/_codex/'+work.name+'/'+path]
 if form is not None:
  for k,v in form.items():cmd+=['--data-urlencode',k+'='+str(v)]
 r=subprocess.run(cmd,text=True,capture_output=True,timeout=35);assert r.returncode==0,r.stderr
 body,code=r.stdout.rsplit('\nHTTP:',1);return int(code),body
try:
 put('.htaccess','Require local\n')
 shutil.copytree(root/'includes/backend',work/'includes/backend',dirs_exist_ok=True)
 shutil.copytree(root/'teams',work/'teams',dirs_exist_ok=True)
 for p,s in payload.items():put(p,(root/p).read_text() if published and p!='unit.cfm' else s)
 # Other components use the same published implementation. Only this task's component is overridden.
 for p in (root/'services').iterdir():
  if not (work/'services'/p.name).exists():(work/'services'/p.name).symlink_to(p,target_is_directory=p.is_dir())
 put('Application.cfc','component {this.name="'+work.name+'";this.datasource="runner_dba";this.sessionManagement=true;this.mappings["/services"]="'+str(work/'services')+'";boolean function onRequestStart(string target){if(!listFind("127.0.0.1,::1",cgi.remote_addr)||compare(cgi.http_x_codex_test_key ?: "","'+key+'")!=0){cfheader(statuscode=404);abort;}cfsetting(showdebugoutput=false);return true;}void function onRequest(required string target) output=true {include arguments.target;}}')
 status,body=request('unit.cfm');assert status==200,(status,body[-3500:]);unit=json.loads(body)
 # Full identity pipeline, shared login, and actual Teams page. Every request's
 # database writes are rolled back; the isolated CF session remains for HTTP transitions.
 for p in (work/'includes/backend').glob('*.cfm'):
  p.write_text(p.read_text().replace('"runnerhub"','"runner_dba"'))
 support_path='/_codex/'+work.name+'/suporte/acesso/index.cfm'
 p=work/'includes/backend/business_delegation_request.cfm'
 p.write_text(p.read_text().replace('CGI.script_name EQ "/suporte/acesso/index.cfm"','CGI.script_name EQ "'+support_path+'"'))
 put('bootstrap.cfm', '<cfscript>structClear(SESSION);new services.BusinessAuthSession().establish(SESSION,139,{sub="isolated-test",email="operator@example.org",name="Operator",picture=""});SESSION.businessRememberCheckedAt=now();writeOutput("BOOTSTRAPPED");</cfscript>')
 put('who.cfm','<cfinclude template="includes/backend/backend_login.cfm"><cfoutput>#serializeJSON({identity=REQUEST.businessIdentity.id,operator=REQUEST.businessAuthenticatedActor.id,delegation=REQUEST.businessDelegationIdentity.id,profile=qPerfil.id,admin=qPerfil.is_admin,effectiveAdmin=VARIABLES.businessEffectiveIsAdmin,account=VARIABLES.businessActiveAccountId,simulation=VARIABLES.businessAccountSimulationActive,rememberUser=new services.BusinessAuthSession().identity(SESSION).id})#</cfoutput>')
 put('admin.cfm','<cfinclude template="includes/backend/backend_login.cfm"><cfinclude template="includes/backend/require_admin.cfm"><cfoutput>ADMIN_ALLOWED</cfoutput>')
 put('expire.cfm','<cfset SESSION.businessSupportSession.expiresAt=dateAdd("s",-1,now())><cfoutput>EXPIRED</cfoutput>')
 put('effect.cfm','<cfoutput>SHOULD_NOT_EXECUTE</cfoutput>')
 put('Application.cfc','component {this.name="'+work.name+'";this.datasource="runner_dba";this.sessionManagement=true;this.mappings["/services"]="'+str(work/'services')+'";boolean function onRequestStart(string target){if(!listFind("127.0.0.1,::1",cgi.remote_addr)||compare(cgi.http_x_codex_test_key ?: "","'+key+'")!=0){cfheader(statuscode=404);abort;}cfsetting(showdebugoutput=false);APPLICATION.businessAccountDelegationEnabled=true;return true;}void function onRequest(required string target) output=true {transaction {try {if(!find("bootstrap.cfm",arguments.target)){REQUEST.businessTargetPath=replace(arguments.target,"/_codex/'+work.name+'","");include "includes/backend/business_request_identity.cfm";include "includes/backend/business_delegation_request.cfm";}include arguments.target;}finally {transaction action="rollback";}}}}')
 cases=[]
 def ok(path,status,needle='',form=None):
  code,body=request(path,form);assert code==status and (not needle or needle in html.unescape(body)),(path,code,re.sub(r'value="[a-f0-9]{64}"', 'value="[redacted]"',body[-2500:]));cases.append({'path':path,'status':code,'method':'POST' if form is not None else 'GET'});return body
 def fields(body):return {k:html.unescape(v) for k,v in re.findall(r'<input[^>]*name="([^"]+)"[^>]*value="([^"]*)"',body)}
 ok('bootstrap.cfm',200,'BOOTSTRAPPED')
 confirmation=ok('suporte/acesso/index.cfm?user_id=136808',200,'Inscrições Movnow')
 start=fields(confirmation);start['confirmed']='1'
 ok('suporte/acesso/index.cfm',403,form={**start,'csrf':'bad'})
 ok('suporte/acesso/index.cfm',303,form=start)
 who=json.loads(ok('who.cfm',200));who={k.lower():v for k,v in who.items()};assert who['identity']==136808 and who['profile']==136808 and who['delegation']==136808 and who['operator']==139 and who['rememberuser']==139 and not who['admin'] and not who['effectiveadmin'] and not who['simulation'] and str(who['account'])=='25',who
 ok('admin.cfm',403)
 teams=ok('teams/index.cfm',200,'Nenhum Team encontrado');assert 'Você está acessando como' in teams and 'Inscrições Movnow' in html.unescape(teams) and 'encerre a simulação' not in teams
 stop=fields(teams);stop={k:v for k,v in stop.items() if k in ('action','csrf')};assert stop.get('action')=='stop',stop
 ok('suporte/acesso/index.cfm',403,form={**stop,'csrf':'bad'})
 ok('suporte/acesso/index.cfm',403,form=start)
 ok('suporte/acesso/index.cfm',303,form=stop)
 restored=json.loads(ok('who.cfm',200));assert restored['IDENTITY']==139 and restored['ADMIN'],restored
 ok('suporte/acesso/index.cfm',403,form=stop)
 start=fields(ok('suporte/acesso/index.cfm?user_id=136808',200));start['confirmed']='1';ok('suporte/acesso/index.cfm',303,form=start)
 ok('expire.cfm',200,'EXPIRED')
 body=ok('effect.cfm',409,'Nenhuma ação',form={'action':'save'});assert 'SHOULD_NOT_EXECUTE' not in body
 restored=json.loads(ok('who.cfm',200));assert restored['IDENTITY']==139
 print(json.dumps({'published':published,'unit':unit,'http':cases,'effectiveIdentity':who,'fixture_removed':True}))
finally:
 shutil.rmtree(work);assert not work.exists()
'''.replace('PAYLOAD',repr(base64.b64encode(json.dumps(payload).encode()).decode())).replace('PUBLISHED',str('--published' in sys.argv))
r=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -'],input=remote,capture_output=True,text=True,timeout=120)
if r.returncode:raise RuntimeError(r.stderr)
print(r.stdout)
(stage/('verified-published.json' if '--published' in sys.argv else 'verified-candidate.json')).write_text(r.stdout)
