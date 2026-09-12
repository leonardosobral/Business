#!/usr/bin/env python3
"""Compile exactly two reviewed RoadRunners templates in a private server directory."""
import hashlib
import inspect
import io
import json
from pathlib import Path
import shlex
import subprocess
import tarfile

from release_remote import BASE, ORDER, SSH, make_archive, read_package

EXPECTED_MEMBERS = tuple(f"{site}/{relative}" for site, relative in ORDER)


def validate_compile_archive(payload, expected_hashes):
    """This exact validator also runs remotely before any directory is created."""
    if set(expected_hashes) != set(EXPECTED_MEMBERS) or len(expected_hashes) != 2:
        raise ValueError("Unexpected compile hash manifest")
    with tarfile.open(fileobj=io.BytesIO(payload), mode="r:") as archive:
        members = archive.getmembers()
        if len(members) != 2 or set(member.name for member in members) != set(EXPECTED_MEMBERS):
            raise ValueError("Compile archive must contain exactly the two RoadRunners circuit templates")
        contents = {}
        for member in members:
            relative = Path(member.name)
            if not member.isfile() or relative.is_absolute() or ".." in relative.parts or relative.parts[0] != "RoadRunners":
                raise ValueError("Unsafe compile archive member")
            content = archive.extractfile(member).read()
            if hashlib.sha256(content).hexdigest() != expected_hashes[member.name]:
                raise ValueError("Compile archive hash mismatch")
            contents[member.name] = content
    return contents


def build_compile_archive(release):
    package = read_package(release)
    contents = {name: package[f"candidate/{name}"] for name in EXPECTED_MEMBERS}
    hashes = {name: hashlib.sha256(content).hexdigest() for name, content in contents.items()}
    archive = make_archive(contents)
    validate_compile_archive(archive, hashes)
    return archive, hashes


def main():
    archive, hashes = build_compile_archive(BASE / "release")
    remote = '''import hashlib,io,json,os,pwd,subprocess,sys,tarfile,tempfile
from pathlib import Path
''' + f"EXPECTED_MEMBERS={EXPECTED_MEMBERS!r}\n" + inspect.getsource(validate_compile_archive) + f'''
contents=validate_compile_archive(sys.stdin.buffer.read(),{hashes!r})
work=Path(tempfile.mkdtemp(prefix='rr-highlight-compile.',dir='/var/tmp'))
os.chmod(work,0o755)
source=work/'src';source.mkdir(mode=0o755)
compiled=work/'compiled';compiled.mkdir(mode=0o755)
nobody=pwd.getpwnam('nobody');os.chown(compiled,nobody.pw_uid,nobody.pw_gid)
for name,content in contents.items():
    target=source/name
    target.parent.mkdir(mode=0o755,parents=True,exist_ok=True)
    with target.open('xb') as handle: handle.write(content)
    os.chmod(target,0o644)
result=subprocess.run(['/opt/ColdFusion/cfusion/bin/cfcompile.sh','-deploy','-cfruntimeuser','nobody','-webroot',str(source),'-dir',str(source),'-deploydir',str(compiled)],stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,timeout=180)
(work/'compile.log').write_text(result.stdout)
print(json.dumps({{'directory':str(work),'returncode':result.returncode,'output':result.stdout,'input_count':len(contents),'input_members':sorted(contents),'input_hashes':{hashes!r},'compiled_files':len(list(compiled.rglob('*.*')))}}))
sys.exit(result.returncode)
'''
    result = subprocess.run(SSH + ["python3 -c " + shlex.quote(remote)], input=archive,
                            stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=200)
    (BASE / "private-compile-result.json").write_bytes(result.stdout)
    print(result.stdout.decode())
    if result.stderr:
        print(result.stderr.decode())
    return result.returncode


if __name__ == "__main__":
    raise SystemExit(main())
