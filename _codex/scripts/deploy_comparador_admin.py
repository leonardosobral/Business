"""Release only the five reviewed Comparador Business runtime files; no SQL or auth bypass.

Default: read-only preflight. `publish` backs up, deploys, verifies and runs anonymous
smokes, rolling back on failure. `rollback --release ID` restores only unchanged
release files. The same module is sent over SSH; no script is installed in webroot.
"""
import argparse,base64,datetime,hashlib,json,os,pathlib,re,shlex,shutil,subprocess,sys,tempfile,urllib.error,urllib.parse,urllib.request,uuid
PATHS=('services/ComparadorAdminService.cfc','administracao/comparador/includes/backend.cfm','administracao/comparador/home.cfm','administracao/comparador/index.cfm','includes/estrutura/sidenav.cfm')
PRODUCTION=pathlib.Path('/var/www/business.roadrunners.run')
BACKUPS=pathlib.Path('/var/backups/business-comparador-admin-20261016')
MANIFEST='_codex/docs/2026-10-16_comparador_manifest.json'
SSH=['ssh','-oBatchMode=yes','-oConnectTimeout=15','root@ssh.runnerhub.run']
def digest(path):return hashlib.sha256(path.read_bytes()).hexdigest() if path.exists() else None
def valid_release(value):
 if not re.fullmatch(r'[0-9]{8}T[0-9]{6}Z-[0-9a-f]{8}',value):raise ValueError('Invalid release ID')
 return value
def checked(root,name):
 path=root/name
 if name not in PATHS or path.is_symlink() or not path.resolve().is_relative_to(root.resolve()):raise ValueError('Invalid release path')
 return path
def validate_payload(payload):
 if set(payload.get('files',{}))!=set(PATHS):raise ValueError('Release scope must contain exactly the five reviewed runtime files')
 for name,item in payload['files'].items():
  data=base64.b64decode(item['data'],validate=True)
  if hashlib.sha256(data).hexdigest()!=item['after']:raise RuntimeError('Candidate checksum mismatch: '+name)
  if item['before'] is not None and not re.fullmatch('[a-f0-9]{64}',item['before']):raise ValueError('Invalid baseline')
def preflight(root,payload):
 validate_payload(payload);result={}
 for name,item in payload['files'].items():
  current=digest(checked(root,name))
  if current!=item['before']:raise RuntimeError('Production baseline changed: '+name)
  result[name]=current
 return {'status':'baseline_verified','files':result}
def write_json(path,value):
 encoded=(json.dumps(value,ensure_ascii=False,indent=2)+'\n').encode();fd,tmp=tempfile.mkstemp(prefix='.receipt-',dir=path.parent)
 try:
  with os.fdopen(fd,'wb') as stream:stream.write(encoded);stream.flush();os.fsync(stream.fileno())
  os.chmod(tmp,0o600);os.replace(tmp,path)
 finally:
  if os.path.exists(tmp):os.unlink(tmp)
def atomic(path,data,attributes,exclusive=False):
 fd,tmp=tempfile.mkstemp(prefix='.comparador-release-',dir=path.parent)
 try:
  with os.fdopen(fd,'wb') as stream:stream.write(data);stream.flush();os.fsync(stream.fileno())
  os.chmod(tmp,attributes['mode']);os.chown(tmp,attributes['uid'],attributes['gid'])
  if exclusive:os.link(tmp,path)
  else:os.replace(tmp,path)
 finally:
  if os.path.exists(tmp):os.unlink(tmp)
def attrs(path):
 stat=path.stat();return {'uid':stat.st_uid,'gid':stat.st_gid,'mode':stat.st_mode & 0o777}
def verify(root,folder):
 receipt=json.loads((folder/'receipt.json').read_text());observed={}
 for name,item in receipt['files'].items():
  value=digest(checked(root,name));observed[name]=value
  if value!=item['after']:raise RuntimeError('Published checksum mismatch: '+name)
 return {'status':'hashes_verified','files':observed}
def rollback(root,folder):
 receipt=json.loads((folder/'receipt.json').read_text());states={}
 if set(receipt['files'])!=set(PATHS):raise RuntimeError('Unexpected backup scope')
 # Check the entire set before changing any file; never overwrite another release.
 for name,item in receipt['files'].items():
  current=digest(checked(root,name));states[name]=current
  if current not in (item['before'],item['after']):raise RuntimeError('Rollback blocked by newer work: '+name)
  if item['before'] is not None and digest(folder/'before'/name)!=item['before']:raise RuntimeError('Backup checksum mismatch: '+name)
 for name in reversed(PATHS):
  item=receipt['files'][name];target=checked(root,name)
  if states[name]==item['before']:continue
  if item['before'] is None:target.unlink()
  else:atomic(target,(folder/'before'/name).read_bytes(),item['attributes'])
 for name in sorted(receipt.get('created_directories',[]),key=len,reverse=True):
  path=root/name
  if path.resolve().is_relative_to(root.resolve()):
   try:path.rmdir()
   except OSError:pass
 for name,item in receipt['files'].items():
  if digest(checked(root,name))!=item['before']:raise RuntimeError('Rollback verification failed: '+name)
 receipt['status']='rolled_back';receipt['rolled_back_at']=datetime.datetime.now(datetime.timezone.utc).isoformat();write_json(folder/'receipt.json',receipt);return receipt
def deploy(root,backup_root,payload,release_id):
 valid_release(release_id);preflight(root,payload)
 backup_root.mkdir(parents=True,exist_ok=True);os.chmod(backup_root,0o700)
 folder=backup_root/release_id;folder.mkdir(mode=0o700)
 receipt={'status':'prepared','created_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'root':str(root),'backup':str(folder),'files':{},'changed':[],'created_directories':[]}
 for name in PATHS:
  target=checked(root,name);item=payload['files'][name];reference=target if target.exists() else root/'includes/estrutura/sidenav.cfm'
  receipt['files'][name]={'before':item['before'],'after':item['after'],'attributes':attrs(reference)}
  if target.exists():
   original=folder/'before'/name;original.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(target,original)
   if digest(original)!=item['before']:raise RuntimeError('Backup verification failed: '+name)
 write_json(folder/'receipt.json',receipt)
 try:
  preflight(root,payload)
  for name in PATHS:
   target=checked(root,name);item=payload['files'][name]
   missing=[];parent=target.parent
   while not parent.exists():missing.append(parent);parent=parent.parent
   directory_attributes=attrs(parent)
   for directory in reversed(missing):
    directory.mkdir(mode=0o755);os.chown(directory,directory_attributes['uid'],directory_attributes['gid']);receipt['created_directories'].append(str(directory.relative_to(root)))
   if digest(target)!=item['before']:raise RuntimeError('Target changed before replacement: '+name)
   atomic(target,base64.b64decode(item['data']),receipt['files'][name]['attributes'],exclusive=item['before'] is None)
   receipt['changed'].append(name);write_json(folder/'receipt.json',receipt)
  verify(root,folder);receipt['status']='published';receipt['published_at']=datetime.datetime.now(datetime.timezone.utc).isoformat();write_json(folder/'receipt.json',receipt)
  return receipt
 except Exception:
  rollback(root,folder);raise
class NoRedirect(urllib.request.HTTPRedirectHandler):
 def redirect_request(self,*args,**kwargs):return None
def smokes():
 opener=urllib.request.build_opener(NoRedirect());cases=[
  ('anonymous_page','/administracao/comparador/','login'),
  ('direct_backend','/administracao/comparador/includes/backend.cfm','forbidden'),
  ('direct_view','/administracao/comparador/home.cfm','forbidden'),
  ('cfc_nonremote','/services/ComparadorAdminService.cfc?method=offerUrl&value=https%3A%2F%2Fexample.invalid%2Fcomparador-probe&returnformat=json','nonremote')]
 results=[]
 for label,path,kind in cases:
  request=urllib.request.Request('https://business.roadrunners.run'+path,headers={'User-Agent':'RunnerHub-Comparador-release-check/20261016','Cache-Control':'no-cache'})
  try:
   with opener.open(request,timeout=30) as response:status=response.status;body=response.read(250000);headers=response.headers
  except urllib.error.HTTPError as response:status=response.code;body=response.read(250000);headers=response.headers
  location=headers.get('Location','');login=status in (302,303) and urllib.parse.urlsplit(location).path=='/'
  passed=login if kind=='login' else (status==403 if kind=='forbidden' else status in (400,401,403,404,405,500) or login)
  # A successful plain return would demonstrate accidental remote method exposure.
  if kind=='nonremote' and status==200:passed=False
  results.append({'name':label,'path':path,'status':status,'location':location,'body_sha256':hashlib.sha256(body).hexdigest(),'passed':passed})
 return results
def invoke_remote(payload):
 source=pathlib.Path(__file__).read_text();command='python3 -c '+shlex.quote(source)+' --remote'
 run=subprocess.run(SSH+[command],input=json.dumps(payload),capture_output=True,text=True,timeout=180)
 if run.returncode:raise RuntimeError(run.stderr[-3000:] or 'Remote release failed')
 return json.loads(run.stdout)
def local_payload(root):
 manifest=json.loads((root/MANIFEST).read_text());items={item['path']:item for item in manifest['runtime']}
 if set(items)!=set(PATHS):raise RuntimeError('Manifest runtime scope changed')
 files={}
 for name in PATHS:
  data=(root/name).read_bytes();expected=items[name]
  if hashlib.sha256(data).hexdigest()!=expected['sha256']:raise RuntimeError('Reviewed source changed: '+name)
  files[name]={'data':base64.b64encode(data).decode(),'after':expected['sha256'],'before':expected['production_baseline_sha256']}
 return {'files':files}
def remote_main():
 import fcntl
 payload=json.load(sys.stdin);mode=payload['mode']
 if mode=='preflight':result=preflight(PRODUCTION,payload)
 else:
  valid_release(payload['release']);folder=BACKUPS/payload['release']
  with open('/var/lock/business-comparador-admin-20261016.lock','w') as lock:
   fcntl.flock(lock,fcntl.LOCK_EX)
   if mode=='publish':result=deploy(PRODUCTION,BACKUPS,payload,payload['release'])
   elif mode=='rollback':result=rollback(PRODUCTION,folder)
   elif mode=='verify':result=verify(PRODUCTION,folder)
   else:raise ValueError('Unknown operation')
 print(json.dumps(result,ensure_ascii=False))
def main():
 parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('mode',nargs='?',choices=['preflight','publish','verify','rollback'],default='preflight');parser.add_argument('--release');args=parser.parse_args()
 root=pathlib.Path(__file__).resolve().parents[2];report_path=root/'_codex/docs/2026-10-16_comparador_publicacao.json'
 if args.mode in ('rollback','verify'):
  if not args.release:parser.error('--release is required')
  report=invoke_remote({'mode':args.mode,'release':valid_release(args.release)})
  if args.mode=='verify':report['smokes']=smokes()
  print(json.dumps(report,ensure_ascii=False,indent=2));return
 payload=local_payload(root);payload['mode']=args.mode
 if args.mode=='preflight':print(json.dumps(invoke_remote(payload),ensure_ascii=False,indent=2));return
 release_id=datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%SZ')+'-'+uuid.uuid4().hex[:8];payload['release']=release_id
 report={'release':release_id,'backup':str(BACKUPS/release_id),'status':'starting','runtime_paths':list(PATHS)}
 write_json(report_path,report)
 try:
  report['remote']=invoke_remote(payload);report['hash_verification']=invoke_remote({'mode':'verify','release':release_id});report['smokes']=smokes()
  if not all(item['passed'] for item in report['smokes']):raise RuntimeError('Anonymous smoke verification failed')
  report['status']='published_verified';report['verified_at']=datetime.datetime.now(datetime.timezone.utc).isoformat()
 except Exception as error:
  report['status']='failed';report['error']=str(error)
  try:report['rollback']=invoke_remote({'mode':'rollback','release':release_id});report['status']='rolled_back'
  except Exception as rollback_error:report['rollback_error']=str(rollback_error)
  write_json(report_path,report);print(json.dumps(report,ensure_ascii=False,indent=2));raise SystemExit(1)
 write_json(report_path,report);print(json.dumps(report,ensure_ascii=False,indent=2))
if __name__=='__main__':
 if '--remote' in sys.argv:remote_main()
 else:main()
