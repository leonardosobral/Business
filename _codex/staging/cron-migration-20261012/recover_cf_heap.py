from pathlib import Path
from datetime import datetime,timezone
import hashlib,json,os,re,subprocess,tempfile
os.umask(0o077)
root=Path('/opt/coldfusion2025/cfusion');target=root/'bin/jvm.config'
original=target.read_bytes();text=original.decode();meta=target.stat()
if re.findall(r'-Xms\S+',text)!=['-Xms256m'] or re.findall(r'-Xmx\S+',text)!=['-Xmx1024m']:raise RuntimeError('Unexpected heap baseline; no change.')
for name in ['cf-init.sh','cf-connectors.sh']:
 if (root/'bin'/name).exists():raise RuntimeError('Startup would run extra setup; stop for review.')
backup=Path(tempfile.mkdtemp(prefix='cf2025-heap-recovery-'+datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')+'-',dir='/var/backups'))
(backup/'jvm.config.before').write_bytes(original)
report={'backup':str(backup),'started_at_utc':datetime.now(timezone.utc).isoformat(),'before_heap':{'initial_mb':256,'maximum_mb':1024},'after_heap':{'initial_mb':2048,'maximum_mb':8192},'before_sha256':hashlib.sha256(original).hexdigest(),'apache_workers_unchanged':150}
(backup/'result.json').write_text(json.dumps(report,indent=2)+'\n')
candidate=text.replace('-Xms256m','-Xms2048m').replace('-Xmx1024m','-Xmx8192m').encode()
if target.read_bytes()!=original:raise RuntimeError('JVM baseline changed concurrently.')
fd,tmp=tempfile.mkstemp(prefix='.jvm-heap-',dir=target.parent)
with os.fdopen(fd,'wb') as out:out.write(candidate);out.flush();os.fsync(out.fileno())
os.chown(tmp,meta.st_uid,meta.st_gid);os.chmod(tmp,meta.st_mode & 0o777);os.replace(tmp,target)
report['after_sha256']=hashlib.sha256(target.read_bytes()).hexdigest()
print(json.dumps({'stage':'backup_and_heap_saved','backup':str(backup)}),flush=True)
with (backup/'stop.log').open('w') as log:
 stopped=subprocess.run([str(root/'bin/coldfusion'),'stop'],stdout=log,stderr=subprocess.STDOUT,timeout=45)
report['stop_rc']=stopped.returncode
if stopped.returncode or Path('/proc/5563').exists():
 (backup/'result.json').write_text(json.dumps(report,indent=2)+'\n');raise RuntimeError('Original JVM still present; do not start duplicate.')
print(json.dumps({'stage':'old_jvm_stopped'}),flush=True)
with (backup/'start.log').open('w') as log:
 started=subprocess.run(['systemctl','start','cf2025'],stdout=log,stderr=subprocess.STDOUT,timeout=45)
report['start_rc']=started.returncode;report['service_active']=subprocess.run(['systemctl','is-active','cf2025'],capture_output=True,text=True).stdout.strip();report['finished_at_utc']=datetime.now(timezone.utc).isoformat()
(backup/'result.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report,indent=2),flush=True)
