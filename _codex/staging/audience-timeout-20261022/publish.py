from pathlib import Path
import base64,hashlib,json,shlex,subprocess
stage=Path(__file__).parent
before=json.loads((stage/'production-baseline.json').read_text())
names=['portal/audiencia/queries/filter.sql','portal/audiencia/index.cfm']
files={p:base64.b64encode(Path(p).read_bytes()).decode() for p in names}
script='''
from pathlib import Path
import base64,hashlib,json,os,shutil,tempfile
root=Path('/var/www/business.roadrunners.run');baseline=BASELINE;files=FILES
for p,row in baseline.items():assert hashlib.sha256((root/p).read_bytes()).hexdigest()==row['sha256'], 'Production changed: '+p
backup=Path(tempfile.mkdtemp(prefix='business-audience-timeout-20261022-',dir='/var/backups'));os.chmod(backup,0o700)
report={'backup':str(backup),'files':{}}
for p in files:
 dest=backup/p;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(root/p,dest)
for p,encoded in files.items():
 target=root/p;data=base64.b64decode(encoded);meta=target.stat()
 assert hashlib.sha256(target.read_bytes()).hexdigest()==baseline[p]['sha256']
 fd,tmp=tempfile.mkstemp(prefix='.audience-publish-',dir=target.parent)
 with os.fdopen(fd,'wb') as f:f.write(data)
 os.chown(tmp,meta.st_uid,meta.st_gid);os.chmod(tmp,meta.st_mode & 0o777);os.replace(tmp,target)
 after=hashlib.sha256(target.read_bytes()).hexdigest();assert after==hashlib.sha256(data).hexdigest()
 report['files'][p]={'before':baseline[p]['sha256'],'after':after}
for p,row in baseline.items():
 if p not in files:assert hashlib.sha256((root/p).read_bytes()).hexdigest()==row['sha256']
(backup/'manifest.json').write_text(json.dumps(report,indent=2));print(json.dumps(report,indent=2))
'''.replace('BASELINE',repr(before)).replace('FILES',repr(files))
r=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(script)],capture_output=True,text=True,timeout=40)
if r.returncode:raise RuntimeError(r.stderr)
(stage/'publication.json').write_text(r.stdout);print(r.stdout)
