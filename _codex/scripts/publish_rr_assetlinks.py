"""Create only the previously absent Android association file, then verify HTTPS."""
from pathlib import Path
import json,shlex,subprocess,sys
local=Path('/Users/Shared/Projects/RunnerHub/RoadRunners/.well-known/assetlinks.json')
assert local.read_bytes()==b'[]\n'
source=r'''
from pathlib import Path
import hashlib,json,os,subprocess,tempfile
root=Path('/var/www/roadrunners.com.br');target=root/'.well-known/assetlinks.json'
stage=Path('/var/backups/roadrunners-assetlinks-20260928')
for p in [root,target.parent,target]:
 if p.is_symlink():raise RuntimeError('Symlink requires review: '+str(p))
if target.exists():raise RuntimeError('Target now exists; refusing to overwrite')
if target.parent.exists() and not target.parent.is_dir():raise RuntimeError('Parent is not a directory')
stage.mkdir(mode=0o700,exist_ok=False)
candidate=b'[]\n'; digest=hashlib.sha256(candidate).hexdigest()
manifest={'path':str(target),'before':None,'parent_existed':target.parent.exists(),'sha256':digest,'rollback':'Remove only this file if its SHA256 still matches this manifest; remove .well-known only if created here and empty.'}
(stage/'candidate.json').write_bytes(candidate)
(stage/'manifest.json').write_text(json.dumps(manifest,indent=2))
reference=(root/'index.cfm').stat()
target.parent.mkdir(mode=0o755,exist_ok=True)
fd,name=tempfile.mkstemp(prefix='.assetlinks-',dir=target.parent)
try:
 with os.fdopen(fd,'wb') as f:f.write(candidate)
 os.chmod(name,0o644);os.chown(name,reference.st_uid,reference.st_gid)
 os.link(name,target) # Atomic creation, never replaces a concurrently-created association.
finally:Path(name).unlink()
try:
 if target.read_bytes()!=candidate:raise RuntimeError('Runtime content mismatch')
 results=[]
 for origin in [True,False]:
  cmd=['curl','-sS','--max-time','25','-D','-','https://roadrunners.run/.well-known/assetlinks.json']
  if origin:cmd[1:1]=['--resolve','roadrunners.run:443:127.0.0.1']
  response=subprocess.run(cmd,capture_output=True,check=True).stdout.decode()
  header,body=response.replace('\r\n','\n').split('\n\n',1)
  if not header.splitlines()[0].split()[1]=='200':raise RuntimeError('Expected HTTP 200: '+header)
  if 'content-type: application/json' not in header.lower():raise RuntimeError('Incorrect MIME: '+header)
  if json.loads(body)!=[]:raise RuntimeError('Unexpected response body')
  results.append({'origin':origin,'status':200,'content_type':'application/json','body':body.strip(),'redirect':False})
 result={'published':str(target),'backup_manifest':str(stage/'manifest.json'),'verified':results,'sha256':digest}
 (stage/'verified.json').write_text(json.dumps(result,indent=2));print(json.dumps(result))
except Exception:
 if target.is_file() and hashlib.sha256(target.read_bytes()).hexdigest()==digest:target.unlink()
 if not manifest['parent_existed'] and not any(target.parent.iterdir()):target.parent.rmdir()
 raise
'''
p=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(source)],capture_output=True,text=True,timeout=65)
if p.returncode:print(p.stderr[-2500:]);sys.exit(p.returncode)
r=json.loads(p.stdout)
stage=Path(__file__).resolve().parents[2]/'_codex/staging/rr-assetlinks';stage.mkdir(exist_ok=True)
(stage/'published.json').write_text(json.dumps(r,indent=2));print(json.dumps(r))
