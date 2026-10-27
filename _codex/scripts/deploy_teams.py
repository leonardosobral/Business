"""Teams-only release: prepare, verify, preflight, publish. No DDL or Git mutations."""
import base64,datetime,hashlib,importlib.util,json,pathlib,shlex,subprocess,sys
ROOT=pathlib.Path(__file__).resolve().parents[2];WORK=ROOT/'_codex/teams';RELEASE=WORK/'release';MODE=sys.argv[1]
SHARED=['business/index.cfm','business/includes/estrutura/sidenav.cfm','business/includes/backend/business_google_callback.cfm','business/services/accountDelegation/RequestBoundary.cfc','rr/atleta/index.cfm','rr/includes/estrutura/header.cfm']
sha=lambda b:hashlib.sha256(b).hexdigest()
def read_json(p):return json.loads(p.read_text())
def sources():
 files={}
 for folder in ['teams','services/teams']:
  for p in (ROOT/folder).rglob('*'):
   if p.is_file() and (p.suffix in ['.cfm','.cfc','.css','.js','.txt','.svg'] or p.name=='.htaccess'):files['business/'+str(p.relative_to(ROOT))]=p.read_bytes()
 for p in (WORK/'roadrunners/teams').rglob('*'):
  if p.is_file():files['rr/teams/'+str(p.relative_to(WORK/'roadrunners/teams'))]=p.read_bytes()
 for p in (ROOT/'services/teams').iterdir():
  if p.is_file() and p.name not in ['Mailer.cfc','EmailTransport.cfc']:files['rr/services/teams/'+p.name]=p.read_bytes()
 for p in (ROOT/'teams/assets').iterdir():
  if p.is_file():files['rr/teams/assets/'+p.name]=p.read_bytes()
 spec=importlib.util.spec_from_file_location('teams_patch',WORK/'patch_shared.py');patch=importlib.util.module_from_spec(spec);spec.loader.exec_module(patch)
 for rel in SHARED:files[rel]=patch.patch(rel,(WORK/'baseline/production'/rel).read_text(encoding='utf-8-sig')).encode()
 return files
if MODE=='prepare':
 baseline=read_json(WORK/'production-baseline.json')['files'];files=sources();manifest={}
 previous=read_json(WORK/'publication.json') if (WORK/'publication.json').exists() else {}
 prior=previous.get('candidate_hashes',{}) if previous.get('ok') else {}
 for rel,data in files.items():
  dest=RELEASE/rel;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(data)
  manifest[rel]={'before':prior.get(rel,baseline.get(rel,{}).get('hash')),'after':sha(data)}
 (WORK/'release-manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
 print(json.dumps({'ok':True,'runtime_files':len(manifest),'shared_patches':len(SHARED)}));raise SystemExit(0)
manifest=read_json(WORK/'release-manifest.json');current=sources()
if set(manifest)!=set(current) or any(sha(current[k])!=v['after'] for k,v in manifest.items()):raise SystemExit('Candidates changed: prepare and verify again')
if MODE=='verify':
 results=[]
 for script,arg in [('test_teams_native.py','source'),('test_teams_native.py','native'),('test_teams_native.py','security'),('test_teams_native.py','identity'),('test_teams_native.py','boundary'),('test_teams_native.py','metrics'),('test_teams_native.py','mailer'),('test_teams_native.py','transport'),('test_teams_native.py','render'),('test_teams_http.py','http'),('test_teams_http.py','concurrency'),('check_teams.py','compile')]:
  run=subprocess.run([sys.executable,'-B',str(ROOT/'_codex/scripts'/script),arg],capture_output=True,text=True,timeout=260)
  try:result=json.loads(run.stdout)
  except ValueError:raise SystemExit('Verification transport failed: '+arg+' '+run.stderr[-300:])
  if run.returncode or not result.get('ok'):print(json.dumps(result));raise SystemExit('Failed '+arg)
  results.append({'suite':script+':'+arg,'result':result})
 if any(sha(v)!=manifest[k]['after'] for k,v in sources().items()):raise SystemExit('Sources changed during verification')
 proof={'checked_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'hashes':{k:v['after'] for k,v in manifest.items()},'tests':results}
 (WORK/'verification.json').write_text(json.dumps(proof,ensure_ascii=False,indent=2)+'\n')
 print(json.dumps({'ok':True,'suites':len(results)}));raise SystemExit(0)
publish=MODE=='publish'
if MODE not in ['publish','preflight']:raise SystemExit('Unknown mode')
if publish:
 proof=read_json(WORK/'verification.json');age=(datetime.datetime.now(datetime.timezone.utc)-datetime.datetime.fromisoformat(proof['checked_at'])).total_seconds()
 if not 0<=age<3600 or proof['hashes']!={k:v['after'] for k,v in manifest.items()}:raise SystemExit('Fresh matching verification required')
REMOTE=r"""
import base64,hashlib,json,os,pathlib,stat,subprocess,sys,tempfile
p=json.load(sys.stdin);root=pathlib.Path('/var/www');sites={'business':'business.roadrunners.run','rr':'roadrunners.com.br'};sha=lambda b:hashlib.sha256(b).hexdigest()
shared=set(p['shared']);items=p['items'];preserved={}
def target(rel):
 site,path=rel.split('/',1)
 if site not in sites or not (path.startswith('teams/') or path.startswith('services/teams/') or rel in shared):raise RuntimeError('Path outside Teams scope')
 dest=root/sites[site]/path
 if dest.is_symlink() or root/sites[site] not in dest.resolve().parents:raise RuntimeError('Unsafe target')
 return dest
for rel in p['preserve']:
 site,path=rel.split('/',1);dest=root/sites[site]/path
 if dest.is_file():preserved[rel]=sha(dest.read_bytes())
for i in items:
 dest=target(i['path']);old=dest.read_bytes() if dest.exists() else None
 if (sha(old) if old is not None else None)!=i['before']:raise RuntimeError('Production baseline conflict: '+i['path'])
 data=base64.b64decode(i['data'],validate=True)
 if sha(data)!=i['after']:raise RuntimeError('Candidate digest mismatch')
 i['old']=old;i['bytes']=data
if not p['publish']:print(json.dumps({'ok':True,'mode':'preflight','files':len(items),'preserved_dependencies':len(preserved)}));sys.exit(0)
backup=pathlib.Path(tempfile.mkdtemp(prefix='rr-teams-release-',dir='/var/backups'));os.chmod(backup,0o700)
written=[];metadata={};checks=[]
def atomic(dest,data,info):
 dest.parent.mkdir(parents=True,exist_ok=True,mode=0o755)
 fd,tmp=tempfile.mkstemp(prefix='.teams-',dir=dest.parent)
 try:
  with os.fdopen(fd,'wb') as stream:
   stream.write(data);stream.flush();os.fsync(stream.fileno());os.fchmod(stream.fileno(),stat.S_IMODE(info.st_mode));os.fchown(stream.fileno(),info.st_uid,info.st_gid)
  os.replace(tmp,dest)
 finally:
  if os.path.exists(tmp):os.unlink(tmp)
def dependency_check():
 for rel,digest in preserved.items():
  site,path=rel.split('/',1)
  if sha((root/sites[site]/path).read_bytes())!=digest:raise RuntimeError('Dependency changed: '+rel)
try:
 for i in items:
  rel=i['path'];dest=target(rel);old=dest.read_bytes() if dest.exists() else None
  if (sha(old) if old is not None else None)!=i['before']:raise RuntimeError('Concurrent production change: '+rel)
  if old==i['bytes']:continue
  site=rel.split('/',1)[0];info=dest.stat() if dest.exists() else (root/sites[site]/'index.cfm').stat();metadata[rel]=info
  if old is not None:
   saved=backup/'before'/rel;saved.parent.mkdir(parents=True,exist_ok=True);saved.write_bytes(old);os.chmod(saved,0o600)
  atomic(dest,i['bytes'],info);written.append(i)
 probes=[
 ('business','/teams/','GET',200,'Road Runners Teams'),
 ('business','/teams/cadastro/','GET',200,'Seu time tem lugar aqui.'),
 ('rr','/teams/','GET',200,'Qual é o seu time?'),
 ('rr','/teams/meu-team/','GET',302,''),
 ('rr','/teams/entrar/','GET',200,'name="credential"'),
 ('rr','/teams/?team=teams-release-nonexistent','GET',404,''),
 ('business','/teams/mail-worker.cfm','GET',405,''),
 ('business','/teams/mail-worker.cfm','POST',401,''),
 ('business','/teams/includes/start.cfm','GET',403,''),
 ('rr','/teams/includes/start.cfm','GET',403,''),
 ('business','/teams/assets/qrcode.js','GET',200,'qrcode'),
 ('business','/teams/assets/teams.css','GET',200,'--business-panel')]
 for site,path,method,expected,required in probes:
  host='business.roadrunners.run' if site=='business' else 'roadrunners.run'
  args=['curl','-sS','--max-time','30','--resolve',host+':443:127.0.0.1','--request',method,'--write-out','\n%{http_code}','https://'+host+path]
  run=subprocess.run(args,capture_output=True,timeout=35);body,_,status=run.stdout.rpartition(b'\n');ok=not run.returncode and status==str(expected).encode() and required in body.decode(errors='replace') and b'Teams em prepara' not in body
  checks.append({'site':site,'path':path,'method':method,'status':status.decode(),'ok':ok})
  if not ok:
   (backup/'failed-response.txt').write_bytes(body);raise RuntimeError('Live probe failed: '+site+path)
 dependency_check()
 if any(sha(target(i['path']).read_bytes())!=i['after'] for i in items):raise RuntimeError('Published digest mismatch')
 result={'ok':True,'mode':'published','backup':str(backup),'runtime_files':len(items),'candidate_hashes':{i['path']:i['after'] for i in items},'preserved_files':preserved,'probes':checks,'ddl':False,'git_mutations':False}
except Exception as e:
 restored=[]
 for i in reversed(written):
  dest=target(i['path'])
  if not dest.is_file() or sha(dest.read_bytes())!=i['after']:restored.append({'path':i['path'],'ok':False});continue
  if i['old'] is None:
   withdrawn=backup/'withdrawn'/i['path'];withdrawn.parent.mkdir(parents=True,exist_ok=True);dest.rename(withdrawn)
  else:atomic(dest,i['old'],metadata[i['path']])
  restored.append({'path':i['path'],'ok':True})
 result={'ok':False,'backup':str(backup),'reason':str(e),'rollback':restored,'probes':checks}
(backup/'receipt.json').write_text(json.dumps(result,indent=2));os.chmod(backup/'receipt.json',0o600)
print(json.dumps(result));sys.exit(0 if result['ok'] else 1)
"""
def priority(rel):
 if rel in SHARED:return 5
 if '/services/' in rel:return 0
 if '/assets/' in rel:return 1
 if '/includes/' in rel:return 2
 return 3
items=[{'path':k,'before':manifest[k]['before'],'after':manifest[k]['after'],'data':base64.b64encode((RELEASE/k).read_bytes()).decode()} for k in sorted(manifest,key=lambda k:(priority(k),k))]
preserve=['business/Application.cfc','business/includes/backend/backend_login.cfm','business/includes/backend/business_account_context.cfm','business/includes/backend/cron_jobs_service.cfm','business/services/BusinessAuthSession.cfc','business/assets/css/business-ui.css','business/emailmkt/EmailSenderService.cfc','rr/Application.cfc','rr/includes/backend/backend_login.cfm','rr/services/ComparadorIdentityProtocol.cfc','rr/services/ComparadorIdentityAccounts.cfc','rr/services/ComparadorGoogleIdentityVerifier.cfc','rr/sso/comparador/_portal_nonce.cfm']
run=subprocess.run(['ssh','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-o','ConnectTimeout=12','rr-prod','python3 -c '+shlex.quote(REMOTE)],input=json.dumps({'publish':publish,'shared':SHARED,'items':items,'preserve':preserve}).encode(),capture_output=True,timeout=460)
try:result=json.loads(run.stdout)
except ValueError:result={'ok':False,'error':run.stderr.decode(errors='replace')[-2000:]}
(WORK/('publication.json' if publish else 'preflight.json')).write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
print(json.dumps({k:v for k,v in result.items() if k not in ['candidate_hashes','preserved_files']},ensure_ascii=False));raise SystemExit(0 if not run.returncode and result.get('ok') else 1)
