"""Candidate global controller HTTP tests: localhost-only, rollback, no deliveries."""
import base64,json,pathlib,shlex,subprocess,sys
ROOT=pathlib.Path(__file__).resolve().parents[2];WORK=ROOT/'_codex/teams/global';files={}
for parent in ['administracao/teams','teams','services/teams']:
 for path in (ROOT/parent).rglob('*'):
  if path.is_file():files[str(path.relative_to(ROOT))]=base64.b64encode(path.read_bytes()).decode()
for rel in ['assets/css/mdb.min.css','assets/css/business-ui.css']:
 files[rel]=base64.b64encode((ROOT/rel).read_bytes()).decode()
seed=(ROOT/'_codex/tests/teams/http-seed.cfm').read_text()
REMOTE=r'''
import base64,html,json,os,pathlib,re,secrets,subprocess,sys,tempfile,urllib.parse
p=json.load(sys.stdin);root=pathlib.Path('/var/www/business.roadrunners.run');name='teams_global_'+secrets.token_hex(8);nonce=secrets.token_hex(24);stage=root/'_codex'/name
archive=pathlib.Path(tempfile.mkdtemp(prefix='rr-teams-global-test-',dir='/var/backups'));os.chmod(archive,0o700);checks=[];previews={};result={'ok':False}
app=r"""component {
 this.name='__NAME__';this.datasource='runner_dba';this.sessionManagement=true;this.setClientCookies=true;
 function onApplicationStart(){
  var users=queryExecute("SELECT id FROM public.tb_usuarios u WHERE NOT coalesce(is_admin,false) AND NOT EXISTS(SELECT 1 FROM public.tb_usuarios_gestao g WHERE g.id_usuario=u.id AND (NOT coalesce(g.ativo,true) OR coalesce(g.excluido,false))) ORDER BY id LIMIT 4",{},{datasource='runner_dba'});
  var staff=queryExecute("SELECT id FROM public.tb_usuarios u WHERE is_admin AND NOT EXISTS(SELECT 1 FROM public.tb_usuarios_gestao g WHERE g.id_usuario=u.id AND (NOT coalesce(g.ativo,true) OR coalesce(g.excluido,false))) ORDER BY id LIMIT 1",{},{datasource='runner_dba'});
  APPLICATION.testActors={owner=users.id[1],other=users.id[2],athlete=users.id[3],viewer=users.id[4],global=staff.id[1]};return true;
 }
 function onRequestStart(string target){
  cfsetting(showdebugoutput=false,requesttimeout=40);
  if(!listFind('127.0.0.1,::1',CGI.remote_addr)||(CGI.http_x_teams_global ?: '')!='__NONCE__'){cfheader(statuscode=404);abort;}
  REQUEST.businessIdentity={};REQUEST.testScenario=CGI.http_x_scenario ?: '';var who=CGI.http_x_actor ?: '';
  if(structKeyExists(APPLICATION.testActors,who))REQUEST.businessIdentity={id=APPLICATION.testActors[who]};
  if(REQUEST.testScenario=='delegated')REQUEST.businessAccessContext={accessMode='DELEGATED'};
  if(REQUEST.testScenario=='simulated')REQUEST.businessAccessContext={accessMode='INTERNAL_SIMULATION'};
  if(REQUEST.testScenario=='cookie-only'){REQUEST.businessIdentity={};COOKIE.id=APPLICATION.testActors.global;COOKIE.is_admin=true;}
  SESSION.businessLoginCsrf=repeatString('a',64);SESSION.businessLoginNonce=repeatString('b',43);return true;
 }
 function onRequest(string target){
  if(listFind('inspect.cfm,actors.cfm',listLast(arguments.target,'/'))){include arguments.target;return;}
  transaction{try{
   include 'seed.cfm';
   queryExecute("UPDATE rr_teams_test.team SET status='PENDING',name='Crew <script>alert(1)</script>' WHERE id_team=10001",{},{datasource='runner_dba'});
   if(find('tenant-admin',REQUEST.testScenario))queryExecute("UPDATE rr_teams_test.admin SET role='ADMIN' WHERE team_id=10001 AND user_id=:user",{user={value=APPLICATION.testActors.viewer,cfsqltype='cf_sql_integer'}},{datasource='runner_dba'});
   if(find('higher',REQUEST.testScenario))queryExecute("INSERT INTO rr_teams_test.admin_invite(team_id,email,role,token_hash,created_by) SELECT 10001,u.email,'ADMIN',repeat('c',64),:owner FROM public.tb_usuarios u WHERE u.id=:user",{owner={value=APPLICATION.testActors.owner,cfsqltype='cf_sql_integer'},user={value=APPLICATION.testActors.other,cfsqltype='cf_sql_integer'}},{datasource='runner_dba'});
   if(REQUEST.testScenario=='stale')queryExecute('UPDATE rr_teams_test.team SET version=2 WHERE id_team=10001',{},{datasource='runner_dba'});
   include arguments.target;
  }finally{transaction action='rollback';}}
 }
}"""
def request(path,actor='',form=None,scenario=''):
 args=['curl','-sS','--max-time','45','--resolve','business.roadrunners.run:443:127.0.0.1','-H','X-Teams-Global: '+nonce,'-H','X-Actor: '+actor,'-H','X-Scenario: '+scenario,'-b',str(archive/(actor+'.cookies')),'-c',str(archive/(actor+'.cookies')),'-D',str(archive/'headers.txt'),'-w','\n%{http_code}','https://business.roadrunners.run/_codex/'+name+'/'+path]
 if form is not None:args+=['--data',urllib.parse.urlencode(form)]
 r=subprocess.run(args,capture_output=True,timeout=50);raw,_,status=r.stdout.rpartition(b'\n');assert not r.returncode
 return int(status),raw.decode(errors='replace'),(archive/'headers.txt').read_text()
def check(label,ok,body=''):
 checks.append({'check':label,'ok':bool(ok)})
 if not ok:(archive/'failure.html').write_text(body);raise RuntimeError(label+'; details in private archive')
def token(body):
 m=re.search(r'name="csrf" value="([a-f0-9]{64})"',body);assert m,'No CSRF';return m.group(1)
try:
 stage.mkdir(mode=0o755);(stage/'.htaccess').write_text('Require local\n')
 for rel,data in p['files'].items():
  dest=stage/rel;dest.parent.mkdir(parents=True,exist_ok=True);body=base64.b64decode(data)
  if dest.suffix in ['.cfm','.cfc']:
   text=body.decode('utf-8-sig').replace('new services.teams.','new _codex.'+name+'.services.teams.')
   if rel=='teams/includes/start.cfm':text=text.replace('.Service();',".Service().init('runner_dba','rr_teams_test');")
   if rel=='administracao/teams/index.cfm':
    # Only the shared shell is replaced; the real controller and all Teams views run intact.
    text=text.replace('<cfinclude template="../../includes/backend/backend_login.cfm">','')
    text=text.replace('<cfinclude template="../../includes/estrutura/head.cfm">','<head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><link rel="stylesheet" href="/assets/css/mdb.min.css"><link rel="stylesheet" href="/assets/css/business-ui.css"></head>')
    text=text.replace('<cfinclude template="../../includes/estrutura/header.cfm">','<header style="height:100px"></header>').replace('<cfinclude template="../../includes/estrutura/footer.cfm">','')
   body=text.encode('utf-8-sig')
  dest.write_bytes(body);os.chmod(dest,0o644)
 (stage/'seed.cfm').write_text(p['seed'],encoding='utf-8-sig');(stage/'Application.cfc').write_text(app.replace('__NAME__',name).replace('__NONCE__',nonce),encoding='utf-8-sig')
 (stage/'actors.cfm').write_text('<cfscript>writeOutput(serializeJSON(APPLICATION.testActors));</cfscript>')
 path='administracao/teams/'
 status,body,h=request(path);check('guest_login_redirect',status==303 and '/teams/' in h,body)
 status,body,h=request(path,scenario='cookie-only');check('cookie_not_global_identity',status==303,body)
 for actor,scenario in [('owner',''),('viewer',''),('global','delegated'),('global','simulated')]:
  status,body,h=request(path,actor,scenario=scenario);check('denied_'+actor+'_'+scenario,status==403 and 'name="decision"' not in body,body)
 status,body,h=request(path,'global');check('global_list',status==200 and 'Novo Team' in body and 'Gestão de Teams' in body and 'Crew &lt;script&gt;' in body and '<script>alert(1)</script>' not in body,body);previews['list']=body
 status,body,h=request(path+'?novo=1&q=Florian&status=PENDING&type=GRUPO&uf=SC','global');check('manual_create_form',status==200 and 'Salvar e revisar' in body and 'name="operation" value="create"' in body and 'name="cref"' in body,body);create_csrf=token(body);previews['create']=body
 check('manual_filters_preserved','q=Florian&status=PENDING&type=GRUPO&uf=SC' in html.unescape(body),body)
 create={'operation':'create','csrf':create_csrf,'name':'Manual <teste>','type':'GRUPO','document':'52998224725','ownerName':'Titular manual','technicalName':'Técnico manual','cref':'123456-G','crefUf':'SC','email':'manual@example.org','phone':'48999998888','whatsapp':'48999998888','city':'Florianópolis','uf':'SC','attendance':'AMBOS','description':'','website':''}
 for who,scenario in [('owner',''),('viewer',''),('global','delegated'),('global','simulated')]:
  status,body,h=request(path+'?novo=1',who,create,scenario=scenario);check('manual_access_'+who+'_'+scenario,status==403,body)
 status,body,h=request(path+'?novo=1','global',{**create,'csrf':'invalid'});check('manual_csrf_denied',status==403 and 'value="Manual <teste>"' in html.unescape(body),body)
 status,body,h=request(path+'?novo=1','global',{**create,'document':'11111111111'});check('manual_validation_preserves',status==400 and 'value="Manual <teste>"' in html.unescape(body) and 'CPF ou CNPJ válido' in html.unescape(body),body)
 status,body,h=request(path+'?novo=1','global',{**create,'cref':''});check('manual_cref_required',status==400,body)
 status,body,h=request(path+'?novo=1','global',{**create,'name':'Crew fixture 2','document':'11222333000181'});check('manual_duplicate_denied',status==400 and 'Já existe' in html.unescape(body),body)
 status,body,h=request(path+'?novo=1&q=Florian&status=PENDING','global',create);check('manual_created_prg',status==303 and 'created=1' in h and 'tab=revisao' in h and 'team=' in h and 'q=Florian' in h,body)
 status,body,h=request(path+'?team=10001&tab=revisao&created=1','global');check('manual_created_notice',status==200 and 'Team cadastrado' in body,body)
 status,body,h=request(path+'?status=PENDING&type=GRUPO&uf=SC&q=Florian','global');check('combined_filters',status==200 and '1 encontrado(s)' in body and 'status=PENDING' in html.unescape(body),body)
 status,body,h=request('actors.cfm');actors={k.lower():v for k,v in json.loads(body).items()}
 existing_path=path+'?team=10001&tab=equipe&q=Florian&status=PENDING&type=GRUPO&uf=SC&user_busca='+str(actors['other'])
 status,body,h=request(existing_path,'global');check('existing_search_results',status==200 and 'Adicionar usuário existente' in body and 'name="operation" value="add_existing_admin"' in body and ('value="'+str(actors['other'])+'"') in body,body);existing_csrf=token(body);previews['existing']=body
 check('existing_filters_preserved','q=Florian&status=PENDING&type=GRUPO&uf=SC' in html.unescape(body) and 'user_busca='+str(actors['other']) in html.unescape(body),body)
 status,body,h=request(path+'?team=10001&tab=equipe&user_busca=nao-existe-fixture-zz','global');check('existing_empty_search',status==200 and 'Nenhum usuário ativo' in body,body)
 status,body,h=request(path+'?team=10001&tab=equipe&user_busca=x','global');check('existing_short_search',status==200 and 'pelo menos dois' in body,body)
 add={'operation':'add_existing_admin','team':10001,'member':actors['other'],'role':'ADMIN','csrf':existing_csrf}
 for who,scenario in [('owner',''),('viewer',''),('global','delegated'),('global','simulated')]:
  status,body,h=request(existing_path,who,add,scenario=scenario);check('existing_access_'+who+'_'+scenario,status==403,body)
 status,body,h=request(existing_path,'global',{**add,'csrf':'bad'});check('existing_csrf_denied',status==403 and '<option value="ADMIN" selected>' in body,body)
 status,body,h=request(existing_path,'global',{**add,'role':'GLOBAL'});check('existing_role_denied',status==400,body)
 status,body,h=request(existing_path,'global',{**add,'member':actors['owner']});check('existing_duplicate_denied',status==400 and 'já faz parte' in html.unescape(body),body)
 for role in ['OWNER','ADMIN','VIEWER']:
  status,body,h=request(existing_path,'global',{**add,'role':role});check('existing_add_'+role,status==303 and 'saved=1' in h and 'tab=equipe' in h and 'user_busca='+str(actors['other']) in h,body)
 status,body,h=request('teams/?team=10001&tab=equipe','owner');check('existing_owner_ui_shared',status==200 and 'name="user_busca"' in body and 'team-add-user-title' in body,body)
 status,body,h=request(path+'?team=10001&tab=equipe','global');check('role_editor_present',status==200 and 'Salvar papel' in body and 'name="expected_role"' in body and 'name="operation" value="change_admin_role"' in body,body)
 addition=body.split('aria-labelledby="team-add-user-title"',1)[1].split('</section>',1)[0]
 check('two_add_options_grouped','Adicionar usuário existente' in addition and 'Convidar por email' in addition and addition.count('<details')==2,body);previews['roles']=body
 change={'operation':'change_admin_role','team':10001,'member':actors['viewer'],'role':'ADMIN','expected_role':'VIEWER','csrf':existing_csrf}
 for who,scenario in [('owner',''),('viewer',''),('global','delegated'),('global','simulated')]:
  status,body,h=request(existing_path,who,change,scenario=scenario);check('role_access_'+who+'_'+scenario,status==403,body)
 status,body,h=request(existing_path,'global',{**change,'csrf':'bad'});check('role_csrf_preserves',status==403 and '<option value="ADMIN" selected>' in body,body)
 status,body,h=request(existing_path,'global',{**change,'expected_role':'OWNER'});check('role_stale_denied',status==400 and 'outra pessoa' in html.unescape(body),body)
 status,body,h=request(existing_path,'global',{**change,'member':actors['owner'],'expected_role':'OWNER'});check('role_last_owner_denied',status==400 and 'último titular' in html.unescape(body),body)
 status,body,h=request(existing_path,'global',{**change,'role':'GLOBAL'});check('role_invalid_denied',status==400,body)
 status,body,h=request(existing_path,'global',{**change,'member':actors['other']});check('role_foreign_member_denied',status==400,body)
 status,body,h=request(existing_path,'global',change);check('role_changed_prg',status==303 and 'saved=1' in h and 'tab=equipe' in h and 'user_busca='+str(actors['other']) in h,body)
 invite_form={'operation':'invite_admin','team':10001,'csrf':existing_csrf,'email':'invalid-email','role':'ADMIN'}
 status,body,h=request(existing_path,'global',invite_form);check('invite_option_error_preserved',status==400 and 'value="invalid-email"' in html.unescape(body) and re.search(r'<details[^>]*open[^>]*><summary><strong>Convidar por email',body),body)
 status,body,h=request(existing_path,'global',{**invite_form,'email':'team-role-fixture@example.org'});check('invite_option_prg',status==303 and 'tab=equipe' in h,body)
 tenant='teams/?team=10001&tab=equipe&q=Florian&page=1&user_busca='+str(actors['other'])
 status,body,h=request(tenant,'owner');check('tenant_owner_shared_ui',status==200 and 'team-add-user-title' in body and 'Salvar papel' in body and 'name="user_busca"' in body and '<option value="OWNER"' not in body,body);owner_csrf=token(body);previews['tenant-owner']=body
 status,body,h=request(tenant,'viewer',scenario='tenant-admin');check('tenant_admin_limited_ui',status==200 and 'team-add-user-title' in body and '<option value="ADMIN"' not in body and '<option value="OWNER"' not in body and 'Salvar papel' not in body and 'Remover acesso' not in body,body);admin_csrf=token(body);previews['tenant-admin']=body
 status,body,h=request(tenant,'viewer');check('tenant_viewer_readonly',status==200 and 'team-add-user-title' not in body and 'Salvar papel' not in body and 'name="user_busca"' not in body and 'Enviar convite' not in body,body);previews['tenant-viewer']=body
 owner_add={'operation':'add_existing_admin','team':10001,'member':actors['other'],'role':'ADMIN','csrf':owner_csrf}
 status,body,h=request(tenant,'owner',owner_add);check('tenant_owner_add_prg',status==303 and 'updated=1' in h and 'user_busca='+str(actors['other']) in h,body)
 status,body,h=request(tenant,'owner',{**owner_add,'role':'OWNER'});check('tenant_owner_cannot_grant_owner',status==403,body)
 status,body,h=request(tenant,'owner',{**owner_add,'csrf':'bad'});check('tenant_owner_csrf',status==403 and 'name="member"' in body,body)
 status,body,h=request(tenant,'viewer',{**owner_add,'csrf':admin_csrf,'role':'VIEWER'},scenario='tenant-admin');check('tenant_admin_add_viewer',status==303,body)
 status,body,h=request(tenant,'viewer',{**owner_add,'csrf':admin_csrf},scenario='tenant-admin');check('tenant_admin_no_peer_grant',status==403,body)
 status,body,h=request(tenant,'viewer',{**owner_add,'csrf':admin_csrf,'role':'VIEWER'},scenario='tenant-admin-higher');check('tenant_admin_preserves_higher_invite',status==403 and '>Revogar</button>' not in body,body)
 status,body,h=request(tenant,'viewer',{**owner_add,'csrf':admin_csrf,'role':'VIEWER'});check('tenant_viewer_no_grant',status==403,body)
 owner_change={'operation':'change_admin_role','team':10001,'member':actors['viewer'],'role':'ADMIN','expected_role':'VIEWER','csrf':owner_csrf}
 status,body,h=request(tenant,'owner',owner_change);check('tenant_owner_change_role',status==303 and 'updated=1' in h,body)
 status,body,h=request(tenant,'owner',{**owner_change,'expected_role':'ADMIN'});check('tenant_stale_role_denied',status==400 and 'outra pessoa' in html.unescape(body),body)
 status,body,h=request(tenant,'owner',{**owner_change,'member':actors['owner'],'expected_role':'OWNER'});check('tenant_owner_no_titular_change',status==403,body)
 status,body,h=request(tenant,'viewer',{**owner_change,'csrf':admin_csrf,'expected_role':'ADMIN','role':'VIEWER'},scenario='tenant-admin');check('tenant_admin_no_role_change',status==403,body)
 status,body,h=request('teams/?team=10002&tab=equipe','owner',owner_add);check('tenant_mismatched_team_denied',status in [400,403],body)
 invite_tenant={'operation':'invite_admin','team':10001,'csrf':admin_csrf,'email':'tenant-fixture@example.org','role':'VIEWER'}
 status,body,h=request(tenant,'viewer',invite_tenant,scenario='tenant-admin');check('tenant_admin_invite_viewer',status==303 and 'invited=1' in h,body)
 status,body,h=request(tenant,'viewer',{**invite_tenant,'role':'ADMIN'},scenario='tenant-admin');check('tenant_admin_invite_no_peer',status==403,body)
 status,body,h=request(path+'?q=ausente','global');check('empty_filters',status==200 and 'Nenhum Team encontrado' in body,body)
 status,body,h=request(path+'?status=INVALID','global');check('invalid_filter',status==400 and 'Situação inválida' in html.unescape(body),body)
 for tab in ['cadastro','responsavel','revisao','equipe','atletas','historico']:
  status,body,h=request(path+'?team=10001&tab='+tab+'&q=Florian&status=PENDING&type=GRUPO&uf=SC','global');check('global_tab_'+tab,status==200 and 'Crew &lt;script&gt;' in body and 'name="csrf"' in body if tab in ['cadastro','revisao','equipe'] else status==200 and 'Crew &lt;script&gt;' in body,body)
  check('filters_retained_'+tab,'q=Florian&status=PENDING&type=GRUPO&uf=SC' in html.unescape(body),body);previews[tab]=body
  if tab=='revisao':csrf=token(body)
 form={'operation':'review','team':10001,'version':1,'csrf':csrf,'decision':'APPROVE','cref_active':'yes','evidence':'Consulta humana fixture'}
 status,body,h=request(path+'?team=10001&tab=revisao','global',{**form,'csrf':'forged'});check('review_csrf_denied',status==403,body)
 status,body,h=request(path+'?team=10001&tab=revisao','global',form,scenario='stale');check('stale_review_denied',status==400 and 'cadastro mudou' in body and 'value="1"' in body,body)
 status,body,h=request(path+'?team=10001&tab=revisao','global',{**form,'version':'invalid'});check('malformed_review_version',status==400 and 'TEST_FAILED' not in body,body)
 status,body,h=request(path+'?team=10001&tab=revisao','global',{**form,'evidence':''});check('review_evidence_required',status==400 and 'evidência' in html.unescape(body),body)
 status,body,h=request(path+'?team=10001&tab=revisao&q=Florian&status=PENDING','global',form);check('review_approved_prg',status==303 and 'saved=1' in h and 'q=Florian' in h,body)
 invalid={'operation':'save','team':10001,'version':1,'csrf':csrf,'name':'Nome <teste> digitado','document':'INVALID','type':'GRUPO','ownerName':'Responsável digitado','technicalName':'Técnico','cref':'123456-G','crefUf':'SC','email':'fixture@example.org','phone':'48999998888','whatsapp':'48999998888','city':'Florianópolis','uf':'SC','attendance':'AMBOS','description':'Descrição preservada','website':''}
 status,body,h=request(path+'?team=10001&tab=cadastro','global',invalid);check('invalid_save_preserves_fields',status==400 and 'value="Nome <teste> digitado"' in html.unescape(body) and 'Descrição preservada' in html.unescape(body) and 'CPF ou CNPJ válido' in html.unescape(body),body)
 status,body,h=request(path+'?team=10001&tab=cadastro','global',{**invalid,'document':'52998224725','description':''});check('save_optional_fields_empty',status==303,body)
 status,body,h=request('teams/?team=10001&tab=equipe','global');check('legacy_global_redirect',status==303 and '/administracao/teams/' in h and 'team=10001' in h and 'tab=equipe' in h,body)
 status,body,h=request('teams/?team=10001&tab=atletas&q=Ana&page=2','global');check('legacy_athlete_filter_redirect',status==303 and 'aq=Ana' in h and 'apage=2' in h and '?q=Ana' not in h,body)
 status,body,h=request('teams/?team=10001&tab=cadastro','owner');check('owner_panel_separate',status==200 and 'name="decision"' not in body and 'name="operation" value="save"' in body,body)
 status,body,h=request('teams/','owner');check('owner_list_scoped',status==200 and 'Crew fixture 2' not in body,body)
 status,body,h=request('teams/?team=10001','global',form);check('legacy_global_post_denied',status==403,body)
 (stage/'inspect.cfm').write_text('<cfoutput>#queryExecute("SELECT count(*) n FROM rr_teams_test.team",{},{datasource="runner_dba"}).n[1]#</cfoutput>')
 # Inspection uses a separate minimal app route without seed/transaction; read only.
 status,body,h=request('inspect.cfm');check('fixture_empty_after_requests',status==200 and body.strip()=='0',body)
 result={'ok':True,'checks':checks,'no_emails':True,'fixture_transactions_rolled_back':True}
except Exception as error:result={'ok':False,'error':str(error),'checks':checks}
finally:
 for name,body in previews.items():(archive/('preview-'+name+'.html')).write_text(body)
 if stage.exists():stage.rename(archive/'source')
 result.update({'archive':str(archive),'stage_removed':not stage.exists(),'previews':{k:base64.b64encode(v.encode()).decode() for k,v in previews.items()} if result.get('ok') else {}})
 (archive/'result.json').write_text(json.dumps({k:v for k,v in result.items() if k!='previews'},indent=2))
print(json.dumps(result))
'''
run=subprocess.run(['ssh','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-o','ConnectTimeout=12','rr-prod','python3 -c '+shlex.quote(REMOTE)],input=json.dumps({'files':files,'seed':seed}).encode(),capture_output=True,timeout=240)
try:result=json.loads(run.stdout)
except ValueError:result={'ok':False,'error':run.stderr.decode(errors='replace')[-1500:]}
if result.get('previews'):
 preview=WORK/'preview';preview.mkdir(parents=True,exist_ok=True)
 for k,v in result.pop('previews').items():(preview/(k+'.html')).write_bytes(base64.b64decode(v))
 for rel in ['assets/css/mdb.min.css','assets/css/business-ui.css','administracao/teams/assets/manager.css','teams/assets/rr_teams.svg','teams/assets/teams.js','teams/assets/admins.css']:
  dest=preview/rel;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes((ROOT/rel).read_bytes())
 (preview/'mobile.html').write_text('<html><body style="margin:0;background:#444"><iframe title="Gestão de Teams no celular" src="list.html" style="width:390px;height:900px;border:0"></iframe></body></html>')
 result['preview']=str(preview)
import hashlib,datetime
result['checked_at']=datetime.datetime.now(datetime.timezone.utc).isoformat()
result['source_hashes']={rel:hashlib.sha256((ROOT/rel).read_bytes()).hexdigest() for rel in ['services/teams/Service.cfc','services/accountDelegation/RequestBoundary.cfc','teams/index.cfm','teams/includes/admins.cfm','teams/assets/admins.css','teams/includes/registration.cfm','includes/estrutura/sidenav.cfm']+[str(p.relative_to(ROOT)) for p in (ROOT/'administracao/teams').rglob('*') if p.is_file()]}
(WORK/'http.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result));sys.exit(0 if result.get('ok') else 1)
