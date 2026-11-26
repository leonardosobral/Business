"""Archive original exports outside both the repo and the web document root."""
from pathlib import Path
import base64, hashlib, json, os, shlex, shutil, subprocess, sys
S=Path(__file__).resolve().parent
source=Path('/private/tmp/semrush-archive-20261104-1240')
local=Path('/Users/Shared/RunnerHubReports/seo/semrush/20261104-final-20000')
mode=sys.argv[1]
assert mode in ('local','remote','verify')
if mode=='local':
 local.mkdir(mode=0o700,parents=True,exist_ok=True)
 for folder in ['raw','normalized']:
  (local/folder).mkdir(mode=0o700,exist_ok=True)
  for p in (source/folder).glob('*'):
   if not p.is_file():continue
   target=local/folder/p.name
   if target.exists():assert target.read_bytes()==p.read_bytes(), 'Existing archive conflict: '+p.name
   else:shutil.copy2(p,target)
   target.chmod(0o600)
 print(json.dumps({'archive':str(local),'files':len(list(local.rglob('*.csv')))}));sys.exit()
files={}
for p in (local/'normalized').glob('*.json'):files[p.name]=p
for p in (local/'raw').glob('*.csv'):files['raw/'+p.name]=p
payload={'mode':mode,'hashes':{n:hashlib.sha256(p.read_bytes()).hexdigest() for n,p in files.items()}}
if mode=='remote':payload['files']={n:base64.b64encode(p.read_bytes()).decode() for n,p in files.items()}
remote=r'''
from pathlib import Path
import base64,hashlib,json,os,pwd,shutil,sys,tempfile
p=json.load(sys.stdin);parent=Path('/var/lib/runnerhub/seo/semrush');target=parent/'20261104'
def verify(root):
 for n,h in p['hashes'].items():
  assert not Path(n).is_absolute() and '..' not in Path(n).parts
  f=root/n;assert f.is_file() and not f.is_symlink() and hashlib.sha256(f.read_bytes()).hexdigest()==h,n
if p['mode']=='remote':
 assert not target.exists(), 'Private archive already exists'
 parent.mkdir(mode=0o755,parents=True,exist_ok=True)
 ex=list(Path('/opt').glob('*/cfusion/bin/cfcompile.sh'));assert len(ex)==1
 uid=(ex[0].parent.parent/'lib/seed.properties').stat().st_uid;gid=pwd.getpwuid(uid).pw_gid
 stage=Path(tempfile.mkdtemp(prefix='.20261104-incoming-',dir=parent))
 try:
  os.chmod(stage,0o750);os.chown(stage,0,gid)
  for n,b in p['files'].items():
   assert not Path(n).is_absolute() and '..' not in Path(n).parts
   f=stage/n;f.parent.mkdir(mode=0o750,parents=True,exist_ok=True);os.chown(f.parent,0,gid)
   f.write_bytes(base64.b64decode(b));os.chmod(f,0o640);os.chown(f,0,gid)
  verify(stage);os.rename(stage,target)
 finally:
  if stage.exists():shutil.rmtree(stage)
verify(target)
print(json.dumps({'private_archive':str(target),'verified_files':len(p['hashes']),'outside_docroot':True}))
'''
ssh=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
cp=subprocess.run(ssh+['python3 -c '+shlex.quote(remote)],input=json.dumps(payload),capture_output=True,text=True,timeout=100)
assert cp.returncode==0,cp.stderr[-3000:]
r=json.loads(cp.stdout);(S/('store-'+mode+'.json')).write_text(json.dumps(dict(r,hashes=payload['hashes']),indent=2));print(json.dumps(r))
