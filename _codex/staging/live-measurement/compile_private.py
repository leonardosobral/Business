#!/usr/bin/env python3
"""Compile only the reviewed runtime templates in a private server directory."""
import io
import json
from pathlib import Path
import shlex
import subprocess
import tarfile

base=Path(__file__).resolve().parent
release=base/'release'
rows=[line.split('\t') for line in (release/'runtime.tsv').read_text().splitlines()]
archive=io.BytesIO()
with tarfile.open(fileobj=archive,mode='w') as tar:
    for site,rel,before,after in rows:
        tar.add(release/'candidate'/site/rel,arcname=f'{site}/{rel}',recursive=False)
remote=r'''
import hashlib,io,json,os,subprocess,sys,tarfile,tempfile
from pathlib import Path
archive=tarfile.open(fileobj=io.BytesIO(sys.stdin.buffer.read()),mode='r:')
work=Path(tempfile.mkdtemp(prefix='rr-live-compile.',dir='/var/tmp'))
os.chmod(work,0o755)
source=work/'src';source.mkdir(mode=0o755)
compiled=work/'compiled';compiled.mkdir(mode=0o755)
import pwd
nobody=pwd.getpwnam('nobody');os.chown(compiled,nobody.pw_uid,nobody.pw_gid)
members=archive.getmembers()
assert len(members)==11
for member in members:
    rel=Path(member.name)
    assert member.isfile() and rel.parts[0] in ('RoadRunners','Business') and not rel.is_absolute() and '..' not in rel.parts
    target=source/rel;target.parent.mkdir(mode=0o755,parents=True,exist_ok=True)
    target.write_bytes(archive.extractfile(member).read());os.chmod(target,0o644)
result=subprocess.run(['/opt/ColdFusion/cfusion/bin/cfcompile.sh','-deploy','-cfruntimeuser','nobody','-webroot',str(source),'-dir',str(source),'-deploydir',str(compiled)],stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,timeout=180)
(work/'compile.log').write_text(result.stdout)
print(json.dumps({'directory':str(work),'returncode':result.returncode,'output':result.stdout,'input_count':len(members),'compiled_files':len(list(compiled.rglob('*.*')))}))
sys.exit(result.returncode)
'''
ssh=['ssh','-i','/Users/leonardosobral/.ssh/webs','-o','BatchMode=yes','-o','IdentitiesOnly=yes','-o','StrictHostKeyChecking=yes','-o','UpdateHostKeys=no','root@ssh.runnerhub.run']
result=subprocess.run(ssh+['python3 -c '+shlex.quote(remote)],input=archive.getvalue(),stdout=subprocess.PIPE,stderr=subprocess.PIPE,timeout=200)
(base/'private-compile-result.json').write_bytes(result.stdout)
print(result.stdout.decode())
if result.stderr: print(result.stderr.decode())
raise SystemExit(result.returncode)
