"""Scoped coupon release: guarded diagnostics, native compile, backups and hashes."""
from pathlib import Path
import io,tarfile,subprocess,shlex,json,hashlib,sys
ROOT=Path(__file__).resolve().parents[2]
FILES=['cupons-rr/index.cfm','cupons-rr/home.cfm','cupons-rr/includes/backend.cfm','cupons-rr/includes/form_campanha.cfm','cupons-rr/includes/CouponService.cfc','cupons-rr/includes/form_cupom.cfm','cupons-rr/includes/event-fields.cfm','cupons-rr/includes/links.cfm','cupons-rr/assets/manager.css','cupons-rr/assets/manager.js']
SSH=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','rr-prod']
mode=sys.argv[1]
assert mode in ['inspect','check','prepare','publish','verify']
baseline={p:hashlib.sha256(subprocess.check_output(['git','show','HEAD:'+p],cwd=ROOT)).hexdigest() if i<4 else None for i,p in enumerate(FILES)}
buf=io.BytesIO()
with tarfile.open(fileobj=buf,mode='w') as tar:
 for p in FILES+['_codex/tests/coupon-production-check.cfm']:
  tar.add(ROOT/p,arcname=p)
remote=r'''
from pathlib import Path
import sys,io,tarfile,tempfile,secrets,shutil,json,hashlib,subprocess,os,re
root=Path('/var/www/business.roadrunners.run')
release=Path('/var/backups/business-coupons-20260916')
release.mkdir(mode=0o700,exist_ok=True)
stage=Path(tempfile.mkdtemp(prefix='coupon-stage-',dir='/tmp'))
try:
 with tarfile.open(fileobj=io.BytesIO(sys.stdin.buffer.read()),mode='r:') as archive:
  for m in archive.getmembers():
   assert m.isfile() and m.name in files+['_codex/tests/coupon-production-check.cfm']
   t=stage/m.name;t.parent.mkdir(parents=True,exist_ok=True);t.write_bytes(archive.extractfile(m).read())
 sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest() if p.exists() else None
 if mode in ['inspect','check']:
  token=secrets.token_hex(32);probe=root/('couponqa'+secrets.token_hex(10));probe.mkdir(mode=0o755)
  try:
   shutil.copyfile(stage/'cupons-rr/includes/CouponService.cfc',probe/'Candidate.cfc')
   guard='<cfif NOT listFind("127.0.0.1,::1",CGI.remote_addr) OR compare(CGI.http_x_coupon_check ?: "", "'+token+'") NEQ 0><cfheader statuscode="404"/><cfabort/></cfif>'
   (probe/'index.cfm').write_text(guard+(stage/'_codex/tests/coupon-production-check.cfm').read_text())
   for p in probe.iterdir(): p.chmod(0o644)
   r=subprocess.run(['curl','--silent','--show-error','--max-time','50','-H','Host: business.roadrunners.run','-H','X-Coupon-Check: '+token,'http://127.0.0.1/'+probe.name+'/index.cfm'],capture_output=True,text=True)
   print(r.stdout);assert r.returncode==0,r.stderr
  finally: shutil.rmtree(probe)
 elif mode=='prepare':
  assert all(sha(root/p)==baseline[p] for p in files),'Production baseline conflict'
  assert not (release/'manifest.json').exists(),'Release already prepared'
  compiled=stage/'compiled';compiled.mkdir()
  for p in [stage,*stage.rglob('*')]: os.chown(p,65534,65534);p.chmod(0o755 if p.is_dir() else 0o644)
  c=subprocess.run(['/opt/ColdFusion/cfusion/bin/cfcompile.sh','-deploy','-cfruntimeuser','nobody','-webroot',str(stage/'cupons-rr'),'-dir',str(stage/'cupons-rr'),'-deploydir',str(compiled)],capture_output=True,text=True,timeout=90)
  log=c.stdout+c.stderr;(release/'compile.log').write_text(log)
  assert c.returncode==0 and re.search(r'successful\s+8\b',log) and re.search(r'total\s+8\b',log),log[-5000:]
  manifest=[]
  for p in files:
   original=root/p;candidate=release/'candidate'/p;candidate.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(stage/p,candidate)
   if original.exists():
    backup=release/'backup'/p;backup.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(original,backup)
   manifest.append(dict(path=p,before=baseline[p],after=sha(candidate)))
  (release/'manifest.json').write_text(json.dumps(manifest,indent=2))
  print(json.dumps(dict(prepared=True,backup=str(release),files=len(manifest),compiled=8)))
 else:
  manifest=json.loads((release/'manifest.json').read_text())
  if mode=='publish':
   assert all(sha(root/m['path'])==m['before'] for m in manifest),'Production baseline changed'
   assert all(sha(release/'candidate'/m['path'])==m['after']==sha(stage/m['path']) for m in manifest),'Candidate changed'
   # All checks complete before the first install. Existing metadata preserved.
   for m in sorted(manifest,key=lambda m:m['path']=='cupons-rr/index.cfm'):
    dest=root/m['path'];dest.parent.mkdir(parents=True,exist_ok=True)
    source=release/'candidate'/m['path'];tmp=dest.with_name(dest.name+'.coupon-release')
    shutil.copyfile(source,tmp)
    stat=dest.stat() if dest.exists() else (root/'cupons-rr/index.cfm').stat()
    os.chown(tmp,stat.st_uid,stat.st_gid);tmp.chmod(stat.st_mode & 0o777);os.replace(tmp,dest)
  assert all(sha(root/m['path'])==m['after'] for m in manifest),'Published hash mismatch'
  print(json.dumps(dict(mode=mode,hashes_verified=len(manifest),backup=str(release))))
finally: shutil.rmtree(stage)
'''
response=subprocess.run(SSH+['python3 -c '+shlex.quote('files='+repr(FILES)+'\nbaseline='+repr(baseline)+'\nmode='+repr(mode)+'\n'+remote)],input=buf.getvalue(),capture_output=True)
print(response.stdout.decode())
if response.stderr: print(response.stderr.decode(),file=sys.stderr)
sys.exit(response.returncode)
