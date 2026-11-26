"""Scoped Business release; no migrations, provider calls or user-data writes."""
from pathlib import Path
import base64,datetime,hashlib,json,shlex,subprocess,sys
ROOT=Path(__file__).resolve().parents[2];STAGE=ROOT/'_codex/staging/verified-pending-payments-20261124'
FILES=['services/VerifiedAdmin.cfc', 'portal/verificados/home.cfm', 'portal/verificados/verified.css','portal/verificados/evidence.cfm']
SSH=['ssh','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-o','ConnectTimeout=10','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
REMOTE=r'''
from pathlib import Path
import base64,hashlib,json,os,shutil,subprocess,sys,tempfile,time,signal
p=json.load(sys.stdin);root=Path('/var/www/business.roadrunners.run');sha=lambda b:hashlib.sha256(b).hexdigest();backup=None;changed=[];temp=None
allowed={'portal/verificados/home.cfm', 'services/VerifiedAdmin.cfc', 'portal/verificados/verified.css','portal/verificados/evidence.cfm'}
if set(p['files'])!=allowed:raise RuntimeError('Unexpected release scope')
if root.is_symlink() or root.resolve()!=root:raise RuntimeError('Unexpected root')
for rel,entry in p['files'].items():
 path=root/rel
 if path.is_symlink():raise RuntimeError('Symlink rejected')
 actual=sha(path.read_bytes()) if path.exists() else None
 if actual!=entry['before']:raise RuntimeError('Production changed: '+rel)
if not p['publish']:
 print(json.dumps({'ok':True,'mode':'preflight','files':len(allowed)}));sys.exit(0)
backup=Path(tempfile.mkdtemp(prefix='business-verified-pending-payments-',dir='/var/backups'));os.chmod(backup,0o700)
def write_atomic(path,data,uid,gid,mode):
 fd,tmp=tempfile.mkstemp(prefix='.verified-origins-',dir=path.parent)
 try:
  with os.fdopen(fd,'wb') as f:f.write(data);f.flush();os.fsync(f.fileno())
  os.chown(tmp,uid,gid);os.chmod(tmp,mode);os.replace(tmp,path)
 finally:
  if os.path.exists(tmp):os.unlink(tmp)
try:
 temp=Path(tempfile.mkdtemp(prefix='verified-compile-',dir=root/'_codex'));os.chmod(temp,0o755);(temp/'.htaccess').write_text('Require local\n')
 for rel,entry in p['files'].items():
  dest=temp/rel;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(base64.b64decode(entry['data']))
 compiled=temp/'compiled';compiled.mkdir();os.chmod(compiled,0o777)
 command=['/opt/coldfusion2025/cfusion/bin/cfcompile.sh','-deploy','-cfruntimeuser','coldfusion','-webroot',str(root),'-dir',str(temp),'-deploydir',str(compiled)]
 proc=subprocess.Popen(command,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,start_new_session=True)
 try:log,_=proc.communicate(timeout=60)
 except subprocess.TimeoutExpired:
  if os.getpgid(proc.pid)==proc.pid:os.killpg(proc.pid,signal.SIGTERM)
  proc.communicate(timeout=10);raise RuntimeError('Compiler timeout')
 (backup/'compile.log').write_bytes(log)
 if proc.returncode or b'Error compiling' in log or b'Error:' in log or b'Exception' in log:raise RuntimeError('Compilation failed; inspect private backup')
 manifest={}
 for rel,entry in p['files'].items():
  path=root/rel;current=sha(path.read_bytes()) if path.exists() else None
  if current!=entry['before']:raise RuntimeError('Production drift before write: '+rel)
  if path.exists():
   dest=backup/'before'/rel;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(path,dest);st=path.stat();uid,gid,mode=st.st_uid,st.st_gid,st.st_mode&0o777
  else:uid,gid,mode=0,0,0o644
  data=base64.b64decode(entry['data']);manifest[rel]={'before':current,'after':sha(data),'uid':uid,'gid':gid,'mode':mode}
  write_atomic(path,data,uid,gid,mode);changed.append(rel)
 for rel,entry in manifest.items():
  if sha((root/rel).read_bytes())!=entry['after']:raise RuntimeError('Hash mismatch '+rel)
 checks=[]
 for route,expected in [('/portal/verificados/',302),('/portal/includes/verified_backend.cfm',403),('/portal/verificados/home.cfm',403),('/portal/verificados/evidence.cfm',403),('/portal/verificados/verified.css',200),('/portal/verificados/verified.js',200)]:
  r=subprocess.run(['curl','-sS','--max-time','20','--resolve','business.roadrunners.run:443:127.0.0.1','-o','/dev/null','-w','%{http_code}','https://business.roadrunners.run'+route],capture_output=True,text=True,timeout=25)
  checks.append({'path':route,'status':r.stdout,'ok':r.returncode==0 and r.stdout==str(expected)})
 if not all(c['ok'] for c in checks):raise RuntimeError('HTTP checks failed '+json.dumps(checks))
 receipt={'ok':True,'backup':str(backup),'files':manifest,'http_checks':checks,'schema_changed':False,'entitlements_changed':False}
 (backup/'manifest.json').write_text(json.dumps(receipt,indent=2));print(json.dumps(receipt))
except Exception:
 for rel in reversed(changed):
  path=root/rel;old=backup/'before'/rel
  if old.exists():st=old.stat();write_atomic(path,old.read_bytes(),st.st_uid,st.st_gid,st.st_mode&0o777)
  else:path.unlink()
 raise
finally:
 if temp:
  shutil.rmtree(temp)
  if temp.exists():raise RuntimeError('Compile stage not removed')
'''
sha=lambda b:hashlib.sha256(b).hexdigest()
baseline=json.loads((STAGE/'baseline.json').read_text());publish='--publish' in sys.argv
proof=json.loads((STAGE/'release-proof.json').read_text())
assert proof['native']['ok'] and proof['native']['stage_removed']
assert proof['hashes']=={p:sha((ROOT/p).read_bytes()) for p in FILES},'Changed since testing'
assert (datetime.datetime.now(datetime.timezone.utc)-datetime.datetime.fromisoformat(proof['tested_at'])).total_seconds()<7200,'Stale tests'
payload={'publish':publish,'files':{p:{'before':baseline.get(p),'data':base64.b64encode((ROOT/p).read_bytes()).decode()} for p in FILES}}
r=subprocess.run(SSH+['python3 -c '+shlex.quote(REMOTE)],input=json.dumps(payload),capture_output=True,text=True,timeout=150)
if r.returncode:print(r.stderr[-3500:]);raise SystemExit(1)
result=json.loads(r.stdout)
if publish:(STAGE/'release.json').write_text(json.dumps(result,indent=2))
print(json.dumps(result,indent=2))
