"""Verified external archive of old geocoding test evidence; explicit phases.
No source mutation until the whole local archive passes SHA-256/member checks.
The external archive is NEVER removed by this script.
"""
import pathlib,subprocess,shlex,json,hashlib,tarfile,sys,os
if not hasattr(hashlib,'file_digest'):
 def compatible_file_digest(stream,algorithm):
  value=hashlib.new(algorithm)
  while True:
   block=stream.read(1048576)
   if not block:break
   value.update(block)
  return value
 hashlib.file_digest=compatible_file_digest
OUT=pathlib.Path('/Users/geraldoprotta/Backups/RunnerHub/172.233.2.76/2026-11-05/geocoding-test-evidence');MODE=sys.argv[1];SSH=['ssh','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-o','ConnectTimeout=12','rr-prod']
def remote(code,payload=None,output=None):
 return subprocess.run(SSH+['python3 -c '+shlex.quote(code)],input=json.dumps(payload).encode() if payload is not None else None,stdout=output or subprocess.PIPE,stderr=subprocess.PIPE,timeout=900)
SNAP=r'''
import pathlib,stat,time,json,hashlib,os
root=pathlib.Path('/var/backups');cutoff=time.time()-86400;result={'directories':{},'created':time.time()}
for p in sorted(root.glob('geocoding-tests-*')):
 if not p.is_dir() or p.is_symlink() or p.stat().st_mtime>=cutoff:continue
 entries={};valid=True
 for q in [p,*p.rglob('*')]:
  s=q.lstat()
  if s.st_mtime>=cutoff or not (stat.S_ISDIR(s.st_mode) or stat.S_ISREG(s.st_mode)) or (q.is_file() and s.st_size>10000000):valid=False;break
  h=None
  if q.is_file():
   with q.open('rb') as f:h=hashlib.file_digest(f,'sha256').hexdigest()
  entries[str(q.relative_to(root))]={'size':s.st_size,'mode':stat.S_IMODE(s.st_mode),'uid':s.st_uid,'gid':s.st_gid,'mtime':s.st_mtime_ns,'ino':s.st_ino,'sha256':h}
 if valid:result['directories'][p.name]=entries
print(json.dumps(result))
'''
TAR=r'''
import sys,json,re,subprocess
p=json.load(sys.stdin);names=list(p['directories'])
if not names or any(not re.fullmatch(r'geocoding-tests-[a-z0-9_]+',n) for n in names):raise SystemExit('Unsafe/empty archive list')
r=subprocess.run(['nice','-n','10','tar','--format=pax','--sparse','--numeric-owner','--one-file-system','--null','-C','/var/backups','-czf','-','-T','-'],input=b'\0'.join(n.encode() for n in names)+b'\0',stdout=sys.stdout.buffer,stderr=subprocess.PIPE)
if r.returncode:sys.stderr.buffer.write(r.stderr)
sys.exit(r.returncode)
'''
REMOVE=r'''
import sys,json,pathlib,stat,hashlib,shutil,os,time,re
p=json.load(sys.stdin);root=pathlib.Path('/var/backups');done=[];report=pathlib.Path('/run/business-disk-rescue-20261105.json')
if not p.get('archive_verified') or not re.fullmatch('[a-f0-9]{64}',p.get('archive_sha256','')):raise SystemExit('Verified external backup required')
for name,entries in p['directories'].items():
 if not re.fullmatch(r'geocoding-tests-[a-z0-9_]+',name):raise SystemExit('Unsafe directory')
 d=root/name
 if d.is_symlink():raise SystemExit('Unsafe symlink')
 if set(str(q.relative_to(root)) for q in [d,*d.rglob('*')])!=set(entries):raise SystemExit('Source membership changed')
 for rel,e in entries.items():
  q=root/rel;s=q.lstat()
  if (s.st_size,stat.S_IMODE(s.st_mode),s.st_uid,s.st_gid,s.st_mtime_ns,s.st_ino)!=(e['size'],e['mode'],e['uid'],e['gid'],e['mtime'],e['ino']):raise SystemExit('Source metadata changed')
  if e['sha256']:
   with q.open('rb') as f:h=hashlib.file_digest(f,'sha256').hexdigest()
   if h!=e['sha256']:raise SystemExit('Source content changed')
 # Durable manifest BEFORE each removal, with the verified external archive locator.
 state={'archive_sha256':p['archive_sha256'],'archive_local_path':p['archive_local_path'],'already_removed':done,'next_verified_directory':name}
 with report.open('w') as f:os.fchmod(f.fileno(),0o600);json.dump(state,f);f.flush();os.fsync(f.fileno())
 shutil.rmtree(d);done.append(name)
 if len(done)%200==0:print(json.dumps({'removed_verified_sources':len(done)}),flush=True)
v=os.statvfs('/');print(json.dumps({'ok':True,'external_backup':p['archive_local_path'],'removed_verified_sources':len(done),'free':v.f_bfree*v.f_frsize,'available':v.f_bavail*v.f_frsize}))
'''
if MODE=='snapshot':
 r=remote(SNAP);r.check_returncode();p=OUT/'manifest.json';p.write_bytes(r.stdout);p.chmod(0o600);m=json.loads(r.stdout);print(json.dumps({'directories':len(m['directories']),'entries':sum(map(len,m['directories'].values()))}))
elif MODE=='archive':
 m=json.loads((OUT/'manifest.json').read_text());p=OUT/'old-geocoding-test-evidence.tar.gz'
 with p.open('xb') as f:
  os.fchmod(f.fileno(),0o600);r=remote(TAR,m,f);f.flush();os.fsync(f.fileno())
 if r.returncode:print(r.stderr.decode()[-2000:]);raise SystemExit('Archive failed; no sources removed')
 print(json.dumps({'archive':str(p),'bytes':p.stat().st_size}))
elif MODE=='verify':
 m=json.loads((OUT/'manifest.json').read_text());expected={k:v for group in m['directories'].values() for k,v in group.items()};p=OUT/'old-geocoding-test-evidence.tar.gz'
 seen=set();checked_hashes={}
 with tarfile.open(p,'r|gz') as tar:
  for i in tar:
   name=i.name
   if name not in expected or name in seen:raise SystemExit('Archive member mismatch')
   e=expected[name];seen.add(name)
   if (i.mode,i.uid,i.gid)!=(e['mode'],e['uid'],e['gid']):raise SystemExit('Archive metadata mismatch')
   if e['sha256']:
    if i.islnk():h=checked_hashes.get(i.linkname)
    else:
     with tar.extractfile(i) as f:h=hashlib.file_digest(f,'sha256').hexdigest()
    if h!=e['sha256']:raise SystemExit('Archive hash mismatch')
    checked_hashes[name]=h
 if seen!=set(expected):raise SystemExit('Archive membership incomplete')
 with p.open('rb') as f:h=hashlib.file_digest(f,'sha256').hexdigest()
 m.update(archive_verified=True,archive_sha256=h,archive_local_path=str(p));(OUT/'verified-manifest.json').write_text(json.dumps(m));(OUT/'verified-manifest.json').chmod(0o600);print(json.dumps({'ok':True,'verified_members':len(expected),'archive_sha256':h}))
elif MODE=='remove-verified':
 m=json.loads((OUT/'verified-manifest.json').read_text());p=pathlib.Path(m['archive_local_path'])
 with p.open('rb') as f:h=hashlib.file_digest(f,'sha256').hexdigest()
 if h!=m['archive_sha256']:raise SystemExit('External archive changed')
 r=remote(REMOVE,m);(OUT/'removal-result.jsonl').write_bytes(r.stdout);print(r.stdout.decode());
 if r.returncode:print(r.stderr.decode()[-2000:]);raise SystemExit(1)
else:raise SystemExit('Unknown phase')
