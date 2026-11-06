"""Explicit snapshot/copy/verify/remove phases for the authorized offline backup move.
Local archives are permanent and never deleted here. Only unchanged verified
sources from /var/backups can be removed. Credentials/metadata stay private.
"""
import pathlib,subprocess,shlex,json,hashlib,tarfile,sys,os
OUT=pathlib.Path('/Users/geraldoprotta/Backups/RunnerHub/172.233.2.76/2026-11-05/var-backups')
SSH=['ssh','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-o','ConnectTimeout=12','rr-prod']
def digest(stream):
 h=hashlib.sha256()
 for block in iter(lambda:stream.read(1048576),b''):h.update(block)
 return h.hexdigest()
def remote(code,payload=None,output=None):
 r=subprocess.run(SSH+['python3 -c '+shlex.quote(code)],input=json.dumps(payload).encode() if payload is not None else None,stdout=output or subprocess.PIPE,stderr=subprocess.PIPE,timeout=900)
 if r.returncode:raise RuntimeError(r.stderr.decode(errors='replace')[-1500:])
 return r.stdout
SNAP=r'''
import pathlib,os,stat,time,json,hashlib
root=pathlib.Path('/var/backups');result={'sources':{},'skipped':[],'created':time.time(),'server':'172.233.2.76'};writers=set()
for fd in pathlib.Path('/proc').glob('[0-9]*/fd/*'):
 try:
  info=(fd.parent.parent/'fdinfo'/fd.name).read_text();flags=int(next(l.split()[1] for l in info.splitlines() if l.startswith('flags:')),8)
  if flags & os.O_ACCMODE:s=fd.stat();writers.add((s.st_dev,s.st_ino))
 except (OSError,StopIteration,ValueError):pass
for top in sorted(root.iterdir()):
 if top.name in ['OFFLINE-BACKUPS.md','offline-backups-index.json']:continue
 nodes=[top,*top.rglob('*')] if top.is_dir() and not top.is_symlink() else [top]
 entries={};valid=True
 for q in nodes:
  s=q.lstat();kind='file' if stat.S_ISREG(s.st_mode) else 'dir' if stat.S_ISDIR(s.st_mode) else 'symlink' if stat.S_ISLNK(s.st_mode) else 'unsupported'
  if kind=='unsupported' or (s.st_dev,s.st_ino) in writers:valid=False;break
  h=None
  if kind=='file':
   with q.open('rb') as f:h=hashlib.file_digest(f,'sha256').hexdigest()
  entries[str(q.relative_to(root))]={'kind':kind,'size':s.st_size,'mode':stat.S_IMODE(s.st_mode),'uid':s.st_uid,'gid':s.st_gid,'mtime':s.st_mtime_ns,'ino':s.st_ino,'sha256':h,'link':os.readlink(q) if kind=='symlink' else None}
 if valid:result['sources'][top.name]=entries
 else:result['skipped'].append(top.name)
print(json.dumps(result))
'''
COPY=r'''
import sys,json,re,subprocess
p=json.load(sys.stdin);names=list(p['sources'])
if not names or any(n in ['.','..'] or not re.fullmatch(r'[A-Za-z0-9_.-]+',n) for n in names):raise SystemExit('Invalid source list')
r=subprocess.run(['nice','-n','10','tar','--format=pax','--sparse','--numeric-owner','--one-file-system','--null','-C','/var/backups','-czf','-','-T','-'],input=b'\0'.join(n.encode() for n in names)+b'\0',stdout=sys.stdout.buffer,stderr=subprocess.PIPE)
if r.returncode:sys.stderr.buffer.write(r.stderr)
sys.exit(r.returncode)
'''
REMOVE=r'''
import sys,json,pathlib,stat,hashlib,os,shutil,re
p=json.load(sys.stdin);root=pathlib.Path('/var/backups');done=[]
if not p.get('verified') or not re.fullmatch('[a-f0-9]{64}',p.get('archive_sha256','')):raise SystemExit('Verified external backup required')
receipt=pathlib.Path('/run/business-offline-backups-20261105.json')
for name,entries in p['sources'].items():
 if name in ['.','..'] or not re.fullmatch(r'[A-Za-z0-9_.-]+',name):raise SystemExit('Unsafe source')
 top=root/name
 nodes=[top,*top.rglob('*')] if top.is_dir() and not top.is_symlink() else [top]
 if set(str(q.relative_to(root)) for q in nodes)!=set(entries):raise SystemExit('Source membership changed: '+name)
 for rel,e in entries.items():
  q=root/rel;s=q.lstat()
  if (s.st_size,stat.S_IMODE(s.st_mode),s.st_uid,s.st_gid,s.st_mtime_ns,s.st_ino)!=(e['size'],e['mode'],e['uid'],e['gid'],e['mtime'],e['ino']):raise SystemExit('Source metadata changed: '+name)
  if e['kind']=='symlink' and os.readlink(q)!=e['link']:raise SystemExit('Symlink changed')
  if e['sha256']:
   with q.open('rb') as f:h=hashlib.file_digest(f,'sha256').hexdigest()
   if h!=e['sha256']:raise SystemExit('Source contents changed: '+name)
 state={'archive':p['archive_local_path'],'archive_sha256':p['archive_sha256'],'removed':done,'next_verified':name}
 with receipt.open('w') as f:os.fchmod(f.fileno(),0o600);json.dump(state,f);f.flush();os.fsync(f.fileno())
 if top.is_dir() and not top.is_symlink():shutil.rmtree(top)
 else:top.unlink()
 done.append(name)
 if len(done)%100==0:print(json.dumps({'verified_sources_removed':len(done)}),flush=True)
v=os.statvfs('/');state.update(ok=True,removed=done,next_verified=None,free=v.f_bfree*v.f_frsize,available=v.f_bavail*v.f_frsize)
with receipt.open('w') as f:os.fchmod(f.fileno(),0o600);json.dump(state,f);f.flush();os.fsync(f.fileno())
print(json.dumps({'ok':True,'removed':len(done),'free':state['free'],'available':state['available']}))
'''
mode=sys.argv[1]
if mode=='snapshot':
 OUT.mkdir(mode=0o700,exist_ok=False);raw=remote(SNAP);p=OUT/'manifest.json';p.write_bytes(raw);p.chmod(0o600);m=json.loads(raw)
 print(json.dumps({'sources':len(m['sources']),'members':sum(map(len,m['sources'].values())),'skipped':m['skipped']}))
elif mode=='copy':
 m=json.loads((OUT/'manifest.json').read_text());p=OUT/'var-backups.tar.gz'
 with p.open('xb') as f:os.fchmod(f.fileno(),0o600);remote(COPY,m,f);f.flush();os.fsync(f.fileno())
 print(json.dumps({'archive':str(p),'bytes':p.stat().st_size}))
elif mode=='verify':
 m=json.loads((OUT/'manifest.json').read_text());expected={k:v for group in m['sources'].values() for k,v in group.items()};seen=set();hashes={};p=OUT/'var-backups.tar.gz'
 with tarfile.open(p,'r|gz') as tar:
  for i in tar:
   if i.name not in expected or i.name in seen:raise RuntimeError('Archive membership mismatch')
   e=expected[i.name];seen.add(i.name)
   if (i.mode,i.uid,i.gid)!=(e['mode'],e['uid'],e['gid']):raise RuntimeError('Metadata mismatch')
   if e['kind']=='symlink':
    if not i.issym() or i.linkname!=e['link']:raise RuntimeError('Symlink mismatch')
   elif e['kind']=='dir':
    if not i.isdir():raise RuntimeError('Directory mismatch')
   else:
    if i.islnk():h=hashes.get(i.linkname)
    else:
     with tar.extractfile(i) as f:h=digest(f)
    if h!=e['sha256']:raise RuntimeError('File checksum mismatch')
    hashes[i.name]=h
 if seen!=set(expected):raise RuntimeError('Missing archive members')
 with p.open('rb') as f:h=digest(f)
 m.update(verified=True,archive_sha256=h,archive_local_path=str(p));target=OUT/'verified-manifest.json';target.write_text(json.dumps(m));target.chmod(0o600)
 print(json.dumps({'ok':True,'verified_members':len(seen),'archive_sha256':h}))
elif mode=='remove-verified':
 m=json.loads((OUT/'verified-manifest.json').read_text())
 with pathlib.Path(m['archive_local_path']).open('rb') as f:h=digest(f)
 if h!=m['archive_sha256']:raise RuntimeError('External archive changed')
 raw=remote(REMOVE,m);p=OUT/'removal-result.jsonl';p.write_bytes(raw);p.chmod(0o600);print(raw.decode())
else:raise SystemExit('Unknown phase')
