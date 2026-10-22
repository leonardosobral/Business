"""Exercise the real manager action and unchanged DEV receiver in an isolated CF app."""
import datetime,hashlib,json,pathlib,shlex,subprocess,sys

ROOT=pathlib.Path(__file__).resolve().parents[2]
REMOTE=r"""
import hashlib,json,os,pathlib,re,secrets,subprocess,sys,tempfile
payload=json.load(sys.stdin);root=pathlib.Path('/var/www/business.roadrunners.run')
published=payload.pop('published_hashes',{})
for path,expected_hash in published.items():
 if hashlib.sha256(pathlib.Path(path).read_bytes()).hexdigest()!=expected_hash:raise RuntimeError('Published runtime changed: '+path)
name='dev_login_test_'+secrets.token_hex(8);stage=root/'_codex'/name
archive=pathlib.Path(tempfile.mkdtemp(prefix='business-dev-login-tests-',dir='/var/backups'));os.chmod(archive,0o700)
nonce=secrets.token_hex(24);result={'ok':False}
try:
 stage.mkdir(mode=0o755);(stage/'services').mkdir(mode=0o755)
 (stage/'.htaccess').write_text('Require local\n')
 (stage/'Application.cfc').write_text('component {this.name="'+name+'";this.datasource="runner_dba";this.sessionManagement=true;this.setClientCookies=false;}')
 source=payload.pop('backend')
 payload['manager-backend.cfm']=source
 functions=source[source.index('<cfscript>')+10:source.index('</cfscript>')]
 start=functions.index('function userManagerAudit(');end=functions.index('function userManagerMutationAccess(',start)
 functions=functions[:start]+'function userManagerAudit(required string actionName,required numeric targetUserId,required numeric targetPageId,required struct beforeData,required struct afterData){REQUEST.capturedAudit=duplicate(arguments);}\n'+functions[end:]
 payload['manager-functions.cfm']='<cfscript>'+functions+'</cfscript>'
 action=re.search(r'<cfcase value="logar_como_dev">(.*?)</cfcase>',source,re.S).group(1)
 action=action.replace('<cflocation addtoken="false" url="#VARIABLES.userManagerHandoffUrl#"/>','<cfthrow type="Test.HandoffReady" message="Captured success"/>')
 payload['manager-action.cfm']=action
 dev=(pathlib.Path('/var/www/dev.roadrunners.run')/'Application.cfc').read_text(encoding='utf-8-sig')
 patch=payload.pop('receiver_patch',None)
 dev_baseline=hashlib.sha256(dev.encode()).hexdigest()
 if patch:
  if dev_baseline==patch['baseline'] and dev.count(patch['before'])==1:dev=dev.replace(patch['before'],patch['after'],1)
  elif dev.count(patch['after'])!=1:raise RuntimeError('DEV receiver baseline conflict')
 session_patch=payload.pop('session_patch',None)
 if session_patch and not published:
  if hashlib.sha256(dev.encode()).hexdigest()!=session_patch['baseline']:raise RuntimeError('DEV session baseline conflict')
  for step in session_patch['steps']:
   if dev.count(step['before'])!=1:raise RuntimeError('DEV session patch context changed')
   dev=dev.replace(step['before'],step['after'],1)
 header_patch=payload.pop('header_patch',None)
 header_hash=None
 if header_patch:
  header=pathlib.Path(header_patch['path']).read_text()
  if not published:
   if hashlib.sha256(header.encode()).hexdigest()!=header_patch['baseline'] or header.count(header_patch['before'])!=1:raise RuntimeError('DEV header baseline conflict')
   header=header.replace(header_patch['before'],header_patch['after'],1)
  elif header.count(header_patch['after'])!=1:raise RuntimeError('Published DEV header context changed')
  header_hash=hashlib.sha256(header.encode()).hexdigest()
  payload['header-return.cfm']=header_patch['after'].replace(header_patch['before'],'')
 return_source=pathlib.Path('/var/www/dev.roadrunners.run/includes/backend/backend.cfm').read_text()
 return_hash=hashlib.sha256(return_source.encode()).hexdigest()
 return_patch=payload.pop('return_patch',None)
 if return_patch and not published:
  if return_hash!=return_patch['baseline'] or return_source.count(return_patch['before'])!=1:raise RuntimeError('DEV return baseline conflict')
  return_source=return_source.replace(return_patch['before'],return_patch['after'],1)
 return_start=return_source.index('<cfif isDefined("URL.action") AND URL.action EQ "dev_auth_back">')
 return_end=return_source.index('<cfif isDefined("URL.action") AND URL.action EQ "dev_auth"',return_start)
 return_code=return_source[return_start:return_end]
 return_code=re.sub(r'<cfquery name="qDevAuthBackPerfil".*?</cfquery>','<cfset qDevAuthBackPerfil=queryNew("id,name,email,imagem_usuario,is_admin,is_dev,tag","integer,varchar,varchar,varchar,bit,bit,varchar",[{id=VARIABLES.actor.id,name="Admin",email="admin@example.test",imagem_usuario="/assets/user.png",is_admin=VARIABLES.actor.is_admin,is_dev=VARIABLES.actor.is_dev,tag="admin"}])/>',return_code,flags=re.S)
 return_code=re.sub(r'<cflocation addtoken="false" url="([^"]*)"\s*/>',r'<cfset VARIABLES.capturedRedirect="\1"/><cfthrow type="Test.Redirect" message="Captured return"/>',return_code)
 payload['return-state.cfm']=return_code
 methods=[]
 for method in ['validateHandoffToken','processEnvironmentHandoff','seedDevAuthSession','normalizeLocalRedirectPath','buildRequestUsuario','buildEmptyUsuario']:
  match=re.search(r'<cffunction name="'+method+r'".*?</cffunction>',dev,re.S)
  if not match:raise RuntimeError('Required DEV method not found')
  methods.append(match.group())
 receiver='\n'.join(methods)
 receiver=re.sub(r'<cflocation addtoken="false" url="([^"]*)"\s*/>',r'<cfset VARIABLES.capturedRedirect="\1"/><cfthrow type="Test.Redirect" message="Captured redirect"/>',receiver)
 payload['ReceiverFixture.cfc']='''<cfcomponent output="false">'''+receiver+'''<cfscript>
 public struct function validate(required string token,required string target){return validateHandoffToken(arguments.token,arguments.target);}
 public query function getUsuarioCoreById(required numeric id){return queryNew("id,is_admin,is_dev,email,gestao_ativo,gestao_excluido,has_active_page","integer,bit,bit,varchar,bit,bit,bit",[arguments.id==variables.actor.id?variables.actor:variables.target]);}
 public query function getUsuarioCoreByEmail(required string email){var other=duplicate(variables.target);other.id=900003;return queryNew("id,is_admin,is_dev,email,gestao_ativo,gestao_excluido,has_active_page","integer,bit,bit,varchar,bit,bit,bit",[other]);}
 public void function setAuthCookiesFromUsuarioRow(required struct row){variables.loggedIn=duplicate(arguments.row);}
 public string function getCurrentEnvironment(){return REQUEST.currentEnvironment;}
 public boolean function isUserManagementSessionActive(required numeric id){return true;}
 public struct function resolveIdentity(required numeric cookieId,required string environment){
 COOKIE.id=arguments.cookieId;REQUEST.currentEnvironment=arguments.environment;SESSION.UsuarioCache={};
 var resolved=buildRequestUsuario();return {id=resolved.id,is_admin=resolved.is_admin};
 }
 public void function logQueryDebug(){ }
 public struct function returnToAdmin(required numeric conflictingCookie){
 REQUEST.currentEnvironment="dev";URL.action="dev_auth_back";VARIABLES.authCookieDomain="business.roadrunners.run";VARIABLES.qDevAuthBackPerfilMeta={};
 try{include "return-state.cfm";}catch(Test.Redirect returned){}
 COOKIE.id=arguments.conflictingCookie;SESSION.UsuarioCache={};
 var user=buildRequestUsuario();return {id=user.id,origin=SESSION.devAuth.origin?:"",impersonating=SESSION.devAuth.isImpersonating};
 }
 public struct function consume(required string token,required string environment,required struct actor,required struct target){
 variables.actor=arguments.actor;variables.actor.email="admin@example.test";variables.target=arguments.target;
 variables.loggedIn={id=0,is_admin=false};variables.capturedRedirect="";structDelete(SESSION,"devAuth");
 REQUEST.currentEnvironment=arguments.environment;URL.action="handoff_consume";URL.token=arguments.token;
 try{processEnvironmentHandoff();}catch(Test.Redirect redirect){}
 return {redirect=variables.capturedRedirect,loggedInId=variables.loggedIn.id,loggedInAdmin=variables.loggedIn.is_admin,
 devAuth=structKeyExists(SESSION,"devAuth")?duplicate(SESSION.devAuth):{}};
 }
 </cfscript></cfcomponent>'''
 for relative,content in payload.items():
  content=content.replace('new services.','new _codex.'+name+'.services.').replace('new ReceiverFixture()','new _codex.'+name+'.ReceiverFixture()')
  content=content.replace('"includes.models.Usuario"','"_codex.'+name+'.includes.models.Usuario"')
  (stage/relative).parent.mkdir(parents=True,exist_ok=True)
  (stage/relative).write_text(content,encoding='utf-8-sig');os.chmod(stage/relative,0o644)
 gate='''<cfsetting showdebugoutput="false" requesttimeout="45"><cfscript>
 if(!listFind("127.0.0.1,::1",CGI.remote_addr)||!structKeyExists(CGI,"http_x_dev_login_test")||CGI.http_x_dev_login_test!="'''+nonce+'''"){cfheader(statuscode=404);abort;}
 cfheader(name="Cache-Control",value="no-store");cfcontent(type="application/json; charset=utf-8",reset=true);
 try{include "native.cfm";}catch(any failure){writeOutput(serializeJSON({ok=false,type=failure.type,message=failure.message,detail=left(failure.detail?:"",400)}));}
 </cfscript>'''
 (stage/'run.cfm').write_text(gate);os.chmod(stage/'run.cfm',0o644)
 proc=subprocess.run(['curl','--silent','--show-error','--max-time','50','--request','POST','--resolve','business.roadrunners.run:443:127.0.0.1','--header','X-Dev-Login-Test: '+nonce,'https://business.roadrunners.run/_codex/'+name+'/run.cfm'],capture_output=True,timeout=55)
 raw=proc.stdout.decode(errors='replace');(archive/'result.txt').write_text(raw);os.chmod(archive/'result.txt',0o600)
 try:result={key.lower():value for key,value in json.loads(raw).items()}
 except Exception:result={'ok':False,'error':'Unexpected native output; inspect private archive'}
 result['dev_receiver_sha256']=hashlib.sha256(dev.encode()).hexdigest()
 result['dev_receiver_baseline']=dev_baseline
 result['dev_header_sha256']=header_hash
 result['dev_return_sha256']=hashlib.sha256(return_source.encode()).hexdigest()
 result['dev_return_baseline']=return_hash
 render_gate=gate[:gate.index(' try{include "native.cfm";')]+'''
 try {
 structClear(FORM);qPerfil=queryExecute("SELECT id,is_admin,is_dev FROM tb_usuarios WHERE coalesce(is_admin,false)=true ORDER BY id LIMIT 1",{},{datasource="runner_dba"});
 URL.user_id=listFind("detail,dev-detail",URL.render_case)?qPerfil.id:0;
 include "manager-backend.cfm";
 if(listFind("dev-list,dev-detail",URL.render_case)) VARIABLES.userManagerActorIsAdmin=false;
 savecontent variable="rendered" {include "home.cfm";}
 count=arrayLen(reMatchNoCase('<form[^>]*data-dev-login\\b',rendered));
 expected=listFind("dev-list,dev-detail",URL.render_case)?0:(URL.render_case=="detail"?1:qUserManagerUsers.recordCount);
 writeOutput(serializeJSON({ok=count==expected,buttons=count,expected=expected}));
 }catch(any failure){writeOutput(serializeJSON({ok=false,type=failure.type,message=failure.message}));}
 </cfscript>'''
 (stage/'render.cfm').write_text(render_gate);os.chmod(stage/'render.cfm',0o644)
 result['render_checks']=[]
 for case in ['list','detail','dev-list','dev-detail']:
  render=subprocess.run(['curl','--silent','--show-error','--max-time','30','--resolve','business.roadrunners.run:443:127.0.0.1','--header','X-Dev-Login-Test: '+nonce,'https://business.roadrunners.run/_codex/'+name+'/render.cfm?render_case='+case],capture_output=True,timeout=35)
  (archive/('render-'+case+'.txt')).write_bytes(render.stdout);os.chmod(archive/('render-'+case+'.txt'),0o600)
  try:render_result={key.lower():value for key,value in json.loads(render.stdout).items()}
  except Exception:render_result={'ok':False,'error':'Unexpected render output'}
  result['render_checks'].append({'case':case,**render_result});result['ok']=result.get('ok',False) and render_result.get('ok',False)
finally:
 if stage.exists():stage.rename(archive/'fixture')
 result['archive']=str(archive);result['stage_removed']=not stage.exists()
print(json.dumps(result))
"""
payload={'backend':(ROOT/'administracao/usuarios/includes/backend.cfm').read_text(),'native.cfm':(ROOT/'_codex/tests/dev-login/native.cfm').read_text(),
    'home.cfm':(ROOT/'administracao/usuarios/home.cfm').read_text()}
if '--published' in sys.argv:
    deployment=json.loads((ROOT/'_codex/deploy/dev-login-session-20261021.json').read_text())
    payload['published_hashes']={entry['path']:entry['after'] for entry in deployment['files'].values()}
for include in (ROOT/'administracao/usuarios/includes').glob('*.cfm'):
    if include.name!='backend.cfm':payload['includes/'+include.name]=include.read_text()
service=ROOT/'services/BusinessDevLogin.cfc'
if service.exists():payload['services/BusinessDevLogin.cfc']=service.read_text()
patch=ROOT/'_codex/patches/dev-login-receiver-identity.json'
if patch.exists():payload['receiver_patch']=json.loads(patch.read_text())
session_patch=ROOT/'_codex/patches/dev-login-session-identity.json'
if session_patch.exists():payload['session_patch']=json.loads(session_patch.read_text())
header_patch=ROOT/'_codex/patches/dev-login-return-header.json'
if header_patch.exists():payload['header_patch']=json.loads(header_patch.read_text())
return_patch=ROOT/'_codex/patches/dev-login-return-state.json'
if return_patch.exists() and '--baseline-return' not in sys.argv:payload['return_patch']=json.loads(return_patch.read_text())
payload['includes/models/Usuario.cfc']=(ROOT.parent/'RoadRunners/includes/models/Usuario.cfc').read_text()
proc=subprocess.run(['ssh','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-o','ConnectTimeout=12','rr-prod','python3 -c '+shlex.quote(REMOTE)],input=json.dumps(payload).encode(),capture_output=True,timeout=150)
try:result=json.loads(proc.stdout)
except Exception:result={'ok':False,'error':'Native transport failed; output suppressed'}
if '--save-evidence' in sys.argv:
    result['checked_at']=datetime.datetime.now(datetime.timezone.utc).isoformat()
    result['files']={name:hashlib.sha256((ROOT/name).read_bytes()).hexdigest() for name in ['administracao/usuarios/includes/backend.cfm','administracao/usuarios/home.cfm','services/BusinessDevLogin.cfc']}
    (ROOT/'_codex/deploy/dev-login-tests-20261021.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
print(json.dumps(result,ensure_ascii=False))
if not result.get('ok'):sys.exit(1)
