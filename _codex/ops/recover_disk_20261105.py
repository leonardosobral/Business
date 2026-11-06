"""Lossless, narrowly scoped storage recovery. Run on rr-prod as root.
Old closed test archives and rotated logs only; runtime/uploads are excluded.
Each source is removed only after its compressed replacement is fully verified.
"""
import os,pathlib,stat,time,json,hashlib,tarfile,gzip,shutil,tempfile,re,sys
os.nice(10)
apply='--apply' in sys.argv
base=pathlib.Path('/var/backups');archive=base/'business-disk-recovery-20261105';cutoff=time.time()-86400
sha=lambda p:hashlib.file_digest(p.open('rb'),'sha256').hexdigest()
def space():
 v=os.statvfs('/');return {'free':v.f_bfree*v.f_frsize,'available':v.f_bavail*v.f_frsize}
def identity(p):
 s=p.lstat();return (s.st_dev,s.st_ino,s.st_size,s.st_mtime_ns,s.st_mode,s.st_uid,s.st_gid)
opened=set()
for p in pathlib.Path('/proc').glob('[0-9]*/fd/*'):
 try:s=p.stat();opened.add((s.st_dev,s.st_ino))
 except OSError:pass
report={'before':space(),'archives':[],'logs':[],'skipped':[],'ok':False}
if apply:
 archive.mkdir(mode=0o700,exist_ok=False)
 def save():
  p=archive/'receipt.json';p.write_text(json.dumps(report,indent=2));os.chmod(p,0o600)
 save()
# Closed, old numbered logs; never touch active log filenames.
logs=[p for p in pathlib.Path('/opt/coldfusion2025/cfusion/logs').iterdir() if re.fullmatch(r'coldfusion-out\.[0-9]+\.log',p.name)]
logs.append(pathlib.Path('/var/log/apache2/access.log.1'))
for p in logs:
 if not p.exists() or p.is_symlink() or not p.is_file():continue
 before=identity(p)
 if before[3]/1e9>=cutoff or before[:2] in opened:continue
 if not apply:continue
 dest=archive/'logs'/pathlib.Path(str(p).lstrip('/'));dest.parent.mkdir(parents=True,exist_ok=True);dest=dest.with_name(dest.name+'.gz')
 checksum=sha(p)
 with p.open('rb') as src,dest.open('xb') as raw:
  os.fchmod(raw.fileno(),0o600)
  with gzip.GzipFile(fileobj=raw,mode='wb',compresslevel=3) as gz:shutil.copyfileobj(src,gz)
  raw.flush();os.fsync(raw.fileno())
 with gzip.open(dest,'rb') as read:verified=hashlib.file_digest(read,'sha256').hexdigest()
 if verified!=checksum or identity(p)!=before:raise RuntimeError('Log verification/concurrency failure')
 p.unlink();report['logs'].append({'source':str(p),'archive':str(dest),'sha256':checksum,'before':before[2],'after':dest.stat().st_size});save()
print(json.dumps({'phase':'logs_verified','files':len(report['logs']),'space':space()}),flush=True)
# These directories are isolated test evidence, never deployment rollback backups.
selected=[p for p in base.iterdir() if p.is_dir() and not p.is_symlink() and p.name.startswith('geocoding-tests-') and p.stat().st_mtime<cutoff]
for p in selected:
 records={};valid=True
 for node in [p,*p.rglob('*')]:
  s=node.lstat()
  if s.st_mtime>=cutoff or (s.st_dev,s.st_ino) in opened or not (stat.S_ISDIR(s.st_mode) or stat.S_ISREG(s.st_mode)):
   valid=False;break
  records[str(node.relative_to(base))]={'identity':identity(node),'hash':sha(node) if node.is_file() else None}
 if not valid:continue
 if not apply:continue
 dest=archive/'test-evidence'/(p.name+'.tar.gz');dest.parent.mkdir(parents=True,exist_ok=True)
 with dest.open('xb') as stream:
  os.fchmod(stream.fileno(),0o600)
  with tarfile.open(fileobj=stream,mode='w:gz',compresslevel=3,dereference=False) as tar:tar.add(p,arcname=p.name)
  stream.flush();os.fsync(stream.fileno())
 with tarfile.open(dest,'r:gz') as tar:
  members={m.name:m for m in tar.getmembers()}
  if set(members)!=set(records):raise RuntimeError('Archive membership mismatch')
  for name,record in records.items():
   m=members[name]
   if record['hash']:
    with tar.extractfile(m) as stream:actual=hashlib.file_digest(stream,'sha256').hexdigest()
    if actual!=record['hash']:raise RuntimeError('Archive content mismatch')
   node=base/name
   if identity(node)!=record['identity']:raise RuntimeError('Concurrent source change')
   if m.uid!=record['identity'][5] or m.gid!=record['identity'][6] or m.mode!=stat.S_IMODE(record['identity'][4]):raise RuntimeError('Archive metadata mismatch')
 if set(str(n.relative_to(base)) for n in [p,*p.rglob('*')])!=set(records):raise RuntimeError('Concurrent membership change')
 size=sum(r['identity'][2] for r in records.values() if r['hash'])
 shutil.rmtree(p)
 report['archives'].append({'source':str(p),'archive':str(dest),'entries':len(records),'source_bytes':size,'archive_bytes':dest.stat().st_size,'sha256':sha(dest),'all_members_sha256_verified':True})
 if len(report['archives'])%100==0:
  save();print(json.dumps({'phase':'old_tests_verified','count':len(report['archives']),'space':space()}),flush=True)
report['after']=space();report['ok']=True
if apply:
 (archive/'RESTORE.txt').write_text('Recover an original test directory: tar -xzf test-evidence/NAME.tar.gz -C /var/backups\nRecover a log: gzip -dc logs/ORIGINAL/PATH.gz > /ORIGINAL/PATH (only after checking no active writer).\nAll original file bytes were SHA-256 verified before source removal. Active logs, runtime, user uploads, credentials and deployment rollback backups were not removed.\n')
 os.chmod(archive/'RESTORE.txt',0o600);save()
print(json.dumps({'ok':True,'apply':apply,'before':report['before'],'after':report['after'],'logs':len(report['logs']),'test_archives':len(report['archives']),'receipt':str(archive/'receipt.json') if apply else None}),flush=True)
