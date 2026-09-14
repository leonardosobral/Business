"""Five-file release of global cached UF and Público percentages; no SQL writes."""
from pathlib import Path
import hashlib, io, json, os, re, shlex, subprocess, sys, tarfile

root=Path(__file__).resolve().parents[2]
receipt=root/'_codex/docs/2026-09-14_publico_location_release.json'
order=[('RoadRunners','services/LocationResolver.cfc'),
       ('RoadRunners','Application.cfc'),
       ('Business','portal/audiencia/queries/event_interest.sql'),
       ('Business','portal/includes/event_interest_backend.cfm'),
       ('Business','portal/eventos-analytics/home.cfm')]
baseline=['09bba9d0f16adf1dd90c2b6cc5e97ee65391b75be45ea30011af7040b9472b9d',
          '2e81c368a8251ff13882104be30b2b66f02f9aaecbea2bf5af077540c774bf48',
          '4382b640eff5eb12f054bb2a1765deaa9410e6047fc8137ad5f16664066aff55',
          '2fc6aaec72f8e99a12fff3497e043c4fae3cee9af995b269da6c4c348743b3d2',
          '6e9b6aec915c71122a8277a71a619a0fc16c93cc3a4c253aa3452b143bf4755d']
ssh=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
mode=sys.argv[1]
assert mode in ('prepare','publish','verify','rollback')
base=(root/'_codex/staging/live-measurement/release-tools/publish.py').read_text()
start=base.index('ORDER = ('); end=base.index('GUARD_FILES =',start)
publisher=base[:start]+'ORDER = '+repr(tuple(order))+'\nNEW_FILES = frozenset()\n'+base[end:]
publisher=publisher.replace('rr-live-measurement','business-publico-location').replace('exactly 11 rows','exactly 5 rows').replace('11 whitelisted runtime targets','5 whitelisted runtime targets').replace('existing=9, absent=2','existing=5, absent=0')
publisher=publisher.replace('"logout.cfm",','"logout.cfm", "includes/backend/require_admin.cfm", "portal/eventos-analytics/index.cfm", "portal/includes/event_analytics_backend.cfm",')
# Exact runtime targets retain before/after hashes and metadata. Only those
# targets are excluded from the additional unrelated-file guard inventory.
anchor='# Snapshot inventories too:'
publisher=publisher.replace(anchor,'''GUARD_FILES = {site: tuple(name for name in names if (site, name) not in ORDER) for site, names in GUARD_FILES.items()}
GUARD_FILES["RoadRunners"] += ("includes/location.cfm", "services/AudienceMeasurementService.cfc", "includes/analytics/bootstrap.cfm", "circuito/live_highlight.cfm")
'''+anchor)
assert publisher.count('if (site, relative) in NEW_FILES:')==1
publisher=publisher.replace('if (site, relative) in NEW_FILES:','if (site, relative) in ORDER:')
sha=lambda b:hashlib.sha256(b).hexdigest()
script_sha=sha(publisher.encode())
if mode=='prepare':
 assert not receipt.exists(),'Existing receipt must not be overwritten'
 source=Path(os.environ['PUBLICO_RELEASE_SOURCE']).resolve()
 assert source.is_dir()
 files={'publish.py':publisher.encode()};lines=[]
 for (site,name),before in zip(order,baseline):
  content=(source/site/name).read_bytes();files['candidate/'+site+'/'+name]=content
  lines.append('\t'.join([site,name,before,sha(content)]))
 files['runtime.tsv']=('\n'.join(lines)+'\n').encode()
 buffer=io.BytesIO()
 with tarfile.open(fileobj=buffer,mode='w') as archive:
  for name,content in files.items():
   item=tarfile.TarInfo(name);item.size=len(content);item.mode=0o600;archive.addfile(item,io.BytesIO(content))
 payload=buffer.getvalue()
 init=f'''
release=Path('/var/backups')/('business-publico-location.'+secrets.token_hex(6));release.mkdir(mode=0o700)
allowed=set({list(files)!r})
with tarfile.open(fileobj=io.BytesIO(sys.stdin.buffer.read()),mode='r:') as archive:
 members=archive.getmembers()
 assert len(members)==len(allowed) and set(m.name for m in members)==allowed
 for item in members:
  assert item.isfile() and '..' not in Path(item.name).parts and not item.name.startswith('/')
  target=release/item.name;target.parent.mkdir(mode=0o700,parents=True,exist_ok=True)
  target.write_bytes(archive.extractfile(item).read());os.chmod(target,0o600)
'''
else:
 previous=json.loads(receipt.read_text());remote=previous['directory']
 assert re.fullmatch(r'/var/backups/business-publico-location\.[A-Za-z0-9_]+',remote)
 assert previous['scriptSHA']==script_sha,'Publisher changed after preparation'
 payload=b'';init=f'release=Path({remote!r})\n'
remote_script='''from pathlib import Path
import hashlib,io,json,os,re,secrets,shutil,subprocess,sys,tarfile,tempfile
'''+init+f'''
assert hashlib.sha256((release/'publish.py').read_bytes()).hexdigest()=={script_sha!r}
if {mode!r}=='publish':
 log=(release/'compile.log').read_text()
 assert re.search(r'successful\\s+4\\b',log) and re.search(r'total\\s+4\\b',log),'Native compilation was not verified'
result=subprocess.run(['python3',str(release/'publish.py'),str(release),{mode!r}],capture_output=True,text=True,timeout=90)
assert result.returncode==0,result.stdout+result.stderr
'''
if mode=='prepare':
 remote_script+='''
stage=Path(tempfile.mkdtemp(prefix='publico-location-compile-',dir='/tmp'))
source=stage/'source';compiled=stage/'compiled';compiled.mkdir()
for path in (release/'candidate').rglob('*'):
 if path.suffix.lower() not in ('.cfm','.cfc'): continue
 target=source/path.relative_to(release/'candidate');target.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(path,target)
for path in [stage,*stage.rglob('*')]:
 os.chown(path,65534,65534);os.chmod(path,0o755 if path.is_dir() else 0o644)
compiled_run=subprocess.run(['/opt/ColdFusion/cfusion/bin/cfcompile.sh','-deploy','-cfruntimeuser','nobody','-webroot',str(source),'-dir',str(source),'-deploydir',str(compiled)],capture_output=True,text=True,timeout=90)
log=compiled_run.stdout+compiled_run.stderr
(release/'compile.log').write_text(log)
shutil.move(str(stage),str(release/'compile-artifacts'))
assert compiled_run.returncode==0 and re.search(r'successful\\s+4\\b',log) and re.search(r'total\\s+4\\b',log),log[-4000:]
'''
remote_script+=f'''
state=json.loads((release/'state.json').read_text())
print(json.dumps({{'directory':str(release),'scriptSHA':{script_sha!r},'mode':{mode!r},'phase':state['phase'],'files':state['files'],'guard_count':len(state['guards']),'compile_log':str(release/'compile.log')}}))
'''
response=subprocess.run(ssh+['python3 -c '+shlex.quote(remote_script)],input=payload,capture_output=True,timeout=220)
if response.stdout:
 result=json.loads(response.stdout)
 destination=receipt if mode=='prepare' else receipt.with_name(receipt.stem+'-'+mode+'.json')
 destination.write_text(json.dumps(result,indent=2)+'\n')
 print(json.dumps({k:result[k] for k in ('directory','mode','phase','guard_count','compile_log')}))
if response.stderr: print(response.stderr.decode(),file=sys.stderr)
raise SystemExit(response.returncode)
