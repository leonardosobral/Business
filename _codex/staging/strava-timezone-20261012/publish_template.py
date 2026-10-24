from pathlib import Path
from datetime import datetime,timezone
import base64,hashlib,json,os,subprocess,tempfile
os.umask(0o077)
backup=Path(BACKUP)
manifest=json.loads((backup/'manifest.json').read_text())
path=Path('/var/www/roadrunners.com.br/api/integrations/strava/batch-refresh.cfm')
before=manifest['runtime_before_sha256'];candidate=base64.b64decode(PAYLOAD);after=hashlib.sha256(candidate).hexdigest()
if hashlib.sha256(path.read_bytes()).hexdigest()!=before:raise RuntimeError('Production baseline changed')
if hashlib.sha256((backup/'activity-dates-before.json').read_bytes()).hexdigest()!=manifest['backup_sha256']:raise RuntimeError('Data backup checksum mismatch')
state=path.stat();fd,tmp=tempfile.mkstemp(prefix='.strava-timezone-',dir=path.parent)
try:
 with os.fdopen(fd,'wb') as f:f.write(candidate);f.flush();os.fsync(f.fileno())
 os.chown(tmp,state.st_uid,state.st_gid);os.chmod(tmp,state.st_mode&0o777)
 if hashlib.sha256(path.read_bytes()).hexdigest()!=before:raise RuntimeError('Concurrent runtime change')
 os.replace(tmp,path)
finally:
 if Path(tmp).exists():Path(tmp).unlink()
if hashlib.sha256(path.read_bytes()).hexdigest()!=after:raise RuntimeError('Published checksum mismatch')
(backup/'batch-refresh.cfm.after').write_bytes(candidate)
r=subprocess.run(['curl','-sS','--max-time','12','--resolve','roadrunners.run:443:127.0.0.1','-w','\n%{http_code}','https://roadrunners.run/api/integrations/strava/batch-refresh.cfm'],capture_output=True,text=True,timeout=15)
body,_,status=r.stdout.rpartition('\n')
try:payload=json.loads(body)
except ValueError:payload={}
report={'published_at_utc':datetime.now(timezone.utc).isoformat(),'backup':str(backup),'before':before,'after':after,'auth_boundary_http':status,'auth_boundary_status':payload.get('status'),'metadata_preserved':True}
(backup/'published.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report,indent=2))
if r.returncode or status not in ('401','405'):raise RuntimeError('Unexpected endpoint compilation/auth response')
