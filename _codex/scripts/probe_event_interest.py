from pathlib import Path
import subprocess,shlex,hashlib,io,tarfile,json,sys
root=Path(__file__).resolve().parents[2]
files={'portal/eventos-analytics/interest-check.cfm':(root/'_codex/tests/event-interest-probe.cfm').read_bytes(),'portal/audiencia/queries/event_interest.sql':(root/'portal/audiencia/queries/event_interest.sql').read_bytes()}
buffer=io.BytesIO()
with tarfile.open(fileobj=buffer,mode='w') as tar:
 for name,content in files.items():
  item=tarfile.TarInfo(name);item.size=len(content);item.mode=0o644;tar.addfile(item,io.BytesIO(content))
remote='''from pathlib import Path
import io,tarfile,sys,os,json,hashlib,shutil,secrets
root=Path('/var/www/business.roadrunners.run')
archive=tarfile.open(fileobj=io.BytesIO(sys.stdin.buffer.read()))
release=Path('/var/backups/business-event-interest.204bd0f4814f')
manifest=release/'probe-manifest.json'
before=json.loads(manifest.read_text())
for name,digest in before.items():
 target=root/name
 assert not target.is_symlink() and hashlib.sha256(target.read_bytes()).hexdigest()==digest,'Diagnostic changed: '+name
quarantine=release/('probe-'+secrets.token_hex(6));quarantine.mkdir(mode=0o700)
'''+f'''
expected={ {p:hashlib.sha256(b).hexdigest() for p,b in files.items()}!r}
members=archive.getmembers();assert set(m.name for m in members)==set(expected)
mode={sys.argv[1]!r}
assert mode in ('update','cleanup')
if mode=='cleanup':
 home='portal/eventos-analytics/home.cfm'
 state=json.loads((release/'state.json').read_text())
 row=next(r for r in state['files'] if r['path']==home)
 saved=release/'before/Business'/home
 assert hashlib.sha256(saved.read_bytes()).hexdigest()==row['before']
 for name in expected:
  shutil.move(str(root/name),str(quarantine/Path(name).name))
 target=root/home;shutil.copy2(target,quarantine/'diagnostic-home.cfm')
 stage=target.with_name('home.cfm.probe-restore')
 assert not stage.exists()
 shutil.copy2(saved,stage)
 os.chown(stage,row['metadata']['uid'],row['metadata']['gid']);os.chmod(stage,row['metadata']['mode'])
 os.utime(stage,ns=(row['metadata']['mtime_ns'],row['metadata']['mtime_ns']))
 os.replace(stage,target)
 assert hashlib.sha256(target.read_bytes()).hexdigest()==row['before']
 print('Diagnostic removed recoverably; original home restored; no data mutations')
 raise SystemExit(0)
for member in members:
 data=archive.extractfile(member).read();assert hashlib.sha256(data).hexdigest()==expected[member.name]
 target=root/member.name
 shutil.copy2(target,quarantine/target.name)
 stage=target.with_name(target.name+'.probe-stage');assert not stage.exists()
 with stage.open('xb') as f:f.write(data)
 os.chmod(stage,0o644);os.replace(stage,target)
before.update(expected);manifest.write_text(json.dumps(before))
print('Temporary admin-only diagnostic updated with hash checks; no data mutations')
'''
r=subprocess.run(['ssh','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=buffer.getvalue(),capture_output=True)
print(r.stdout.decode());print(r.stderr.decode());raise SystemExit(r.returncode)
