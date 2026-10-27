"""Teams existing-user management release only. Baseline/CAS, CF compilation, backup, rollback and probes."""
import ast,base64,datetime,hashlib,json,pathlib,shlex,subprocess,sys
ROOT=pathlib.Path(__file__).resolve().parents[2];WORK=ROOT/'_codex/teams/existing';sha=lambda b:hashlib.sha256(b).hexdigest();mode=sys.argv[1]
EXISTING=['services/teams/Service.cfc','administracao/teams/home.cfm','administracao/teams/includes/backend.cfm']
NEW=['administracao/teams/includes/existing_user.cfm'];PATHS=EXISTING+NEW
PRESERVE=['config/business.local.cfm','teams/mail-worker.cfm','services/teams/Mailer.cfc','services/teams/EmailTransport.cfc','teams/includes/header.cfm','teams/assets/teams.css','teams/assets/rr_teams.svg','includes/backend/cron_jobs_service.cfm','administracao/contas/index.cfm','administracao/contas/home.cfm','includes/estrutura/head.cfm','assets/css/business-ui.css','includes/estrutura/sidenav.cfm','teams/index.cfm','teams/includes/registration.cfm','administracao/teams/index.cfm','administracao/teams/includes/review.cfm','administracao/teams/assets/manager.css','administracao/teams/includes/create.cfm']
def ssh(remote,payload,timeout=220):
 run=subprocess.run(['ssh','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-o','ConnectTimeout=12','rr-prod','python3 -c '+shlex.quote(remote)],input=json.dumps(payload).encode(),capture_output=True,timeout=timeout)
 try:result=json.loads(run.stdout)
 except ValueError:raise SystemExit(run.stderr.decode(errors='replace')[-1500:] or run.stdout.decode(errors='replace')[-1000:])
 if run.returncode or not result.get('ok'):print(json.dumps(result));raise SystemExit(1)
 return result
READ=r'''
import base64,hashlib,json,pathlib,sys
p=json.load(sys.stdin);root=pathlib.Path('/var/www/business.roadrunners.run');files={}
for rel in p['paths']:
 path=root/rel;assert not path.is_symlink();data=path.read_bytes() if path.exists() else None;files[rel]={'hash':hashlib.sha256(data).hexdigest() if data is not None else None,'data':base64.b64encode(data).decode() if data is not None and rel in p['includeData'] else None}
print(json.dumps({'ok':True,'files':files}))
'''
if mode=='prepare':
 baseline=ssh(READ,{'paths':PATHS+PRESERVE,'includeData':PATHS});publication=json.loads((ROOT/'_codex/teams/publication.json').read_text());manifest={}
 for rel in PATHS:
  info=baseline['files'][rel];data=(ROOT/rel).read_bytes()
  if rel in NEW and info['hash'] is not None:raise SystemExit('New production route already exists: '+rel)
  if rel in EXISTING and info['hash']!=publication['candidate_hashes']['business/'+rel]:raise SystemExit('Production drift; inspect and preserve before proceeding: '+rel)
  dest=WORK/'baseline'/rel;dest.parent.mkdir(parents=True,exist_ok=True)
  if info['data'] is not None:dest.write_bytes(base64.b64decode(info['data']))
  target=WORK/'release'/rel;target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(data)
  manifest[rel]={'before':info['hash'],'after':sha(data)}
 (WORK/'baseline.json').write_text(json.dumps({'files':{rel:{'hash':v['hash']} for rel,v in baseline['files'].items()}},indent=2)+'\n');(WORK/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
 print(json.dumps({'ok':True,'files':len(manifest),'preserved':len(PRESERVE)}));sys.exit(0)
manifest=json.loads((WORK/'manifest.json').read_text());files={}
for rel,v in manifest.items():
 data=(WORK/'release'/rel).read_bytes()
 if sha(data)!=v['after'] or (ROOT/rel).read_bytes()!=data:raise SystemExit('Candidate changed; prepare and verify again: '+rel)
 files[rel]=data
if mode=='compile':
 tree=ast.parse((ROOT/'_codex/scripts/check_teams.py').read_text());remote=next(ast.literal_eval(n.value) for n in tree.body if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='REMOTE' for t in n.targets))
 result=ssh(remote,{'mode':'compile','files':{rel:v.decode('utf-8-sig') for rel,v in files.items()}});result['hashes']={k:v['after'] for k,v in manifest.items()};(WORK/'compile.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result));sys.exit(0)
if mode!='publish':raise SystemExit('Use prepare, compile or publish')
proof=json.loads((ROOT/'_codex/teams/global/http.json').read_text());compiled=json.loads((WORK/'compile.json').read_text());want={k:v['after'] for k,v in manifest.items()}
if not proof['ok'] or {k:proof['source_hashes'].get(k) for k in want}!=want or not compiled['ok'] or compiled['hashes']!=want:raise SystemExit('Matching HTTP and compilation proof required')
if (datetime.datetime.now(datetime.timezone.utc)-datetime.datetime.fromisoformat(proof['checked_at'])).total_seconds()>3600:raise SystemExit('HTTP evidence expired')
REMOTE=r'''
import base64,hashlib,json,os,pathlib,secrets,stat,subprocess,sys,tempfile
p=json.load(sys.stdin);root=pathlib.Path('/var/www/business.roadrunners.run');sha=lambda b:hashlib.sha256(b).hexdigest()
assert set(p['items'])==set(p['allowed']);old={};info={}
for rel,d in p['items'].items():
 path=root/rel;assert not path.is_symlink() and root in path.resolve().parents
 data=path.read_bytes() if path.exists() else None;assert (sha(data) if data is not None else None)==d['before'],'Production conflict: '+rel
 assert sha(base64.b64decode(d['data']))==d['after'];old[rel]=data;info[rel]=path.stat() if path.exists() else (root/'index.cfm').stat()
for rel,h in p['preserve'].items():assert sha((root/rel).read_bytes())==h,'Dependency drift: '+rel
backup=pathlib.Path(tempfile.mkdtemp(prefix='rr-teams-existing-release-',dir='/var/backups'));os.chmod(backup,0o700);written=[];probes=[]
def atomic(rel,data):
 path=root/rel;path.parent.mkdir(parents=True,exist_ok=True,mode=0o755);fd,tmp=tempfile.mkstemp(prefix='.teams-global-',dir=path.parent);meta=info[rel]
 try:
  with os.fdopen(fd,'wb') as f:f.write(data);f.flush();os.fsync(f.fileno());os.fchmod(f.fileno(),stat.S_IMODE(meta.st_mode) if old[rel] is not None else 0o644);os.fchown(f.fileno(),meta.st_uid,meta.st_gid)
  os.replace(tmp,path)
 finally:
  if os.path.exists(tmp):os.unlink(tmp)
def request(path,status,needle=''):
 r=subprocess.run(['curl','-sS','--max-time','40','-w','\n%{http_code}','https://business.roadrunners.run'+path],capture_output=True,timeout=45);body,_,code=r.stdout.rpartition(b'\n')
 if r.returncode or int(code)!=status or needle not in body.decode(errors='replace'):
  (backup/'failed-http.html').write_bytes(body);raise RuntimeError('HTTP probe failed: '+path+' status='+code.decode())
 probes.append({'path':path,'status':int(code)})
try:
 (backup/'manifest.json').write_text(json.dumps({k:{'before':d['before'],'after':d['after']} for k,d in p['items'].items()},indent=2))
 # Publish assets/dependencies first; activate the new entry point before redirect/menu changes.
 order=['services/teams/Service.cfc','administracao/teams/includes/existing_user.cfm','administracao/teams/includes/backend.cfm','administracao/teams/home.cfm']
 for rel in order:
  path=root/rel;now=path.read_bytes() if path.exists() else None;assert now==old[rel],'Concurrent change: '+rel
  if now is not None:dest=backup/rel;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(now);os.chmod(dest,0o600)
  atomic(rel,base64.b64decode(p['items'][rel]['data']));written.append(rel)
 for rel,d in p['items'].items():assert sha((root/rel).read_bytes())==d['after']
 for rel,h in p['preserve'].items():assert sha((root/rel).read_bytes())==h,'Preserved dependency changed: '+rel
 request('/administracao/teams/',303);request('/teams/',200,'Entre com sua conta');request('/teams/cadastro/',200,'Seu time tem lugar aqui.');request('/teams/convites/',200,'Convite para administrar')
 # This private localhost-only GET probe rolls back any legacy notification maintenance.
 name='teams_global_operation_'+secrets.token_hex(12);nonce=secrets.token_hex(24);stage=root/'_codex'/name;stage.mkdir(mode=0o755);(stage/'.htaccess').write_text('Require local\n')
 body=p['probe'].replace('__NONCE__',nonce);(stage/'run.cfm').write_text(body,encoding='utf-8-sig');os.chmod(stage/'run.cfm',0o644)
 try:
  r=subprocess.run(['curl','-sS','--max-time','60','--resolve','business.roadrunners.run:443:127.0.0.1','-H','X-Teams-Global-Operation: '+nonce,'https://business.roadrunners.run/_codex/'+name+'/run.cfm'],capture_output=True,timeout=65)
  raw=r.stdout.decode(errors='replace');(backup/'authenticated-probe.txt').write_text(raw);os.chmod(backup/'authenticated-probe.txt',0o600)
  assert not r.returncode and 'TEAMS_GLOBAL_PRODUCTION_PASSED' in raw,'Authenticated published shell failed; inspect private backup'
  probes.append({'authenticated_global_shell':True,'readonly_effects':True})
 finally:
  stage.rename(backup/'private-probe')
 result={'ok':True,'backup':str(backup),'files':len(written),'hashes':{k:v['after'] for k,v in p['items'].items()},'preserved_files':len(p['preserve']),'probes':probes}
except Exception as error:
 for rel in reversed(written):
  path=root/rel
  if old[rel] is None:path.unlink()
  else:atomic(rel,old[rel])
 result={'ok':False,'backup':str(backup),'rolled_back':True,'error':str(error)}
(backup/'result.json').write_text(json.dumps(result,indent=2));print(json.dumps(result));sys.exit(0 if result['ok'] else 1)
'''
PROBE='''<cfsetting requesttimeout="55" showdebugoutput="false"><cfscript>
if(!listFind('127.0.0.1,::1',CGI.remote_addr)||(CGI.http_x_teams_global_operation ?: '')!='__NONCE__'){cfheader(statuscode=404);abort;}
try{
 transaction {
  try{
   staff=queryExecute("SELECT id FROM public.tb_usuarios u WHERE is_admin=true AND NOT EXISTS(SELECT 1 FROM public.tb_usuarios_gestao g WHERE g.id_usuario=u.id AND (NOT coalesce(g.ativo,true) OR coalesce(g.excluido,false))) ORDER BY id LIMIT 1",{},{datasource='runner_dba'});
   REQUEST.businessIdentity={id=staff.id[1]};structDelete(REQUEST,'businessAccessContext',false);structDelete(SESSION,'businessAccessSelection',false);structDelete(SESSION,'businessSimulatedAccountId',false);
   existingTeam=queryExecute('SELECT id_team FROM rr_teams.team ORDER BY id_team LIMIT 1',{},{datasource='runner_dba'});
   if(existingTeam.recordCount){URL.team=existingTeam.id_team[1];URL.tab='equipe';}
   savecontent variable='globalHtml'{include '/administracao/teams/index.cfm';}
   if(!find('Gestão de Teams',globalHtml)||!find('/administracao/teams/',globalHtml)||!find('main-sidenav',globalHtml)||(existingTeam.recordCount&&(!find('Adicionar usuário existente',globalHtml)||!find('name="user_busca"',globalHtml))))throw(type='Teams.Test',message='Global shell missing');
   if(queryExecute('SELECT count(*) n FROM rr_teams_test.team',{},{datasource='runner_dba'}).n[1]!=0)throw(type='Teams.Test',message='Fixture not empty');
  }finally{transaction action='rollback';}
 }
 cfcontent(type='text/plain; charset=utf-8',reset=true);writeOutput('TEAMS_GLOBAL_PRODUCTION_PASSED');
}catch(any failed){cfheader(statuscode=500);cfcontent(type='text/plain; charset=utf-8',reset=true);writeOutput('FAILED ' & failed.type & ' ' & failed.message);if(structKeyExists(failed,'tagContext'))for(frame in failed.tagContext)writeOutput(chr(10)&frame.template&':'&frame.line);}
</cfscript>'''
baseline=json.loads((WORK/'baseline.json').read_text())['files'];items={k:{**manifest[k],'data':base64.b64encode(data).decode()} for k,data in files.items()}
result=ssh(REMOTE,{'items':items,'allowed':PATHS,'preserve':{rel:baseline[rel]['hash'] for rel in PRESERVE},'probe':PROBE});result['checked_at']=datetime.datetime.now(datetime.timezone.utc).isoformat();(WORK/'publication.json').write_text(json.dumps(result,indent=2)+'\n')
pubPath=ROOT/'_codex/teams/publication.json';pub=json.loads(pubPath.read_text());(WORK/'previous-publication.json').write_text(json.dumps(pub,indent=2)+'\n')
pub['candidate_hashes'].update({'business/'+k:v for k,v in result['hashes'].items()});pub['runtime_files']=len(pub['candidate_hashes']);pub['existing_user_publication']=result;pubPath.write_text(json.dumps(pub,indent=2)+'\n')
for rel,data in files.items():
 target=ROOT/'_codex/teams/release/business'/rel;target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(data)
print(json.dumps(result))
