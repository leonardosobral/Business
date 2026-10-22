"""Scoped atomic publication of the approved Business -> DEV support login."""
import datetime,hashlib,json,pathlib,shlex,subprocess,sys

ROOT=pathlib.Path(__file__).resolve().parents[2]
BASELINES={
 'services/BusinessDevLogin.cfc':None,
 'administracao/usuarios/includes/backend.cfm':'b8b3087c12c18cf50106943009141778182a400d37447e28caf0e09c2c9a3297',
 'administracao/usuarios/home.cfm':'9874809c2921da2b4fd4f674fa9684ced0be680ab1c7cb0f4f5b44c92b7e7b13',
}
tests=json.loads((ROOT/'_codex/deploy/dev-login-tests-20261021.json').read_text())
age=datetime.datetime.now(datetime.timezone.utc)-datetime.datetime.fromisoformat(tests['checked_at'])
if not(tests.get('ok') and tests.get('checks',0)>=45 and tests.get('stage_removed')
 and len(tests.get('render_checks',[]))==4 and all(case.get('ok') for case in tests['render_checks'])
 and 0<=age.total_seconds()<3600):raise SystemExit('Fresh successful native evidence is required')
for name in BASELINES:
 if tests['files'].get(name)!=hashlib.sha256((ROOT/name).read_bytes()).hexdigest():raise SystemExit('Candidate changed after tests: '+name)
subprocess.run(['node',str(ROOT/'_codex/scripts/test_dev_login_confirmation.mjs')],check=True,capture_output=True)
patch=json.loads((ROOT/'_codex/patches/dev-login-receiver-identity.json').read_text())
if patch['baseline']!=tests['dev_receiver_baseline']:raise SystemExit('Receiver baseline differs from tests')
payload={'files':{name:{'baseline':baseline,'content':(ROOT/name).read_text()} for name,baseline in BASELINES.items()},
 'patch':patch,'receiver_after':tests['dev_receiver_sha256']}
REMOTE=r'''
import hashlib,json,os,pathlib,re,stat,subprocess,sys,tempfile
payload=json.load(sys.stdin);root=pathlib.Path('/var/www/business.roadrunners.run')
allowed={'services/BusinessDevLogin.cfc','administracao/usuarios/includes/backend.cfm','administracao/usuarios/home.cfm'}
def sha(raw):return hashlib.sha256(raw).hexdigest()
def current(path):return sha(path.read_bytes()) if path.exists() else None
def atomic(target,raw,meta):
 fd,name=tempfile.mkstemp(prefix='.dev-login-',suffix=target.suffix,dir=target.parent)
 with os.fdopen(fd,'wb') as stream:
  stream.write(raw);stream.flush();os.fsync(stream.fileno());os.fchmod(stream.fileno(),meta['mode']);os.fchown(stream.fileno(),meta['uid'],meta['gid'])
 os.replace(name,target)
def request(host,path):
 headers=backup/('headers-'+host+'.txt')
 proc=subprocess.run(['curl','--silent','--show-error','--max-time','30','--resolve',host+':443:127.0.0.1',
  '--dump-header',str(headers),'--write-out','\n%{http_code}','https://'+host+path],capture_output=True,timeout=35)
 os.chmod(headers,0o600)
 if proc.returncode:raise RuntimeError('Runtime request failed: '+host)
 body,_,code=proc.stdout.rpartition(b'\n')
 if not code.isdigit():raise RuntimeError('Missing HTTP status: '+host)
 if re.search(r'(?im)^set-cookie:\s*(?:id|name|email|tag)=',headers.read_text()):raise RuntimeError('Anonymous request received an identity cookie: '+host)
 return int(code)
backup=None;state={};installed=[];candidates={}
try:
 if set(payload['files'])!=allowed:raise RuntimeError('Unexpected publication scope')
 for relative,item in payload['files'].items():candidates['business/'+relative]={'path':root/relative,**item}
 patch=payload['patch'];dev=pathlib.Path('/var/www/dev.roadrunners.run/Application.cfc')
 if patch['path']!=str(dev) or current(dev)!=patch['baseline']:raise RuntimeError('DEV baseline conflict')
 source=dev.read_text()
 if source.count(patch['before'])!=1:raise RuntimeError('DEV patch context changed')
 candidate=source.replace(patch['before'],patch['after'],1)
 if sha(candidate.encode())!=payload['receiver_after']:raise RuntimeError('DEV candidate differs from tested source')
 candidates['dev/Application.cfc']={'path':dev,'baseline':patch['baseline'],'content':candidate}
 for label,item in candidates.items():
  path=item['path']
  if path.is_symlink() or path.parent.resolve()!=path.parent:raise RuntimeError('Unsafe runtime path')
  before=current(path)
  if before!=item['baseline']:raise RuntimeError('Production baseline conflict: '+label)
  if path.exists():
   info=path.stat()
   if not stat.S_ISREG(info.st_mode):raise RuntimeError('Target is not a regular file')
   meta={'mode':stat.S_IMODE(info.st_mode),'uid':info.st_uid,'gid':info.st_gid}
  else:meta={'mode':0o644,'uid':0,'gid':0}
  state[label]={'path':str(path),'before':before,'after':sha(item['content'].encode()),**meta}
 backup=pathlib.Path(tempfile.mkdtemp(prefix='business-dev-login-20261021-',dir='/var/backups'));os.chmod(backup,0o700)
 for label,item in candidates.items():
  saved=backup/label;saved.parent.mkdir(parents=True,exist_ok=True)
  if state[label]['before'] is not None:
   original=saved.with_name(saved.name+'.before');original.write_bytes(item['path'].read_bytes());os.chmod(original,0o600)
  output=saved.with_name(saved.name+'.candidate');output.write_text(item['content']);os.chmod(output,0o600)
 manifest=backup/'manifest.json';manifest.write_text(json.dumps(state));os.chmod(manifest,0o600)
 order=['business/services/BusinessDevLogin.cfc','dev/Application.cfc','business/administracao/usuarios/includes/backend.cfm','business/administracao/usuarios/home.cfm']
 for label in order:
  item=candidates[label]
  if current(item['path'])!=state[label]['before']:raise RuntimeError('Concurrent runtime change: '+label)
  atomic(item['path'],item['content'].encode(),state[label]);installed.append(label)
 statuses={}
 statuses['business_anonymous']=request('business.roadrunners.run','/administracao/usuarios/')
 if statuses['business_anonymous'] not in (302,303,401,403):raise RuntimeError('Manager anonymous-access guard failed')
 statuses['dev_invalid_token']=request('dev.roadrunners.run','/?action=handoff_consume&token=invalid')
 statuses['prod_invalid_token']=request('roadrunners.run','/?action=handoff_consume&token=invalid')
 if statuses['dev_invalid_token'] not in (302,303) or statuses['prod_invalid_token'] not in (302,303):raise RuntimeError('Invalid-token runtime guard failed')
 for label,item in candidates.items():
  if current(item['path'])!=state[label]['after']:raise RuntimeError('Published checksum mismatch: '+label)
 result={'ok':True,'backup':str(backup),'files':state,'http':statuses,'credentials_changed':False,'schema_changed':False,'production_rr_files_changed':False}
except Exception as failure:
 restored=[]
 if backup:
  for label in reversed(installed):
   item=candidates[label];path=item['path']
   if current(path)!=state[label]['after']:continue
   if state[label]['before'] is None:
    withdrawn=backup/'withdrawn'/label;withdrawn.parent.mkdir(parents=True,exist_ok=True);path.rename(withdrawn)
   else:
    saved=backup/label;atomic(path,saved.with_name(saved.name+'.before').read_bytes(),state[label])
   restored.append(label)
 result={'ok':False,'error':str(failure) if isinstance(failure,RuntimeError) else 'Publication failed; inspect private backup','backup':str(backup) if backup else None,'restored':restored}
print(json.dumps(result))
if not result['ok']:sys.exit(1)
'''
proc=subprocess.run(['ssh','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-o','ConnectTimeout=12','rr-prod',
 'python3 -c '+shlex.quote(REMOTE)],input=json.dumps(payload).encode(),capture_output=True,timeout=130)
try:result=json.loads(proc.stdout)
except Exception:result={'ok':False,'error':'Publication transport failed; output suppressed'}
if result.get('ok'):
 result['tests']=tests
 (ROOT/'_codex/deploy/dev-login-20261021.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
print(json.dumps(result,ensure_ascii=False))
if proc.returncode or not result.get('ok'):sys.exit(1)
