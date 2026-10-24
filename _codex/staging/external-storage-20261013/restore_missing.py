"""Restore only the three missing private assets approved after the inventory."""
from pathlib import Path
import hashlib,io,json,shlex,subprocess,tarfile
SSH=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-i','/Users/leonardosobral/.ssh/webs']
OLD='root@172.233.26.63'; NEW='root@ssh.runnerhub.run'
TARGETS=['var/lib/runnerhub/reports/mif-2026','etc/roadrunners/credentials/medical-mail.json','var/lib/runnerhub-secrets/content-google-oauth.local.cfm']
BACKUP='/var/backups/external-storage-20261013'
def remote(host,command,data=None):
 return subprocess.run(SSH+[host,command],input=data,capture_output=True,check=True,timeout=60).stdout
def allowed(name):
 return any(name==t or name.startswith(t+'/') for t in TARGETS)
source='''from pathlib import Path
import hashlib,json
targets=TARGETS
out={}
for name in targets:
 p=Path('/')/name
 assert p.exists() and not p.is_symlink()
 for f in ([p] if p.is_file() else p.rglob('*')):
  assert not f.is_symlink()
  if f.is_file():out[str(f.relative_to('/'))]=hashlib.sha256(f.read_bytes()).hexdigest()
print(json.dumps(out))'''.replace('targets=TARGETS','targets='+repr(TARGETS))
manifest=json.loads(remote(OLD,'python3 -c '+shlex.quote(source)))
archive=remote(OLD,'tar -czf - -C / '+' '.join(map(shlex.quote,TARGETS)))
with tarfile.open(fileobj=io.BytesIO(archive),mode='r:gz') as tf:
 found={}
 for m in tf.getmembers():
  assert allowed(m.name) and '..' not in Path(m.name).parts and (m.isfile() or m.isdir())
  if m.isfile():found[m.name]=hashlib.sha256(tf.extractfile(m).read()).hexdigest()
assert found==manifest
guard=' && '.join('test ! -e /'+t+' && test ! -L /'+t for t in TARGETS)
remote(NEW,guard+' && umask 077 && mkdir '+BACKUP+' && cat > '+BACKUP+'/private-assets.tar.gz',archive)
remote(NEW,'umask 077 && cat > '+BACKUP+'/source-sha256.json',json.dumps(manifest).encode())
restore='''
from pathlib import Path
import hashlib,json,os,pwd,shutil,tarfile
targets=TARGETS
b=Path('/var/backups/external-storage-20261013');stage=b/'stage';stage.mkdir(mode=0o700)
expected=json.loads((b/'source-sha256.json').read_text());gid=pwd.getpwnam('coldfusion').pw_gid
def allowed(n):return any(n==t or n.startswith(t+'/') for t in targets)
for t in targets:assert not (Path('/')/t).exists() and not (Path('/')/t).is_symlink()
with tarfile.open(b/'private-assets.tar.gz') as tf:
 for m in tf.getmembers():assert allowed(m.name) and '..' not in Path(m.name).parts and (m.isfile() or m.isdir())
 tf.extractall(stage,filter='data')
actual={str(p.relative_to(stage)):hashlib.sha256(p.read_bytes()).hexdigest() for p in stage.rglob('*') if p.is_file()}
assert actual==expected
for t in targets:
 src=stage/t;dst=Path('/')/t
 missing=[];parent=dst.parent
 while not parent.exists():missing.append(parent);parent=parent.parent
 assert not parent.is_symlink()
 for p in reversed(missing):p.mkdir(mode=0o750);os.chown(p,0,gid)
 for p in [src]+(list(src.rglob('*')) if src.is_dir() else []):
  os.chown(p,0,gid);os.chmod(p,0o750 if p.is_dir() else 0o640)
 assert not dst.exists() and not dst.is_symlink()
 src.rename(dst)
shutil.rmtree(stage)
verified=all(hashlib.sha256((Path('/')/p).read_bytes()).hexdigest()==h for p,h in expected.items())
assert verified
report={'targets':['/'+t for t in targets],'files':len(expected),'hashes_match':verified,'backup':str(b),'owner':'root:coldfusion','file_mode':'0640','directory_mode':'0750'}
(b/'restoration.json').write_text(json.dumps(report,indent=2));print(json.dumps(report,indent=2))
'''.replace('targets=TARGETS','targets='+repr(TARGETS))
result=remote(NEW,'python3 -c '+shlex.quote(restore))
Path(__file__).with_name('restoration.json').write_bytes(result)
print(result.decode())
