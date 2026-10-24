from pathlib import Path
from datetime import datetime, timezone
import base64,hashlib,json,os,tempfile
ROOT=Path('/var/www/conteudo.roadrunners.run')
os.umask(0o077)
PAYLOAD = None
MANIFEST = None
sha=lambda data:hashlib.sha256(data).hexdigest()
order=['inc/db.cfc']+[name for name in MANIFEST if name!='inc/db.cfc']
for name in order:
 if sha((ROOT/name).read_bytes())!=MANIFEST[name]['before']:raise RuntimeError('Production baseline conflict: '+name)
 if sha(base64.b64decode(PAYLOAD[name]))!=MANIFEST[name]['after']:raise RuntimeError('Candidate integrity mismatch: '+name)
backup=Path(tempfile.mkdtemp(prefix='news-importers-cf2025-'+datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')+'-',dir='/var/backups'))
metadata={}
for name in order:
 path=ROOT/name;state=path.stat();metadata[name]={'uid':state.st_uid,'gid':state.st_gid,'mode':state.st_mode & 0o777}
 original=backup/'before'/name;original.parent.mkdir(parents=True,exist_ok=True);original.write_bytes(path.read_bytes())
(backup/'manifest.json').write_text(json.dumps({'hashes':MANIFEST,'metadata':metadata},indent=2)+'\n')
def install(name,data):
 target=ROOT/name
 fd,tmp=tempfile.mkstemp(prefix='.cron-import-fix-',dir=target.parent)
 try:
  with os.fdopen(fd,'wb') as out:out.write(data);out.flush();os.fsync(out.fileno())
  os.chown(tmp,metadata[name]['uid'],metadata[name]['gid']);os.chmod(tmp,metadata[name]['mode']);os.replace(tmp,target)
 finally:
  if Path(tmp).exists():Path(tmp).unlink()
changed=[]
try:
 for name in order:
  if sha((ROOT/name).read_bytes())!=MANIFEST[name]['before']:raise RuntimeError('Concurrent production change: '+name)
  install(name,base64.b64decode(PAYLOAD[name]));changed.append(name)
  if sha((ROOT/name).read_bytes())!=MANIFEST[name]['after']:raise RuntimeError('Publication hash mismatch: '+name)
except Exception:
 for name in reversed(changed):
  if sha((ROOT/name).read_bytes())==MANIFEST[name]['after']:install(name,(backup/'before'/name).read_bytes())
 raise
report={'backup':str(backup),'published_at_utc':datetime.now(timezone.utc).isoformat(),'files':MANIFEST,'metadata_preserved':True,'server_permissions_changed':False}
(backup/'result.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report,indent=2))
