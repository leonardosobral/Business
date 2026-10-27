"""Staged HTTP/concurrency tests, no publication or real deliveries."""
import json,pathlib,shlex,subprocess,sys
ROOT=pathlib.Path(__file__).resolve().parents[2];mode=sys.argv[1] if len(sys.argv)>1 else 'http';files={}
for parent in ['teams','services/teams']:
 for p in (ROOT/parent).rglob('*'):
  if p.is_file():files['business/'+str(p.relative_to(ROOT))]=p.read_text()
for p in (ROOT/'_codex/teams/roadrunners/teams').rglob('*'):
 if p.is_file():files['rr/teams/'+str(p.relative_to(ROOT/'_codex/teams/roadrunners/teams'))]=p.read_text()
for p in (ROOT/'services/teams').glob('*.cfc'):
 if p.name not in ['Mailer.cfc','EmailTransport.cfc']:files['rr/services/teams/'+p.name]=p.read_text()
for p in (ROOT/'teams/assets').glob('*'):
 if p.is_file():files['rr/teams/assets/'+p.name]=p.read_text()
fixtures={p.name:p.read_text() for p in (ROOT/'_codex/tests/teams').glob('http-*.cfm')};fixtures['concurrent.cfm']=(ROOT/'_codex/tests/teams/concurrent.cfm').read_text()
REMOTE=r"""
import concurrent.futures,json,os,pathlib,re,secrets,subprocess,sys,tempfile,urllib.parse
p=json.load(sys.stdin);mode=p['mode'];nonce=secrets.token_hex(24);name='teams_http_'+secrets.token_hex(8)
roots={'business':pathlib.Path('/var/www/business.roadrunners.run'),'rr':pathlib.Path('/var/www/roadrunners.com.br')};hosts={'business':'business.roadrunners.run','rr':'roadrunners.run'}
archive=pathlib.Path(tempfile.mkdtemp(prefix='rr-teams-http-',dir='/var/backups'));os.chmod(archive,0o700)
paths={s:r/'_codex'/name for s,r in roots.items()};results=[];cleanup=[];secret='fixture-only-teams-worker-'+secrets.token_hex(20);recruit='teams-'+secrets.token_hex(12)+'@example.org'
app=r'''component {
 this.name='__NAME__';this.datasource='runner_dba';this.sessionManagement=true;this.setClientCookies=true;
 function onApplicationStart(){
  var users=queryExecute("SELECT id,email FROM public.tb_usuarios u WHERE NOT coalesce(is_admin,false) AND email IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.tb_usuarios_gestao g WHERE g.id_usuario=u.id AND (NOT coalesce(g.ativo,true) OR coalesce(g.excluido,false))) ORDER BY id LIMIT 4",{},{datasource='runner_dba'});
  var staff=queryExecute("SELECT id FROM public.tb_usuarios u WHERE is_admin=true AND NOT EXISTS(SELECT 1 FROM public.tb_usuarios_gestao g WHERE g.id_usuario=u.id AND (NOT coalesce(g.ativo,true) OR coalesce(g.excluido,false))) ORDER BY id LIMIT 1",{},{datasource='runner_dba'});
  APPLICATION.testActors={owner=users.id[1],athlete=users.id[2],other=users.id[3],viewer=users.id[4],global=staff.id[1]};APPLICATION.testRecruitAddress='__EMAIL__';APPLICATION.cronJobs={runnerToken='__SECRET__'};return true;
 }
 function onRequestStart(string target){
  cfsetting(showdebugoutput=false);
  if(!listFind('127.0.0.1,::1',CGI.remote_addr)||(CGI.http_x_teams_test ?: '')!='__NONCE__'){cfheader(statuscode=404);abort;}
  REQUEST.businessIdentity={};REQUEST.testScenario=CGI.http_x_teams_scenario ?: '';var actor=CGI.http_x_teams_actor ?: '';
  SESSION.businessLoginNonce=repeatString('a',43);SESSION.businessLoginCsrf=repeatString('b',64);
  if(structKeyExists(APPLICATION.testActors,actor))REQUEST.businessIdentity={id=APPLICATION.testActors[actor]};
  if(REQUEST.testScenario=='cookie-only' && !structIsEmpty(REQUEST.businessIdentity)){COOKIE.id=REQUEST.businessIdentity.id;VARIABLES.Usuario={id=REQUEST.businessIdentity.id,logado=true};}
  __PROOF__
  return true;
 }
 function onRequest(string target){
  var special=listLast(arguments.target,'/');
  if(listFind('seed.cfm,clean.cfm,inspect.cfm,concurrent.cfm',special)){include arguments.target;return;}
  transaction{try{include 'http-seed.cfm';include arguments.target;}finally{transaction action='rollback';}}
 }
}'''
proof=r'''if(!structIsEmpty(REQUEST.businessIdentity)&&REQUEST.testScenario!='cookie-only'){
 if(!structKeyExists(APPLICATION,'comparadorIdentityStateV1'))APPLICATION.comparadorIdentityStateV1={};
 var protocol=createObject('component','services.ComparadorIdentityProtocol').init(APPLICATION.comparadorIdentityStateV1);
 var identity=createObject('component','services.ComparadorIdentityAccounts').init('runner_dba').byId(REQUEST.businessIdentity.id);
 var binding=protocol.randomToken();identity.sessionId=protocol.randomToken();identity.browserBinding=protocol.digest(binding);protocol.rememberBrowser(binding,identity,dateAdd('h',1,now()));COOKIE['__Host-rr-comparador-identity']=binding;
}'''
def request(site,path,actor='',body=None,scenario='',auth=False,jar=True):
 host=hosts[site];args=['curl','-sS','--max-time','45','--resolve',host+':443:127.0.0.1','-H','X-Teams-Test: '+nonce,'-H','X-Teams-Actor: '+actor,'-H','X-Teams-Scenario: '+scenario,'-w','\n%{http_code}','https://'+host+'/_codex/'+name+'/'+path]
 if jar:args+=['-b',str(archive/(site+'-'+actor+'.cookies')),'-c',str(archive/(site+'-'+actor+'.cookies'))]
 if auth:args+=['-H','Authorization: Bearer '+secret,'-H','Content-Type: application/json']
 if body is not None:
  if body.startswith(('{','[')):args+=['-H','Content-Type: application/json']
  args+=['--data',body]
 run=subprocess.run(args,capture_output=True,timeout=50);content,_,status=run.stdout.rpartition(b'\n')
 if run.returncode:raise RuntimeError('HTTP transport failed')
 return int(status),content.decode(errors='replace')
def check(label,condition,detail=''):
 results.append({'check':label,'ok':bool(condition)})
 if not condition:
  (archive/'failed-response.txt').write_text(detail);raise RuntimeError(label+'; response saved privately')
def csrf(html):
 found=re.search(r'name="csrf" value="([a-f0-9]{64})"',html)
 if not found:raise RuntimeError('CSRF missing')
 return found.group(1)
try:
 for site,stage in paths.items():
  stage.mkdir(mode=0o755);(stage/'.htaccess').write_text('Require local\n')
  for full,body in p['files'].items():
   entry,rel=full.split('/',1)
   if entry!=site:continue
   target=stage/rel;target.parent.mkdir(parents=True,exist_ok=True)
   body=body.replace('new services.teams.','new _codex.'+name+'.services.teams.')
   if rel.endswith('start.cfm'):body=body.replace('new _codex.'+name+'.services.teams.Service();',"new _codex."+name+".services.teams.Service().init('runner_dba','rr_teams_test');")
   if rel=='teams/mail-worker.cfm':body=body.replace('.Mailer().run(',".Mailer().init('runner_dba','rr_teams_test').run(")
   if site=='rr':body=body.replace('<cfinclude template="../../includes/estrutura/variaveis.cfm">','')
   if site=='rr' and rel=='teams/entrar/index.cfm':body=body.replace('template="../../sso/comparador/_portal_nonce.cfm"','template="/sso/comparador/_portal_nonce.cfm"')
   target.write_text(body,encoding='utf-8-sig' if target.suffix in ['.cfm','.cfc'] else 'utf-8');os.chmod(target,0o644)
  application=app.replace('__NAME__',name+'_'+site).replace('__EMAIL__',recruit).replace('__SECRET__',secret).replace('__NONCE__',nonce).replace('__PROOF__',proof if site=='rr' else '')
  (stage/'Application.cfc').write_text(application,encoding='utf-8-sig')
  for rel,body in p['fixtures'].items():(stage/rel).write_text(body,encoding='utf-8-sig')
  (stage/'seed.cfm').write_text('<cfinclude template="http-seed.cfm">SEEDED')
  (stage/'clean.cfm').write_text('<cfinclude template="http-clean.cfm">')
  (stage/'inspect.cfm').write_text('<cfscript>q=queryExecute("SELECT (SELECT count(*) FROM rr_teams_test.membership WHERE ended_at IS NULL) members,(SELECT count(*) FROM rr_teams_test.recruit_invite) invites,(SELECT count(*) FROM rr_teams_test.mail_outbox) mails",{},{datasource="runner_dba"});writeOutput(serializeJSON(queryGetRow(q,1)));</cfscript>')
  (stage/'concurrent.cfm').write_text(p['fixtures']['concurrent.cfm'].replace('new services.teams.','new _codex.'+name+'.services.teams.'),encoding='utf-8-sig')
 if mode=='concurrency':
  status,body=request('business','seed.cfm');check('seed',status==200 and 'SEEDED' in body,body)
  try:
   with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
    responses=[f.result() for f in [pool.submit(request,'business','concurrent.cfm','athlete','operation=join&team='+t,'',False,False) for t in ['a','b']]]
   check('concurrent_join',sorted(s for s,b in responses)==[200,409],str(responses))
   status,body=request('business','inspect.cfm');snapshot={k.lower():v for k,v in json.loads(body).items()};check('one_active_membership',snapshot['members']==1,body)
   with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
    responses=[f.result() for f in [pool.submit(request,'business','concurrent.cfm',actor,'operation=recruit','',False,False) for actor in ['owner','other']]]
   check('concurrent_recruit',sorted(s for s,b in responses)==[200,409],str(responses))
   status,body=request('business','inspect.cfm');snapshot={k.lower():v for k,v in json.loads(body).items()};check('one_recruit_email',snapshot['invites']==1 and snapshot['mails']==1,body)
  finally:
   status,body=request('business','clean.cfm');cleanup.append({'ok':status==200 and 'FIXTURE_CLEAN' in body});check('fixture_cleanup',cleanup[-1]['ok'],body)
 else:
  status,body=request('business','teams/');check('business_anonymous',status==200 and 'Entre com sua conta' in body,body)
  status,body=request('business','teams/cadastro/','owner');check('business_registration',status==200 and 'name="cref"' in body,body);token=csrf(body)
  status,body=request('business','teams/cadastro/','owner','csrf='+token+'&confirm=yes');check('registration_validation_renders',status==200 and 'Preencha corretamente' in body,body)
  for tab in ['visao','atletas','resultados','divulgacao','equipe','cadastro']:
   status,body=request('business','teams/?team=10001&tab='+tab,'owner');check('business_tab_'+tab,status==200 and 'Crew fixture 1' in body and 'Não foi possível carregar' not in body,body)
   if tab in ['cadastro','divulgacao']:(archive/('preview-'+tab+'.html')).write_text(body)
  status,body=request('business','teams/?team=10001&tab=atletas','viewer');check('viewer_read',status==200 and 'Remover vínculo</button>' not in body,body)
  status,body=request('business','teams/?team=10001','other');check('other_team_denied',status==403,body)
  data=urllib.parse.urlencode({'operation':'review','team':10001,'csrf':token,'decision':'APPROVE','version':1,'evidence':'fixture','cref_active':'yes'})
  status,body=request('business','teams/','owner',data);check('owner_cannot_approve',status==403,body)
  status,body=request('business','teams/','owner','operation=save&team=10001&csrf=forged');check('csrf_denied',status==403,body)
  status,body=request('rr','teams/');check('rr_directory',status==200 and 'Crew fixture 1' in body,body)
  status,body=request('rr','teams/?team=crew-fixture-1');check('rr_public_team',status==200 and 'Represente este Team' in body and 'name="document"' not in body,body);(archive/'preview-rr.html').write_text(body)
  status,body=request('rr','teams/?team=crew-fixture-1','athlete',scenario='cookie-only');check('cookie_id_not_authenticated',status==200 and 'Entrar e continuar' in body and 'name="consent"' not in body,body)
  status,body=request('rr','teams/meu-team/');check('rr_personal_requires_login',status==302,body)
  status,body=request('rr','teams/?team=crew-fixture-1','athlete');check('rr_consent',status==200 and 'name="consent"' in body,body);rrToken=csrf(body)
  status,body=request('rr','teams/?team=crew-fixture-1','athlete',urllib.parse.urlencode({'operation':'join','team_id':10001,'consent':'yes','csrf':rrToken}));check('rr_join',status==303,body)
  status,body=request('rr','teams/meu-team/','athlete',scenario='linked');check('rr_my_team',status==200 and 'Crew fixture 1' in body and 'Sair do Team' in body,body)
  status,body=request('rr','teams/?team=crew-fixture-2','athlete',scenario='linked');check('rr_cooldown',status==200 and 'próxima adesão ou troca' in body,body)
  status,body=request('rr','teams/convidar/','athlete');check('rr_recruit_form',status==200 and 'name="destination"' in body,body)
  for method,data,auth,expected in [('GET',None,False,405),('POST','{}',False,401),('POST','[]',True,400),('POST','{"limit":0,"dryRun":true}',True,400),('POST','{"limit":1,"dryRun":true}',True,200)]:
   status,body=request('business','teams/mail-worker.cfm',body=data,auth=auth);check('worker_'+method+'_'+str(expected),status==expected,body)
 result={'ok':True,'mode':mode,'checks':results,'no_test_deliveries':True,'fixture_cleanup':cleanup}
except Exception as error:result={'ok':False,'mode':mode,'error':str(error),'checks':results,'fixture_cleanup':cleanup}
finally:
 for site,stage in paths.items():
  if stage.exists():stage.rename(archive/site)
 result['stages_removed']=all(not path.exists() for path in paths.values());result['archive']=str(archive)
 (archive/'result.json').write_text(json.dumps(result,indent=2));os.chmod(archive/'result.json',0o600)
print(json.dumps(result))
"""
run=subprocess.run(['ssh','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-o','ConnectTimeout=12','rr-prod','python3 -c '+shlex.quote(REMOTE)],input=json.dumps({'mode':mode,'files':files,'fixtures':fixtures}).encode(),capture_output=True,timeout=240)
try:result=json.loads(run.stdout)
except ValueError:result={'ok':False,'error':run.stderr.decode(errors='replace')[-2000:]}
(ROOT/'_codex/teams'/('http-'+mode+'.json')).write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
print(json.dumps(result,ensure_ascii=False));raise SystemExit(0 if not run.returncode and result.get('ok') else 1)
