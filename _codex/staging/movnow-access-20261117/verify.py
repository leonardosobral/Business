from pathlib import Path
import base64,json,subprocess,sys
root=Path.cwd();stage=root/'_codex/staging/movnow-access-20261117'
names=[str(p.relative_to(stage/'baseline')) for p in (stage/'baseline').rglob('*') if p.is_file()]+['includes/backend/business_internal_privileges.cfm']
payload={p:(root/p).read_text() for p in names}
remote=r"""
from pathlib import Path
import base64,json,os,tempfile,subprocess,shutil,secrets,signal
root=Path('/var/www/business.roadrunners.run');payload=json.loads(base64.b64decode(PAYLOAD));published=PUBLISHED
work=Path(tempfile.mkdtemp(prefix='movnow-access-check-20261117-',dir=root/'_codex'));os.chmod(work,0o755)
def interrupted(s,f):raise RuntimeError('Interrupted')
signal.signal(signal.SIGTERM,interrupted);signal.signal(signal.SIGHUP,interrupted)
key=secrets.token_hex(24);results=[]
def put(name,source):
 p=work/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(source)
try:
 put('.htaccess','Require local\n')
 put('Application.cfc','component {this.name="'+work.name+'";this.datasource="runner_dba";this.sessionManagement=true;this.mappings["/services"]="'+str(root/'services')+'";boolean function onRequestStart(string target){if(!listFind("127.0.0.1,::1",cgi.remote_addr)||compare(cgi.http_x_codex_test_key ?: "","'+key+'")!=0){cfheader(statuscode=404);abort;}cfsetting(showdebugoutput=false);return true;}void function onRequest(required string target) output=true {transaction {queryExecute("SET TRANSACTION READ ONLY",{},{datasource="runner_dba"});include "bootstrap.cfm";include arguments.target;}}}')
 for p,s in payload.items():put(p,(root/p).read_text() if published else s)
 for p in ['includes/backend/agenda_service.cfm','includes/backend/require_catarinense_challenge_access.cfm','includes/backend/require_brasil_gigante_challenge_access.cfm','teams/index.cfm','teams/includes/header.cfm','teams/includes/footer.cfm','teams/includes/login.cfm']:
  put(p,(root/p).read_text())
 put('bootstrap.cfm', '''<cfparam name="URL.profile" default="owner"><cfparam name="URL.mode" default="direct"><cfparam name="URL.account" default="25">
<cfset uid=URL.profile EQ 'admin' ? 139 : (URL.profile EQ 'partner' ? 116141 : 136808)>
<cfquery name="qPerfil">SELECT id,is_admin,is_dev,is_partner FROM tb_usuarios WHERE id=<cfqueryparam value="#uid#" cfsqltype="cf_sql_integer"></cfquery>
<cfif URL.profile EQ 'partner'><cfset querySetCell(qPerfil,'is_partner',true)></cfif>
<cfif URL.profile EQ 'dev'><cfset querySetCell(qPerfil,'is_dev',true)></cfif>
<cfset REQUEST.businessIdentity={id=uid}><cfset VARIABLES.businessAccountSimulationActive=URL.mode EQ 'simulation'><cfset VARIABLES.businessEffectiveIsAdmin=URL.profile EQ 'admin' AND URL.mode EQ 'direct'><cfset VARIABLES.businessEffectiveAccountOperatorIds=URL.profile EQ 'viewer' OR URL.mode EQ 'delegated' ? '0' : URL.account>
<cfset structClear(SESSION)>
<cfif URL.mode EQ 'simulation'><cfset SESSION.businessSimulatedAccountId=val(URL.account)><cfset SESSION.businessAccessSelection={accessMode='INTERNAL_SIMULATION'}><cfelseif URL.mode EQ 'delegated'><cfset REQUEST.businessAccessContext={accessMode='DELEGATED'}><cfelseif URL.mode EQ 'canonical'><cfset SESSION.businessAccessSelection={accessMode='INTERNAL_SIMULATION'}><cfelseif URL.mode EQ 'invalid'><cfset SESSION.businessAccessSelectionInvalid=true></cfif>''')
 put('agenda.cfm','<cfinclude template="includes/backend/require_admin_dev_partner.cfm"><cfoutput>AGENDA_ALLOWED</cfoutput>')
 put('backend.cfm','<cfinclude template="portal/includes/agenda_management_backend.cfm"><cfoutput>#serializeJSON({write=VARIABLES.agendaManagementCanWrite,all=VARIABLES.agendaManagementCanManageAll,count=qAgendaManagementList.recordCount,owners=valueList(qAgendaManagementList.id_usuario)})#</cfoutput>')
 put('challenge.cfm','<cfif URL.account EQ "13"><cfinclude template="includes/backend/require_brasil_gigante_challenge_access.cfm"><cfelse><cfinclude template="includes/backend/require_catarinense_challenge_access.cfm"></cfif><cfoutput>CHALLENGE_ALLOWED</cfoutput>')
 def check(path,profile,mode,status,needle='',post=False,account=25):
  url='https://business.roadrunners.run/_codex/'+work.name+'/'+path+('&' if '?' in path else '?')+'profile='+profile+'&mode='+mode+'&account='+str(account)
  cmd=['curl','-sS','--max-time','25','--resolve','business.roadrunners.run:443:127.0.0.1','-H','X-Codex-Test-Key: '+key,'-w','\nHTTP:%{http_code}',url]
  if post:cmd+=['--data','operation=save&acao=alterar_status&agenda_id=2&status=pausada']
  r=subprocess.run(cmd,capture_output=True,text=True,timeout=30);assert r.returncode==0,r.stderr
  body,code=r.stdout.rsplit('\nHTTP:',1)
  assert int(code)==status and (not needle or needle in body),(path,profile,mode,code,body[-1800:])
  if path.startswith('teams/') and mode!='direct':assert 'Ficha cadastral' not in body and 'name="csrf"' not in body
  results.append(dict(route=path,profile=profile,mode=mode,method='POST' if post else 'GET',status=int(code)))
  return body
 for mode in ['simulation','canonical','delegated','invalid']:
  check('agenda.cfm','admin',mode,403)
  check('challenge.cfm','admin',mode,403)
  check('teams/index.cfm?team=1','admin',mode,200,'Teams são vinculados')
  check('teams/index.cfm?team=1','admin',mode,403,post=True)
 check('agenda.cfm','admin','simulation',403,post=True)
 for profile in ['admin','dev','partner']:check('agenda.cfm',profile,'direct',200,'AGENDA_ALLOWED')
 check('agenda.cfm','owner','direct',403)
 for profile,mode,account,status in [('admin','direct',25,200),('owner','direct',25,403),('owner','direct',12,200),('viewer','direct',12,403),('owner','direct',13,200),('viewer','direct',13,403),('admin','simulation',12,200),('admin','simulation',13,200)]:check('challenge.cfm',profile,mode,status,account=account)
 for profile,mode,count,allowners in [('admin','simulation',0,False),('owner','direct',0,False),('partner','direct',1,False),('admin','direct',2,True)]:
  data=json.loads(check('backend.cfm',profile,mode,200));data={k.lower():v for k,v in data.items()};assert data['count']==count and bool(data['all'])==allowners,data
  if profile=='partner':assert data['owners']=='116141',data
 check('backend.cfm','admin','simulation',200,post=True)
 check('teams/index.cfm','owner','direct',200,'Nenhum Team encontrado')
 check('teams/index.cfm','admin','direct',303)
finally:
 shutil.rmtree(work);assert not work.exists()
print(json.dumps({'published':published,'passed':len(results),'cases':results,'fixture_removed':True}))
"""
remote=remote.replace('PAYLOAD',repr(base64.b64encode(json.dumps(payload).encode()).decode())).replace('PUBLISHED',str('--published' in sys.argv))
r=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -'],input=remote,text=True,capture_output=True,timeout=240)
if r.returncode:raise RuntimeError(r.stderr)
result=json.loads(r.stdout);(stage/('verified-published.json' if '--published' in sys.argv else 'verified-candidate.json')).write_text(json.dumps(result,indent=2))
print(json.dumps(result))
