#!/usr/bin/env python3
"""Transfer the reviewed package privately, then invoke its guarded release CLI."""
import hashlib
import io
import json
from pathlib import Path
import re
import shlex
import subprocess
import sys
import tarfile

base=Path(__file__).resolve().parent
release=base/'release'
script=base/'release-tools/publish.py'
mode=sys.argv[1]
assert mode in ('prepare','publish','verify','rollback')
script_sha=hashlib.sha256(script.read_bytes()).hexdigest()
ssh=['ssh','-i','/Users/leonardosobral/.ssh/webs','-o','BatchMode=yes','-o','IdentitiesOnly=yes','-o','StrictHostKeyChecking=yes','-o','UpdateHostKeys=no','root@ssh.runnerhub.run']
receipt=base/'remote-release.json'
payload=b''
if mode=='prepare':
    assert not receipt.exists(), 'An existing release receipt requires inspection before another preparation.'
    rows=[line.split('\t') for line in (release/'runtime.tsv').read_text().splitlines()]
    assert len(rows)==11
    files={'runtime.tsv':release/'runtime.tsv','publish.py':script}
    for site,rel,before,after in rows:
        source=release/'candidate'/site/rel
        assert hashlib.sha256(source.read_bytes()).hexdigest()==after
        files[f'candidate/{site}/{rel}']=source
    archive=io.BytesIO()
    with tarfile.open(fileobj=archive,mode='w') as tar:
        for name,source in files.items():tar.add(source,arcname=name,recursive=False)
    payload=archive.getvalue()
    init=f'''
import io,secrets,tarfile
release=Path('/var/backups')/('rr-live-measurement.'+secrets.token_hex(6))
release.mkdir(mode=0o700)
allowed=set({list(files)!r})
archive=tarfile.open(fileobj=io.BytesIO(sys.stdin.buffer.read()),mode='r:')
members=archive.getmembers()
assert len(members)==len(allowed) and set(m.name for m in members)==allowed
for member in members:
    rel=Path(member.name)
    assert member.isfile() and not rel.is_absolute() and '..' not in rel.parts
    target=release/rel;target.parent.mkdir(mode=0o700,parents=True,exist_ok=True)
    target.write_bytes(archive.extractfile(member).read());os.chmod(target,0o600)
'''
else:
    previous=json.loads(receipt.read_text())
    remote_dir=previous['directory']
    assert re.fullmatch(r'/var/backups/rr-live-measurement\.[A-Za-z0-9]+',remote_dir)
    assert previous['scriptSHA']==script_sha, 'Reviewed publisher changed after preparation.'
    init=f'release=Path({remote_dir!r})\n'
remote='''import hashlib,json,os,subprocess,sys
from pathlib import Path
'''+init+f'''
assert hashlib.sha256((release/'publish.py').read_bytes()).hexdigest()=={script_sha!r}
result=subprocess.run(['python3',str(release/'publish.py'),str(release),{mode!r}],stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,timeout=90)
state=json.loads((release/'state.json').read_text()) if (release/'state.json').exists() else {{}}
print(json.dumps({{'directory':str(release),'scriptSHA':{script_sha!r},'mode':{mode!r},'returncode':result.returncode,'output':result.stdout,'phase':state.get('phase'),'target_count':len(state.get('files',[])),'guard_count':len(state.get('guards',{{}})),'rollback_conflicts':state.get('rollbackConflicts',[])}}))
sys.exit(result.returncode)
'''
result=subprocess.run(ssh+['python3 -c '+shlex.quote(remote)],input=payload,stdout=subprocess.PIPE,stderr=subprocess.PIPE,timeout=100)
(base/f'remote-{mode}-result.json').write_bytes(result.stdout)
if mode=='prepare' and result.stdout:
    receipt.write_bytes(result.stdout)
print(result.stdout.decode())
if result.stderr: print(result.stderr.decode())
raise SystemExit(result.returncode)
