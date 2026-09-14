"""Four-file, baseline-guarded release. Reuses the existing reversible publisher.
No database connections, migrations, credentials, git mutations or service restarts.
"""
from pathlib import Path
import hashlib, io, json, os, re, shlex, subprocess, sys, tarfile

root=Path(__file__).resolve().parents[2]
receipt_name=sys.argv[2] if len(sys.argv)>2 else '2026-09-14_event_agenda_release.json'
assert Path(receipt_name).name==receipt_name and receipt_name.endswith('.json')
receipt=root/'_codex/docs'/receipt_name
order=[('Business','portal/audiencia/queries/event_agenda_ranking.sql'),
       ('Business','portal/eventos-analytics/agenda.cfm'),
       ('Business','portal/includes/event_interest_backend.cfm'),
       ('Business','portal/eventos-analytics/home.cfm')]
baseline=['ABSENT','ABSENT','8a27fa10ea402ff47369a59e990bbeae099d09bd0f4c76d05e2fd9be7a86471e','5fca554e2c431479dcb37f6740d5da2fcb0a68c5d2f4c0918f9f357af1d5a297']
ssh=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
mode=sys.argv[1]
assert mode in ('prepare','publish','verify','rollback')
base=(root/'_codex/staging/live-measurement/release-tools/publish.py').read_text()
start=base.index('ORDER = ('); end=base.index('GUARD_FILES =',start)
publisher=base[:start]+'ORDER = '+repr(tuple(order))+'\nNEW_FILES = frozenset(ORDER[:2])\n'+base[end:]
publisher=publisher.replace('rr-live-measurement','business-event-agenda').replace('exactly 11 rows','exactly 4 rows').replace('11 whitelisted runtime targets','4 whitelisted runtime targets').replace('existing=9, absent=2','existing=2, absent=2')
publisher=publisher.replace('"logout.cfm",','"logout.cfm", "includes/backend/require_admin.cfm", "portal/eventos-analytics/index.cfm", "portal/includes/event_analytics_backend.cfm",')
# Every exact runtime target has before/candidate/after hash and metadata checks.
# The unrelated-tree guard must not also demand its old hash after installation.
assert publisher.count('if (site, relative) in NEW_FILES:') == 1
publisher=publisher.replace('if (site, relative) in NEW_FILES:', 'if (site, relative) in ORDER:')
sha=lambda b:hashlib.sha256(b).hexdigest()
script_sha=sha(publisher.encode())
if mode=='prepare':
 assert not receipt.exists(),'Existing receipt must not be overwritten'
 files={'publish.py':publisher.encode()}
 lines=[]
 for (site,name),before in zip(order,baseline):
  content=(root/name).read_bytes();files['candidate/'+site+'/'+name]=content
  lines.append('\t'.join([site,name,before,sha(content)]))
 files['runtime.tsv']=('\n'.join(lines)+'\n').encode()
 buffer=io.BytesIO()
 with tarfile.open(fileobj=buffer,mode='w') as archive:
  for name,content in files.items():
   item=tarfile.TarInfo(name);item.size=len(content);item.mode=0o600;archive.addfile(item,io.BytesIO(content))
 payload=buffer.getvalue()
 init=f'''
release=Path('/var/backups')/('business-event-agenda.'+secrets.token_hex(6));release.mkdir(mode=0o700)
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
 assert re.fullmatch(r'/var/backups/business-event-agenda\.[A-Za-z0-9_]+',remote)
 assert previous['scriptSHA']==script_sha,'Publisher changed after preparation'
 payload=b'';init=f'release=Path({remote!r})\n'
remote_script='''from pathlib import Path
import hashlib,io,json,os,re,secrets,shutil,subprocess,sys,tarfile,tempfile
'''+init+f'''
assert hashlib.sha256((release/'publish.py').read_bytes()).hexdigest()=={script_sha!r}
if {mode!r}=='publish':
 log=(release/'compile.log').read_text()
 assert re.search(r'successful\\s+3\\b',log) and re.search(r'total\\s+3\\b',log),'Native compilation was not verified'
result=subprocess.run(['python3',str(release/'publish.py'),str(release),{mode!r}],capture_output=True,text=True,timeout=90)
assert result.returncode==0,result.stdout+result.stderr
'''
if mode=='prepare':
 # Compile only the three CFML candidates, outside all webroots.
 remote_script+='''
stage=Path(tempfile.mkdtemp(prefix='event-interest-compile-',dir='/tmp'))
source=stage/'source';compiled=stage/'compiled';compiled.mkdir()
for path in (release/'candidate/Business').rglob('*.cfm'):
 target=source/path.relative_to(release/'candidate/Business');target.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(path,target)
for path in [stage,*stage.rglob('*')]:
 os.chown(path,65534,65534);os.chmod(path,0o755 if path.is_dir() else 0o644)
compiled_run=subprocess.run(['/opt/ColdFusion/cfusion/bin/cfcompile.sh','-deploy','-cfruntimeuser','nobody','-webroot',str(source),'-dir',str(source),'-deploydir',str(compiled)],capture_output=True,text=True,timeout=90)
log=compiled_run.stdout+compiled_run.stderr
(release/'compile.log').write_text(log)
shutil.move(str(stage),str(release/'compile-artifacts'))
assert compiled_run.returncode==0 and re.search(r'successful\\s+3\\b',log) and re.search(r'total\\s+3\\b',log),log[-4000:]
'''
if mode=='publish':
 # The reviewed prepared package is immutable; the publisher rechecks every hash.
 # Actual HTTP/JDBC verification is a separate required post-publication step.
 pass
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
