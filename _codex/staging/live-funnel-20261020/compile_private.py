#!/usr/bin/env python3
"""Transfer validated candidate bytes for private CF compilation; never publishes or executes templates."""
import json
import shlex
import subprocess
from release_support import BASE, SSH, archive_files, load_package, publisher


def main():
    rows, manifest_sha, files = load_package(BASE / 'release')
    expected = {f"{row['site']}/{row['path']}": row['after'] for row in rows}
    payload = archive_files(files)
    publisher.require(publisher.sha256(BASE / 'release/runtime.tsv') == manifest_sha, 'Manifest changed during packaging')
    remote = '''import hashlib,io,json,os,pwd,subprocess,sys,tarfile,tempfile
from pathlib import Path
''' + f'expected={expected!r}\n' + r'''
archive=tarfile.open(fileobj=io.BytesIO(sys.stdin.buffer.read()),mode='r:')
members=archive.getmembers()
assert len(members)==len(expected) and set(m.name for m in members)==set(expected)
work=Path(tempfile.mkdtemp(prefix='rr-live-funnel-compile.',dir='/var/tmp'))
os.chmod(work,0o755)
source=work/'src';source.mkdir(mode=0o755)
compiled=work/'compiled';compiled.mkdir(mode=0o755)
nobody=pwd.getpwnam('coldfusion');os.chown(compiled,nobody.pw_uid,nobody.pw_gid)
for member in members:
    rel=Path(member.name)
    assert member.isfile() and not rel.is_absolute() and '..' not in rel.parts
    data=archive.extractfile(member).read()
    assert hashlib.sha256(data).hexdigest()==expected[member.name]
    target=source/rel;target.parent.mkdir(mode=0o755,parents=True,exist_ok=True)
    target.write_bytes(data);os.chmod(target,0o644)
result=subprocess.run(['/opt/coldfusion2025/cfusion/bin/cfcompile.sh','-deploy','-cfruntimeuser','coldfusion','-webroot',str(source),'-dir',str(source),'-deploydir',str(compiled)],stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,timeout=180)
(work/'compile.log').write_text(result.stdout)
print(json.dumps({'directory':str(work),'returncode':result.returncode,'output':result.stdout,'input_count':len(members),'compiled_files':len(list(compiled.rglob('*.*')))}))
sys.exit(result.returncode or (0 if len(list(compiled.rglob('*.*'))) >= 6 else 1))
'''
    result = subprocess.run(SSH + ['python3 -c ' + shlex.quote(remote)], input=payload,
                            stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=200)
    (BASE / 'private-compile-result.json').write_bytes(result.stdout)
    print(result.stdout.decode())
    if result.stderr:
        print(result.stderr.decode())
    return result.returncode


if __name__ == '__main__':
    raise SystemExit(main())
